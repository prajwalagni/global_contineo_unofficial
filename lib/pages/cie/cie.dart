import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CiePage extends StatefulWidget {
  const CiePage({super.key});

  @override
  State<CiePage> createState() => _CiePageState();
}

class _CiePageState extends State<CiePage> {

  late InAppWebViewController webViewController;
  bool isLoadingInit = false;
  bool isLoading = false;
  int? loadingSub;
  List<Map<String, dynamic>> subjects = [];
  Map<String, Map<String, String>> cieAll = {};
  int lastRefreshedDiff = 60;
  DateTime? lastUpdated;

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

  Future<void> _fetchAllCIE() async {
    if (!isLoading) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();

    final lastRefreshedCIE = prefs.getString('lastRefreshedCIE');

    if (lastRefreshedCIE != null) {
      lastUpdated = DateTime.parse(lastRefreshedCIE);
      lastRefreshedDiff =
          DateTime.now()
              .difference(DateTime.parse(lastRefreshedCIE))
              .inSeconds;
    }

    final jsonString = prefs.getString('cie_all');
    if (jsonString != null) {
      final Map<String, dynamic> decodedMap = jsonDecode(jsonString);

      cieAll = decodedMap.map(
      (key, value) {
        // Convert the nested value into a Map<String, String>
        Map<String, String> nestedMap = Map<String, String>.from(
          value.map((nestedKey, nestedValue) => MapEntry(nestedKey.toString(), nestedValue.toString())),
        );

        return MapEntry(key, nestedMap);
      },
    );
    }

    if (lastRefreshedDiff >= 60) {
      for (var entry in subjects.asMap().entries) {
        int index = entry.key;
        var subject = entry.value;

        setState(() {
          loadingSub = index;
        });

        final cieLink = subject['cie_link'];
        await webViewController.loadUrl(
          urlRequest: URLRequest(url: WebUri(cieLink)),
        );

        // Wait for WebView progress to reach 100%
        await Future.delayed(
          const Duration(milliseconds: 100),
        ); // Initial small delay
        while (true) {
          final progress = await webViewController.getProgress();
          if (progress == 100) break;
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Run JS to extract sorted attendance
        if (await webViewController.getTitle() != 'Web page not available') {
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
            result1.forEach((item) => result[item.split(" = ")[0]] = item.split(" = ")[1]);
            setState(() {
              prefs.setString(
                'lastRefreshedCIE',
                DateTime.now().toIso8601String(),
              );
            });
          }

          cieAll['${subject['subject_code']}'] = result;
        } else if (cieAll['${subject['subject_code']}'] == null) {
          cieAll['${subject['subject_code']}'] = {};
        }

        print('CIE from: $cieLink');
        
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Try refreshing in ${60 - lastRefreshedDiff} seconds.'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // await

    setState(() {
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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    subjects = args['subjects'];
    isLoadingInit = args['isLoading'];
    webViewController = args['webview_ctrl'];

    if (!isLoadingInit &&
        !isLoading &&
        cieAll.isEmpty &&
        lastRefreshedDiff >= 60) {
      setState(() {
        isLoading = true;
      });
      _fetchAllCIE();
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('CIE'),
            if (isLoading)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  Text('Updating', style: TextStyle(fontSize: 15)),
                  // SizedBox(width: 10),
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.red,
                      strokeWidth: 3.0,
                    ),
                  ),
                ],
              ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/login');
              // TODO: Implemment Settings Action
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                        if (isLoadingInit || (isLoading && loadingSub == index))
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
                        WidgetSpan(child: Icon(Icons.arrow_forward, size: 20)),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/cie/details',
                      arguments: {
                        'subject_code': subjects[index]['subject_code'],
                        'subject_name': subjects[index]['subject_name'],
                        'data': cieAll['${subjects[index]['subject_code']}'],
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
      ),
    );
  }
}