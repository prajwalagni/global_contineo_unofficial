import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceHomePage extends StatefulWidget {
  const AttendanceHomePage({super.key});

  @override
  State<AttendanceHomePage> createState() => _AttendanceHomePageState();
}

class _AttendanceHomePageState extends State<AttendanceHomePage> {
  late InAppWebViewController webViewController;
  bool isLoadingInit = false;
  bool isLoading = false;
  int? loadingSub;
  List<Map<String, dynamic>> subjects = [];
  Map<String, List> attendanceAll = {};
  int lastRefreshedDiff = 60;
  DateTime? lastUpdated;
  ValueNotifier<bool> isLoadingNotifier1 = ValueNotifier(false);
  ValueNotifier<bool> isLoadingNotifier2 = ValueNotifier(false);

  // List subjects = [
  //   {'name': 'Mathematics', 'subject_code': 'BMATS24201', 'attendance': 71},
  //   {'name': 'Chemistry', 'subject_code': 'BCHES24202', 'attendance': 65},
  //   {
  //     'name': 'Computer-Aided Engineering Design',
  //     'subject_code': 'BCEDK24203',
  //     'attendance': 92,
  //   },
  //   {'name': 'Electrical', 'subject_code': 'BESCK24204C', 'attendance': 71},
  // ];

  Future<void> _fetchAllAttendance() async {
    if (!isLoading) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();

    final lastRefreshedAttendance = prefs.getString('lastRefreshedAttendance');

    if (lastRefreshedAttendance != null) {
      lastUpdated = DateTime.parse(lastRefreshedAttendance);
      lastRefreshedDiff =
          DateTime.now()
              .difference(DateTime.parse(lastRefreshedAttendance))
              .inSeconds;
    }

    final jsonString = prefs.getString('attendance_all');
    if (jsonString != null) {
      final Map<String, dynamic> decodedMap = jsonDecode(jsonString);

      attendanceAll = decodedMap.map(
        (key, value) => MapEntry(
          key,
          List<List<String>>.from(value.map((item) => List<String>.from(item))),
        ),
      );
    }

    if (lastRefreshedDiff >= 60) {
      for (var entry in subjects.asMap().entries) {
        int index = entry.key;
        var subject = entry.value;

        setState(() {
          loadingSub = index;
        });
        isLoadingNotifier2.value = false;

        final attendanceLink = subject['attendance_link'];
        await webViewController.loadUrl(
          urlRequest: URLRequest(url: WebUri(attendanceLink)),
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
          final result = await webViewController.evaluateJavascript(
            source: """
            (() => {
              const rows = document.querySelectorAll("tr.even, tr.odd");
              const attendance = [];
      
              rows.forEach(row => {
                const cells = row.querySelectorAll("td");
                if (cells.length >= 4) {
                  const date = cells[1].innerText.trim();
                  const time = cells[2].innerText.trim().replace(/\\s+/g, ' ');
                  const status = cells[3].innerText.trim();
                  attendance.push({
                    date,
                    time,
                    status,
                    sortKey: new Date(date.split("-").reverse().join("-") + "T" + time.split("TO")[0].trim())
                  });
                }
              });
      
              attendance.sort((a, b) => a.sortKey - b.sortKey);
      
              return attendance.map((entry, index) => [
                String(index + 1),
                entry.date,
                entry.time,
                entry.status
              ]);
            })()
          """,
          );

          attendanceAll['${subject['subject_code']}'] = result;
          // attendanceAll['finalIndex'] = [index + 1];
        } else if (attendanceAll['${subject['subject_code']}'] == null) {
          attendanceAll['${subject['subject_code']}'] = [];
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
        prefs.setString(
          'lastRefreshedAttendance',
          DateTime.now().toIso8601String(),
        );
        lastUpdated = DateTime.parse(DateTime.now().toIso8601String());
      }
      loadingSub = null;
      isLoading = false;
      prefs.setString('attendance_all', jsonEncode(attendanceAll));
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
    subjects = args['subjects'];
    isLoadingInit = args['isLoading'];
    webViewController = args['webview_ctrl'];
    isLoadingNotifier1 = args['isLoadingNotifier1'];

    // print(attendanceAll.length);
    // print(lastRefreshedDiff);

    if (!isLoadingInit &&
        !isLoading &&
        attendanceAll.isEmpty &&
        lastRefreshedDiff >= 60) {
      setState(() {
        isLoading = true;
        isLoadingNotifier2.value = false;
      });
      _fetchAllAttendance();
    }

    return Scaffold(
      appBar: AppBar(
        // toolbarHeight: isLoading ? 70.0 : 55.0,
        // title: Column(
        //   spacing: 2,
        //   children: [
        //     Text('Attendance'),
        //     if (isLoadingInit || isLoading)
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
        title: Text('Attendance'),
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
      body: ValueListenableBuilder<bool>(
        valueListenable: isLoadingNotifier1,
        builder: (context, value, child) {
          if (!isLoadingNotifier1.value &&
              !isLoading &&
              attendanceAll.isEmpty &&
              lastRefreshedDiff >= 60) {
            isLoading = true;
            isLoadingNotifier2.value = false;
            _fetchAllAttendance();
          }
          return value
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      'Last updated: ${lastUpdated?.toString().split('.')[0]}',
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
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
                            textAlign: TextAlign.center,
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
                                    '${subjects[index]['attendance']}%',
                                    style: TextStyle(
                                      color:
                                          subjects[index]['attendance'] < 85
                                              ? Colors.red
                                              : Colors.green,
                                      // fontWeight: FontWeight.bold,
                                    ),
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
                            isLoadingNotifier2.value =
                                (loadingSub == index) ? true : false;
                            Navigator.pushNamed(
                              context,
                              '/attendance/details',
                              arguments: {
                                'subject_code': subjects[index]['subject_code'],
                                'subject_name': subjects[index]['subject_name'],
                                'attendance': subjects[index]['attendance'],
                                'attendance_history':
                                    attendanceAll['${subjects[index]['subject_code']}'],
                                'isLoading': (isLoading && loadingSub == index),
                                'isLoadingNotifier2': isLoadingNotifier2,
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
