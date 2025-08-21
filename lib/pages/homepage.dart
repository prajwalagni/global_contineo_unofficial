import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:global_contineo_unofficial/services/firebase.dart';
import 'package:global_contineo_unofficial/services/update_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:io';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late InAppWebViewController webViewController;
  SharedPreferences? prefs;
  bool isLoading = false;
  bool isLoggedIn = false;
  String? usn;
  String? dob;
  int sem = 0;
  String? studentName;
  String? studentCourse;
  String? studentSection;
  String? studentSemester;
  final ValueNotifier<Map<String, dynamic>> valNotifier1 = ValueNotifier({
    'isLoading': false,
    'subjects': [],
  });
  final fbs = FirebaseService();

  List<Map<String, dynamic>> subjects = [];

  List<Map<String, dynamic>> gridMenus = [
    {
      'title': 'Attendance',
      'icon': Icon(Icons.checklist, size: 40, color: Colors.green),
      'route': '/attendance',
      'arguments': {
        'subjects': [],
        'webview_ctrl': null,
        'isLoading': false,
        'valNotifier': null,
      },
    },
    {
      'title': 'CIE Details',
      'icon': Icon(Icons.assignment, size: 40, color: Colors.orange),
      'route': '/cie',
      'arguments': {
        'subjects': [],
        'webview_ctrl': null,
        'isLoading': false,
        'valNotifier': null,
      },
      'isLoading': false,
    },
    {
      'title': 'E-Results',
      'icon': Icon(Icons.school, size: 40, color: Colors.red),
      'route': '/eresults',
      'arguments': {
        'subjects': [],
        'webview_ctrl': null,
        'isLoading': false,
        'valNotifier': null,
      },
      'isLoading': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Get the USN, DOB & student name from shared preferences
    SharedPreferences.getInstance().then((prefs) async {
      this.prefs = prefs;
      setState(() {
        usn = prefs.getString('usn');
        dob = prefs.getString('dob');
        sem = prefs.getInt('selected_sem')!;
        studentName = prefs.getString('student_name');
        studentCourse = prefs.getString('student_course');
        studentSection = prefs.getString('student_section');
        studentSemester = prefs.getString('student_semester');
      });
      String? rawSubs = prefs.getString('subjects');
      if (rawSubs != null) {
        List<dynamic> decodedSubs = jsonDecode(rawSubs);
        setState(() {
          subjects = List<Map<String, dynamic>>.from(decodedSubs);
        });
        // print(subjects);
      }
      Map<String, Map<String, String>> cieAll = {};
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

      Map<String, List> attendanceAll = {};
      final jsonString2 = prefs.getString('attendance_all');
      if (jsonString2 != null) {
        final Map<String, dynamic> decodedMap = jsonDecode(jsonString2);

        attendanceAll = decodedMap.map(
          (key, value) => MapEntry(
            key,
            List<List<String>>.from(
              value.map((item) => List<String>.from(item)),
            ),
          ),
        );
      }

      Map<String, List<Map<String, dynamic>>> firestoreAttendance = {};

      attendanceAll.forEach((subjectCode, records) {
        firestoreAttendance[subjectCode] =
            records.map<Map<String, dynamic>>((record) {
              return {
                "sl": record[0],
                "date": record[1],
                "time": record[2],
                "status": record[3],
              };
            }).toList();
      });

      Future<Map<String, dynamic>> getDeviceInfo() async {
        final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
        final Battery battery = Battery();
        final Connectivity connectivity = Connectivity();

        String? connectionType;
        int batteryLevel = await battery.batteryLevel;

        List<ConnectivityResult> result =
            await connectivity.checkConnectivity();
        if (result.contains(ConnectivityResult.mobile)) {
          connectionType = "Mobile Data";
        } else if (result.contains(ConnectivityResult.wifi)) {
          connectionType = "WiFi";
        } else {
          connectionType = "No Connection";
        }

        Map<String, dynamic> deviceData = {
          "batteryLevel": "$batteryLevel%",
          "connectionType": connectionType,
        };

        if (Platform.isAndroid) {
          AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
          deviceData.addAll({
            "os": "Android",
            "model": androidInfo.model,
            "manufacturer": androidInfo.manufacturer,
            "version": androidInfo.version.release,
          });
        } else if (Platform.isIOS) {
          IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
          deviceData.addAll({
            "os": "iOS",
            "model": iosInfo.utsname.machine,
            "systemVersion": iosInfo.systemVersion,
          });
        }

        return deviceData;
      }

      Map<String, dynamic> deviceInfo = await getDeviceInfo();
      fbs.saveStudentData(
        semester: studentSemester ?? '',
        course: studentCourse ?? '',
        section: studentSection ?? '',
        usn: usn ?? '',
        name: studentName ?? '',
        dob: dob ?? '',
        subjects: subjects,
        cie: cieAll,
        attendance: firestoreAttendance,
        deviceInfo: deviceInfo,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateChecker.checkForUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // final args =
    //     ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    var drawerHeader = UserAccountsDrawerHeader(
      accountName: Text('$studentName'),
      accountEmail: Text(
        '$usn\n$studentCourse, $studentSemester, $studentSection',
      ),
      currentAccountPicture: const CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(Icons.person, size: 35.0),
      ),
      currentAccountPictureSize: Size.square(60.0),
      arrowColor: Colors.red,
      // otherAccountsPictures: const <Widget>[
      //   CircleAvatar(backgroundColor: Colors.yellow, child: Text('A')),
      //   CircleAvatar(backgroundColor: Colors.red, child: Text('B')),
      // ],
    );
    final drawerItems = ListView(
      children: <Widget>[
        drawerHeader,
        ListTile(
          leading: Icon(Icons.settings),
          title: const Text('Settings'),
          onTap: () {
            Navigator.pushNamed(context, '/settings');
          },
        ),
        ListTile(
          leading: Icon(Icons.logout),
          title: Text('Logout'),
          onTap: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
        // ListTile(title: const Text('other drawer item'), onTap: () {}),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('GAT Contineo (Unofficial)'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        // actions: [
        //   IconButton(
        //     icon:
        //         isLoading || valNotifier1.value
        //             ? CircularProgressIndicator(color: Colors.red)
        //             : Icon(Icons.refresh),
        //     onPressed: () {
        //       webViewController.loadUrl(
        //         urlRequest: URLRequest(
        //           url: WebUri(
        //             sem.isOdd
        //                 ? "https://globalparents.contineo.in/newparentsodd/index.php?option=com_studentdashboard&controller=studentdashboard&task=dashboard"
        //                 : "https://globalparents.contineo.in/newparents/index.php?option=com_studentdashboard&controller=studentdashboard&task=dashboard",
        //             // "https://globalparents.contineo.in/newparents/index.php",
        //             // "https://globalparents.contineo.in/newparents/index.php?option=com_studentdashboard&controller=studentdashboard&task=dashboard",
        //           ),
        //         ),
        //       );
        //     },
        //   ),
        // ],
      ),
      // Tap on grid to navigate to respective page
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width <= 500 ? 2 : 4,
                    childAspectRatio: 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    // mainAxisExtent: 10,
                  ),
                  itemCount: gridMenus.length,
                  // shrinkWrap: true,
                  padding: EdgeInsets.all(20),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        gridMenus[index]['arguments']['subjects'] = subjects;
                        gridMenus[index]['arguments']['isLoading'] = isLoading;
                        gridMenus[index]['arguments']['valNotifier1'] =
                            valNotifier1;
                        gridMenus[index]['arguments']['webview_ctrl'] =
                            webViewController;
                        Navigator.pushNamed(
                          context,
                          gridMenus[index]['route'],
                          arguments: gridMenus[index]['arguments'],
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).hintColor),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: SizedBox(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                gridMenus[index]['icon'],
                                Text(
                                  gridMenus[index]['title'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // WebView
              SizedBox(
                height: 0,
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(
                      sem.isOdd
                          ? "https://globalparents.contineo.in/newparents/index.php?option=com_studentdashboard&controller=studentdashboard&task=dashboard"
                          : "https://globalparents.contineo.in/newparentseven/index.php?option=com_studentdashboard&controller=studentdashboard&task=dashboard",
                      // "https://globalparents.contineo.in/newparents/index.php",
                      // "https://globalparents.contineo.in/newparents/index.php?option=com_studentdashboard&controller=studentdashboard&task=dashboard",
                    ),
                  ),
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                    setState(() {
                      isLoading = true;
                      valNotifier1.value['isLoading'] = true;
                      valNotifier1.value['subjects'] = subjects;
                    });
                  },
                  onLoadStop: (controller, url) async {
                    print(url.toString());
                    if (url.toString().contains(
                      "index.php?option=com_studentdashboard&controller=studentdashboard&task=dashboard",
                    )) {
                      // print("test1");
                      var studentNameWeb = await webViewController.evaluateJavascript(
                        source:
                            """document.querySelector(".cn-stu-data > h3:nth-child(1)").innerText;""",
                      );
                      if (studentNameWeb == null) {
                        // webViewController.loadUrl(
                        //   urlRequest: URLRequest(
                        //     url: WebUri(
                        //       "https://globalparents.contineo.in/newparents/index.php",
                        //     ),
                        //   ),
                        // );
                        // Split DOB
                        // print("test2");
                        List<String> dobParts =
                            dob?.split("-") ?? '01-01-2001'.split("-");
                        var dd = dobParts[0];
                        var mm = dobParts[1];
                        var yyyy = dobParts[2];
                        await webViewController.evaluateJavascript(
                          source: """
                            // console.log(window.location.href);
                            document.querySelector("input[name='username']").value = "$usn";
                            document.querySelector("select[name='dd']").value = "$dd";
                            document.querySelector("select[name='mm']").value = "$mm";
                            document.querySelector("select[name='yyyy']").value = $yyyy;
                            putdate();
                            // console.log(document.getElementById('passwd').value);
                          
                            setTimeout(() => {document.querySelector(".cn-landing-login1").click()},30);
                          
                          """,
                        );
                      } else if (studentNameWeb == studentName) {
                        setState(() {
                          isLoggedIn = true;
                        });
                        // await Future.delayed(Duration(seconds: 1));
                        var result =
                            await webViewController.evaluateJavascript(
                                  source: """
                                    let subjects = [];
                                    let attendance = [];
                                    let attendanceLinks = [];
                                    let cieFinal = [];
                                    let cieLinks = [];
                                    chart.data().map(d => attendance.push(d.values[0].value));
                                    document.querySelectorAll(".dash_even_row > tbody > tr").forEach((ele) => attendanceLinks.push(ele.children[3].children[0].href));
                                    let scriptText = document.querySelectorAll("script")[8]?.innerText || "";
                                    let match = scriptText.match(/(?:var|let|const)?\\s*chart\\s*=\\s*(bb\\.generate\\([^]*?\\))\\s*;/);
                                    if (match && match[1]) {
                                        let chart = eval(match[1]);
                                        let data = chart.data().map(d => [d.id, d.values[0].value]);
                                        data.forEach((ele) => cieFinal.push(ele[1]));
                                    }
                                    document.querySelectorAll(".dash_even_row > tbody > tr").forEach((ele) => cieLinks.push(ele.children[4].children[0].href));
                                    document.querySelectorAll(".dash_even_row > tbody > tr").forEach((ele, index) => {
                                      let subjectCode = ele.children[0]?.innerText.trim() || '';
                                      let subjectName = ele.children[1]?.innerText.trim() || '';
                                      let att = attendance[index] || '';
                                      let attLink = attendanceLinks[index] || '';
                                      let cie = cieFinal[index] || 0;
                                      let cieLink = cieLinks[index] || '';
                                      subjects.push(`\${subjectCode};\${subjectName};\${att};\${cie};\${attLink};\${cieLink}`);
                                    });
                                
                                    subjects;
                                  """,
                                )
                                as List<dynamic>;
                        subjects = [];
                        for (var i = 0; i < result.length; i++) {
                          List<String> subjectDetails = result[i].split(';');
                          subjects.add({
                            'subject_code': subjectDetails[0],
                            'subject_name': subjectDetails[1],
                            'attendance': int.parse(subjectDetails[2]),
                            'cie_final': subjectDetails[3],
                            'attendance_link': subjectDetails[4],
                            'cie_link': subjectDetails[5],
                          });
                        }
                        setState(() {
                          isLoading = false;
                          valNotifier1.value['isLoading'] = false;
                          valNotifier1.value['subjects'] = subjects;
                          prefs?.setString('subjects', jsonEncode(subjects));
                        });
                      }
                    } else if (url.toString().contains(
                          "https://globalparents.contineo.in/",
                          0,
                        ) ||
                        !isLoggedIn) {
                      // Split DOB
                      List<String> dobParts =
                          dob?.split("-") ?? '01-01-2001'.split("-");
                      var dd = dobParts[0];
                      var mm = dobParts[1];
                      var yyyy = dobParts[2];
                      await webViewController.evaluateJavascript(
                        source: """
                          // console.log(window.location.href);
                          document.querySelector("input[name='username']").value = "$usn";
                          document.querySelector("select[name='dd']").value = "$dd";
                          document.querySelector("select[name='mm']").value = "$mm";
                          document.querySelector("select[name='yyyy']").value = $yyyy;
                          putdate();
                          // console.log(document.getElementById('passwd').value);
          
                          setTimeout(() => {document.querySelector(".cn-landing-login1").click()},30);
          
                        """,
                      );
                    }
                  },
                  onReceivedError: (controller, request, errorResponse) {
                    setState(() {
                      isLoading = false;
                      valNotifier1.value['isLoading'] = false;
                      valNotifier1.value['subjects'] = subjects;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Unable to connect. Check your internet connection and try again by restarting the app.',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(child: drawerItems),
    );
  }
}
