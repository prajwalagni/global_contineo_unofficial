import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:global_contineo_unofficial/services/update_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
  String? studentName;

  List<Map<String, dynamic>> subjects = [];

  List<Map<String, dynamic>> gridMenus = [
    {
      'title': 'Attendance',
      'icon': Icon(Icons.checklist, size: 40, color: Colors.green),
      'route': '/attendance',
      'arguments': {'subjects': [], 'webview_ctrl': null, 'isLoading': false},
    },
    {
      'title': 'CIE Details',
      'icon': Icon(Icons.assignment, size: 40, color: Colors.orange),
      'route': '/cie',
      'arguments': {'subjects': [], 'webview_ctrl': null, 'isLoading': false},
      'isLoading': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Get the USN, DOB & student name from shared preferences
    SharedPreferences.getInstance().then((prefs) {
      this.prefs = prefs;
      setState(() {
        usn = prefs.getString('usn');
        dob = prefs.getString('dob');
        studentName = prefs.getString('student_name');
      });
      String? rawSubs = prefs.getString('subjects');
      if (rawSubs != null) {
        List<dynamic> decodedSubs = jsonDecode(rawSubs);
        setState(() {
          subjects = List<Map<String, dynamic>>.from(decodedSubs);
        });
        // print(subjects);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateChecker.checkForUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // final args =
    //     ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    return Scaffold(
      appBar: AppBar(
        title: const Text('GAT Contineo'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/login');
              // TODO : Implement settings action
            },
          ),
        ],
      ),
      // Tap on grid to navigate to respective page
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
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
                        border: Border.all(color: Colors.black),
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
                    // "https://globalparents.contineo.in/newparents/index.php",
                    "https://globalparents.contineo.in/newparents/index.php?option=com_studentdashboard&controller=studentdashboard&task=dashboard",
                  ),
                ),
                onWebViewCreated: (controller) {
                  webViewController = controller;
                  setState(() {
                    isLoading = true;
                  });
                },
                onLoadStop: (controller, url) async {
                  if (url.toString() ==
                      "https://globalparents.contineo.in/newparents/index.php?option=com_studentdashboard&controller=studentdashboard&task=dashboard") {
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
                                    subjects.push(\`\${subjectCode};\${subjectName};\${att};\${cie};\${attLink};\${cieLink}\`);
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
                        prefs?.setString('subjects', jsonEncode(subjects));
                      });
                    }
                  }
                  // else if (url.toString() ==
                  //         "https://globalparents.contineo.in/newparents/index.php" &&
                  //     !isLoggedIn) {
                  //   // Split DOB
                  //   List<String> dobParts = dob?.split("-") ?? '01-01-2001'.split("-");
                  //   var dd = dobParts[0];
                  //   var mm = dobParts[1];
                  //   var yyyy = dobParts[2];
                  //   await webViewController.evaluateJavascript(
                  //     source: """
                  //       // console.log(window.location.href);
                  //       document.querySelector("input[name='username']").value = "$usn";
                  //       document.querySelector("select[name='dd']").value = "$dd";
                  //       document.querySelector("select[name='mm']").value = "$mm";
                  //       document.querySelector("select[name='yyyy']").value = $yyyy;
                  //       putdate();
                  //       // console.log(document.getElementById('passwd').value);

                  //       setTimeout(() => {document.querySelector(".cn-landing-login1").click()},30);

                  //     """,
                  //   );
                  // }
                },
                onReceivedError: (controller, request, errorResponse) {
                  setState(() {
                    isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Unable to connect. Check your internet connection and try again.',
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
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(child: Container()),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
