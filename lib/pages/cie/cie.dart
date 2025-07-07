import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:global_contineo_unofficial/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CiePage extends StatefulWidget {
  const CiePage({super.key});

  @override
  State<CiePage> createState() => _CiePageState();
}

class _CiePageState extends State<CiePage> {
  late InAppWebViewController webViewController;
  bool initLoad = false;
  bool isLoading = false;
  int? loadingSub;
  List<Map<String, dynamic>> subjects = [];
  Map<String, Map<String, String>> cieAll = {};
  int lastRefreshedDiff = 60;
  DateTime? lastUpdated;
  int sem = 0;
  String? studentName;
  ValueNotifier<Map<String, dynamic>> valNotifier1 = ValueNotifier({});
  ValueNotifier<Map<String, dynamic>> valNotifier2 = ValueNotifier({});

  // List cieDetails = [
  //   {'subject_name': 'Mathematics', 'subject_code': 'BMATS24201', 'attendance': 0, 'CIE 1': '0/40', 'CIE 2': '0/40', 'CIE 3': '0/40', 'Final CIE': '0/50'},
  //   {'subject_name': 'Chemistry', 'subject_code': 'BCHES24202', 'attendance': 0, 'CIE 1': '0/40', 'CIE 2': '0/40', 'CIE 3': '0/40', 'Final CIE': '0/50'},
  //   {'subject_name': 'Computer-Aided Engineering Design', 'subject_code': 'BCEDK24203', 'attendance': 0, 'CIE 1': '0/30', 'CIE 2': '0/30', 'CIE 3': '0/30', 'Final CIE': '0/50'},
  //   {'subject_name': 'Electrical', 'subject_code': 'BESCK24204C', 'attendance': 0, 'CIE 1': '0/30', 'CIE 2': '0/30', 'CIE 3': '0/30', 'Final CIE': '0/50'},
  //   {'subject_name': 'Mathematics', 'subject_code': 'BMATS24201', 'attendance': 0, 'CIE 1': '0/40', 'CIE 2': '0/40', 'CIE 3': '0/40', 'Final CIE': '0/50'},
  //   {'subject_name': 'Chemistry', 'subject_code': 'BCHES24202', 'attendance': 0, 'CIE 1': '0/40', 'CIE 2': '0/40', 'CIE 3': '0/40', 'Final CIE': '0/50'},
  //   {'subject_name': 'Computer-Aided Engineering Design', 'subject_code': 'BCEDK24203', 'attendance': 0, 'CIE 1': '0/30', 'CIE 2': '0/30', 'CIE 3': '0/30', 'Final CIE': '0/50'},
  //   {'subject_name': 'Electrical', 'subject_code': 'BESCK24204C', 'attendance': 0, 'CIE 1': '0/30', 'CIE 2': '0/30', 'CIE 3': '0/30', 'Final CIE': '0/50'},
  // ];

  @override
  void initState() {
    super.initState();
    // _fetchAllCIE();
  }

  @override
  void dispose() {
    super.dispose();
  }
  
  Future<void> _screenRefresh(valNotifier1) async {
    while (true) {
      final progress = await webViewController.getProgress();
      if (progress == 100) break;
      await Future.delayed(const Duration(milliseconds: 50));
    }
    await Future.delayed(Duration(seconds: 2));
    if ((valNotifier1.value['isLoading'] != true ||
        valNotifier1.value['subjects'] != []) && !initLoad && !isLoading) {
      setState(() {});
    }
  }

  Future<void> _fetchAllCIE() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final lastRefreshedCIE = prefs.getString('lastRefreshedCIE');

    if (lastRefreshedCIE != null) {
      lastUpdated = DateTime.parse(lastRefreshedCIE);
      lastRefreshedDiff =
          DateTime.now().difference(DateTime.parse(lastRefreshedCIE)).inSeconds;
    }

    final jsonString = prefs.getString('cie_all');
    if (jsonString != null) {
      final Map<String, dynamic> decodedMap = jsonDecode(jsonString);

      cieAll = decodedMap.map((key, value) {
        // Convert the nested value into a Map<String, String>
        Map<String, String> nestedMap = Map<String, String>.from(
          value.map(
            (nestedKey, nestedValue) =>
                MapEntry(nestedKey.toString(), nestedValue.toString()),
          ),
        );

        return MapEntry(key, nestedMap);
      });
    }

    setState(() {
      sem = prefs.getInt('selected_sem')!;
      studentName = prefs.getString('student_name');
    });

