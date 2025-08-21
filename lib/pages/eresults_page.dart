import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// HTML parsing
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class EResultsPage extends StatefulWidget {
  const EResultsPage({super.key});

  @override
  State<EResultsPage> createState() => _EResultsPageState();
}

class _EResultsPageState extends State<EResultsPage>
    with WidgetsBindingObserver {
  // Per-semester state
  final Map<int, bool> isDownloading = {};
  final Map<int, double> progress = {};
  final Map<int, File?> downloadedFiles = {};

  String usn = '1GA24CS001';
  int currentSem = 1;
  SharedPreferences? prefs;

  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 2));

  // Available results (from GET + HTML parsing)
  List<String> availableResults = [];

  // Share tile highlight/blink state
  bool highlightShare = false;
  Timer? _blinkTimer;
  int _blinkTicks = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _blinkTimer?.cancel();
    super.dispose();
  }

  // 🔑 App lifecycle callback
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // If student already has results downloaded, blink share again
      if (downloadedFiles.values.any((file) => file != null)) {
        _blinkShareTile();
      }
    }
  }

  Future<void> _initialLoad() async {
    final p = await SharedPreferences.getInstance();
    prefs = p;
    setState(() {
      usn = p.getString('usn') ?? usn;
      currentSem = p.getInt('selected_sem') ?? currentSem;
    });

    // Pre-detect existing files
    for (final sem in _semsForCurrent()) {
      final file = await _fileForSem(sem);
      if (await file.exists()) {
        downloadedFiles[sem] = file;
      }
    }

    _loadAvailableResultsViaGet();
  }

  List<int> _semsForCurrent() =>
      currentSem.isOdd ? [currentSem] : [currentSem - 1, currentSem];

  Future<Directory> _resultsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final saveDir = Directory("${dir.path}/GAT/e-results");
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return saveDir;
  }

  Future<File> _fileForSem(int sem) async {
    final saveDir = await _resultsDir();
    return File("${saveDir.path}/${usn}_result_sem$sem.pdf");
  }

  // Blink the "Share this app" tile 3 times
  void _blinkShareTile() {
    _blinkTimer?.cancel();
    _blinkTicks = 0;
    highlightShare = true;
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 350), (t) {
      _blinkTicks++;
      setState(() {
        highlightShare = !highlightShare;
      });
      if (_blinkTicks >= 6) {
        t.cancel();
        setState(() {
          highlightShare = false;
        });
      }
    });
  }

  // GET page + parse HTML
  Future<void> _loadAvailableResultsViaGet() async {
    try {
      final resp =
          await http.get(Uri.parse("https://eresultsglobal.contineo.in/"));
      if (resp.statusCode == 200) {
        final dom.Document doc = html_parser.parse(resp.body);
        final lis = doc.querySelectorAll('.uk-panel ol li');
        final list = lis.map((e) => e.text.trim()).where((e) => e.isNotEmpty);
        setState(() {
          availableResults = list.toList();
        });
      }
    } catch (_) {
      // ignore
    }
  }

  // Download function
  Future<void> downloadResult(int sem) async {
    final existing = await _fileForSem(sem);
    if (await existing.exists()) {
      setState(() {
        downloadedFiles[sem] = existing;
      });
      _showAlreadyDownloadedSnack(existing);
      return;
    }

    setState(() {
      isDownloading[sem] = true;
      progress[sem] = 0;
    });

    try {
      final savePath = existing.path;
      final examId = sem.isOdd ? "19" : "20";
      final url = Uri.parse("https://eresultsglobal.contineo.in/index.php");

      final request = http.MultipartRequest("POST", url)
        ..fields["option"] = "com_report"
        ..fields["task"] = "getReport"
        ..fields["id"] = "procard"
        ..fields["usn"] = usn
        ..fields["examId"] = examId;

      final response = await request.send();

      final sink = existing.openWrite();
      final total = response.contentLength ?? 0;
      int received = 0;

      await response.stream.listen((chunk) {
        sink.add(chunk);
        received += chunk.length;
        setState(() {
          double raw = total > 0 ? received / total : 0;
          progress[sem] = raw.clamp(0.0, 1.0);
        });
      }).asFuture();

      await sink.close();

      setState(() {
        downloadedFiles[sem] = existing;
        isDownloading[sem] = false;
      });

      _confettiController.play();
      _blinkShareTile();

      final file = downloadedFiles[sem];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Result downloaded successfully 🎉"),
          action: SnackBarAction(
            label: "Open",
            onPressed: () {
              OpenFilex.open(file!.path);
            },
          ),
        ),
      );
    } catch (e) {
      setState(() => isDownloading[sem] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _showAlreadyDownloadedSnack(File file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Already downloaded. What next?"),
        action: SnackBarAction(
          label: "Open",
          onPressed: () {
            OpenFilex.open(file.path);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sems = _semsForCurrent();

    return Scaffold(
      appBar: AppBar(title: const Text("E-Results")),
      body: Column(
        children: [
          // ⚠️ Caution note
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "⚠️ If your result is empty/blank, please try Re-download.",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(),

          // 🔁 Blinking Share App Tile
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            color: highlightShare ? Colors.lightBlue[400] : Colors.transparent,
            child: ListTile(
              title: const Text("Share this app"),
              trailing: const Icon(Icons.share),
              onTap: () {
                Share.share(
                  "🚀 Hey! Download our unofficial GAT Results app to check your marks easily.\n👉 Visit https://github.com/myrepo to download.",
                );
              },
            ),
          ),
          const Divider(),

          ...sems.map((sem) {
            final isBusy = isDownloading[sem] == true;
            final pct =
                ((progress[sem] ?? 0) * 100).clamp(0, 100).toStringAsFixed(0);
            final file = downloadedFiles[sem];

            return ListTile(
              title: Text("Semester $sem"),
              subtitle: Text("USN: $usn"),
              trailing: isBusy
                  ? SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          "$pct%",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  : file == null
                      ? IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => downloadResult(sem),
                        )
                      : PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            switch (value) {
                              case "open":
                                await OpenFilex.open(file.path);
                                _blinkShareTile(); // blink after open
                                break;
                              case "share":
                                await Share.shareXFiles([XFile(file.path)]);
                                _blinkShareTile(); // blink after share
                                break;
                              case "redownload":
                                if (await file.exists()) await file.delete();
                                setState(() => downloadedFiles[sem] = null);
                                downloadResult(sem);
                                break;
                              case "delete":
                                if (await file.exists()) await file.delete();
                                setState(() => downloadedFiles[sem] = null);
                                break;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: "open", child: Text("Open")),
                            PopupMenuItem(value: "share", child: Text("Share")),
                            PopupMenuItem(
                                value: "redownload", child: Text("Re-download")),
                            PopupMenuItem(
                              value: "delete",
                              child: Text("Delete",
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
            );
          }),

          // 🎉 Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
            ),
          ),

          const Divider(),

          // Results Available Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 8.0, left: 8.0, bottom: 6.0),
                  child: Text(
                    "The following results are now available (If your program is not listed below then the results are yet to be announced.)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: availableResults.isEmpty
                      ? const Center(child: Text("Loading results..."))
                      : ListView.builder(
                          itemCount: availableResults.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 2.0),
                            child: Text("• ${availableResults[index]}"),
                          ),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "For any query regarding these results please contact Examination Section immediately.",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 10),

          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "The results published on this web site are provisional and are provided for immediate information to the examinees. These results may not be used as official confirmation of your achievement. While all efforts have been made to make the information available on this website as authentic as possible, GLOBAL ACADEMY OF TECHNOLOGY, contineo, e-Sutra chronicles Pvt. Ltd or any of their staff will not be responsible for any loss caused by shortcoming, defect or inaccuracy in the information provided on this website. Please contact the Examination Department for the final official results.",
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}