    if (!isLoading) return;

    if (lastRefreshedDiff >= 60) {
      webViewController.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(
            sem.isOdd
                ? "https://globalparents.contineo.in/newparentsodd/index.php?option=com_studentdashboard&controller=studentdashboard&task=dashboard"
                : "https://globalparents.contineo.in/newparents/index.php?option=com_studentdashboard&controller=studentdashboard&task=dashboard",
            // "https://globalparents.contineo.in/newparents/index.php",
            // "https://globalparents.contineo.in/newparents/index.php?option=com_studentdashboard&controller=studentdashboard&task=dashboard",
          ),
        ),
      );
      // Wait for WebView progress to reach 100%
      await Future.delayed(
        const Duration(milliseconds: 200),
      ); // Initial small delay
      while (true) {
        final progress = await webViewController.getProgress();
        if (progress == 100) break;
        await Future.delayed(const Duration(milliseconds: 50));
      }
      forLoop:
      for (var entry in subjects.asMap().entries) {
        if (!isLoading) break forLoop;
        int index = entry.key;
        var subject = entry.value;

        if (await webViewController.getTitle() != 'Web page not available') {
          var url = await webViewController.getUrl();
          if (url.toString().contains(
            "index.php?option=com_studentdashboard&controller=studentdashboard",
          )) {
            print("test0");
            var studentNameWeb = await webViewController.evaluateJavascript(
              source: """document.body.innerText.includes('$studentName')""",
            );
            // print(studentNameWeb);
            if (studentNameWeb == null || studentNameWeb == false) {
              print("test1");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('An error occured. Please try again.'),
                  duration: Duration(seconds: 2),
                ),
              );
              break forLoop;
            } else if (studentNameWeb == true) {
              setState(() {
                loadingSub = index;
              });

              final cieLink = subject['cie_link'];
              await webViewController.loadUrl(
                urlRequest: URLRequest(url: WebUri(cieLink)),
              );

              // Wait for WebView progress to reach 100%
              await Future.delayed(
                const Duration(milliseconds: 200),
              ); // Initial small delay
              while (true) {
                final progress = await webViewController.getProgress();
                if (progress == 100) break;
                await Future.delayed(const Duration(milliseconds: 50));
              }

              final result1 = await webViewController.evaluateJavascript(
                source: """
              (() => {
                let tableData = [];

                const headers = document.querySelectorAll('table thead th');

                const rows = document.querySelectorAll('table tbody tr.odd');

                const cells = rows[0].querySelectorAll('td');

                headers.forEach((header, index) => {
                  // We skip empty headers (if any)
                  if (header.innerText.trim() !== "" && index > 0) {
                    // Map the header to the corresponding cell value
                    tableData.push(`\${header.innerText.trim()} = \${cells[index-1].innerText.trim()}`);
                  }
                });

                return tableData;
              })();
            """,
              );
              Map<String, String> result = {};

              if (result1 != null) {
                result1.forEach(
                  (item) => result[item.split(" = ")[0]] = item.split(" = ")[1],
                );
              }

              cieAll['${subject['subject_code']}'] = result;
            }
          } else if (!(url.toString().contains("index.php?"))) {
            print("test2");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('An error occured. Please try again.tt'),
                duration: Duration(seconds: 2),
              ),
            );
            break forLoop;
          }
        } else if (cieAll['${subject['subject_code']}'] == null) {
          cieAll['${subject['subject_code']}'] = {};
        } else if (await webViewController.getTitle() !=
            'Web page not available') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to connect. Check your internet connection and try again by restarting the app.',
              ),
              duration: Duration(seconds: 2),
            ),
          );
          break forLoop;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An error occured. Please try again.t'),
              duration: Duration(seconds: 2),
            ),
          );
          break forLoop;
        }

        // print('Attendance from: $attendanceLink');
        // print(result);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Try refreshing in ${60 - lastRefreshedDiff} seconds.'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() {
      if (loadingSub == subjects.length - 1) {
        prefs.setString('lastRefreshedCIE', DateTime.now().toIso8601String());
        lastUpdated = DateTime.parse(DateTime.now().toIso8601String());
      }
      loadingSub = null;
      isLoading = false;
      prefs.setString('cie_all', jsonEncode(cieAll));
      // prefs.setString(
      //   'lastRefreshedAttendance',
      //   DateTime.now().toIso8601String(),
      // );
    });
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    // subjects = args['subjects'];
    webViewController = args['webview_ctrl'];
    valNotifier1 = args['valNotifier1'];
    subjects = valNotifier1.value['subjects'];

    if (!valNotifier1.value['isLoading'] &&
        !isLoading &&
        !initLoad &&
        cieAll.isEmpty &&
        lastRefreshedDiff >= 60) {
      setState(() {
        isLoading = true;
        initLoad = true;
        valNotifier2.value['isLoading'] = false;
      });
      _fetchAllCIE();
    } else {
      _screenRefresh(valNotifier1);
    }

    return Scaffold(
      appBar: AppBar(
        // title: Column(
        //   children: [
        //     Text('CIE'),
        //     if (isLoading)
        //       Row(
        //         mainAxisAlignment: MainAxisAlignment.center,
        //         spacing: 10,
        //         children: [
        //           Text('Updating', style: TextStyle(fontSize: 15)),
        //           // SizedBox(width: 10),
        //           SizedBox(
        //             height: 20,
        //             width: 20,
        //             child: CircularProgressIndicator(
        //               color: Colors.red,
        //               strokeWidth: 3.0,
        //             ),
        //           ),
        //         ],
        //       ),
        //   ],
        // ),
        title: Text('CIE'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon:
                isLoading || valNotifier1.value['isLoading']
                    ? Stack(
                      alignment: AlignmentDirectional.center,
                      children: [
                        CircularProgressIndicator(color: Colors.red),
                        if (!valNotifier1.value['isLoading'] && isLoading && initLoad)
                          Icon(Icons.close),
                      ],
                    )
                    : Icon(Icons.refresh),
            onPressed: () async {
              if (!valNotifier1.value['isLoading'] && !isLoading) {
                isLoading = true;
                valNotifier2.value['isLoading'] = false;
                _fetchAllCIE();
              } else if (!valNotifier1.value['isLoading'] && isLoading && initLoad) {
                setState(() {
                  isLoading = false;
                  loadingSub = null;
                });
              }
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<Map<String, dynamic>>(
        valueListenable: valNotifier1,
        builder: (context, value, child) {
          if (!valNotifier1.value['isLoading'] &&
              !isLoading &&
              !initLoad &&
              lastRefreshedDiff >= 60) {
            isLoading = true;
            valNotifier2.value['isLoading'] = false;
            _fetchAllCIE();
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'Last updated: ${lastUpdated != null ? lastUpdated?.toString().split('.')[0] : "Never Updated"}',
                ),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: subjects.length,
                  controller: ScrollController(),
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subjects[index]['subject_code'], // This acts as the "super title"
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            subjects[index]['subject_name'], // This acts as the "sub title"
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 15),
                      trailing: RichText(
                        textAlign: TextAlign.end,
                        text: TextSpan(
                          children: [
                            if (isLoading && loadingSub == index)
                              WidgetSpan(
                                child: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: SizedBox(
                                    height: 25,
                                    width: 25,
                                    child: CircularProgressIndicator(
                                      color: Colors.red,
                                      strokeWidth: 3.0,
                                    ),
                                  ),
                                ),
                              ),
                            WidgetSpan(
                              child: Text(
                                '${subjects[index]['cie_final']}/50',
                                textScaler: TextScaler.linear(1.3),
                              ),
                            ),
                            WidgetSpan(child: SizedBox(width: 5)),
                            WidgetSpan(
                              child: Icon(Icons.arrow_forward, size: 20),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        valNotifier2.value['isLoading'] =
                            (loadingSub == index) ? true : false;
                        valNotifier2.value['data'] = cieAll['${subjects[index]['subject_code']}'];
                        Navigator.pushNamed(
                          context,
                          '/cie/details',
                          arguments: {
                            'subject_code': subjects[index]['subject_code'],
                            'subject_name': subjects[index]['subject_name'],
                            // 'data':
                            //     cieAll['${subjects[index]['subject_code']}'],
                            'isLoading': (isLoading && loadingSub == index),
                            'valNotifier2': valNotifier2,
                          },
                        );
                      },
                      // trailing: Text(
                      //   '${subjects[index]['attendance']}%',
                      //   style: TextStyle(
                      //     color:
                      //         subjects[index]['attendance'] < 85
                      //             ? Colors.red
                      //             : Colors.green,
                      //     // fontWeight: FontWeight.bold,
                      //   ),
                      //   textScaler: TextScaler.linear(1.3),
                      // ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
