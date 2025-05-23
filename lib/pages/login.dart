import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

bool isLoading = false;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late InAppWebViewController webViewController;
  int selectedSem = 0;

  // Controllers
  final TextEditingController usnController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  late String dd, mm, yyyy;

  // Date Picker Function
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2005, 1, 1), // Default starting date
      firstDate: DateTime(1900), // Minimum selectable date
      lastDate: DateTime.now(), // Maximum selectable date (Today)
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue, // Header background color
            // accentColor: Colors.blue,    // Button color
            colorScheme: ColorScheme.light(primary: Colors.blue),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // print(pickedDate);
      String formattedDate =
          "${pickedDate.day.toString().padLeft(2, '0')}-"
          "${pickedDate.month.toString().padLeft(2, '0')}-"
          "${pickedDate.year}";

      dobController.text = formattedDate;

      // Split DOB
      List<String> dobParts = dobController.text.split("-");
      dd = dobParts[0];
      mm = dobParts[1];
      yyyy = dobParts[2];
      // print(formattedDate);
      // print(dobController);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GAT Contineo'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO : Implement settings action
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: Form(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 15,
                children: [
                  DropdownButtonFormField(
                    hint: Text('Select Semester'),
                    icon: const Icon(Icons.arrow_drop_down),
                    decoration: InputDecoration(
                      labelText: 'Semester',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 1, child: Text('1st')),
                      DropdownMenuItem(value: 2, child: Text('2nd')),
                    ],
                    validator: (value) {
                      if (value == null || value == 0) {
                        return 'Please select semester';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      print(value);
                      setState(() {
                        selectedSem = value as int;
                      });
                    },
                  ),
                  TextFormField(
                    controller: usnController,
                    decoration: const InputDecoration(
                      labelText: 'USN',
                      hintText: 'Enter your USN',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your USN';
                      } else if (value.length != 10) {
                        return 'USN should be 10 characters long';
                      } else if (!RegExp(
                        r'^[1-9]{1}[A-Za-z]{2}[0-9]{2}[A-Za-z]{2}[0-9]{3}$',
                      ).hasMatch(value)) {
                        return 'Invalid USN format';
                      }
                      return null;
                    },
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onFieldSubmitted: (value) {
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  TextFormField(
                    controller: dobController,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth (DD-MM-YYYY)',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    onFieldSubmitted: (value) {},
                  ),
                  isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                        onPressed: () async {
                          if (usnController.text.isEmpty ||
                              dobController.text.isEmpty ||
                              selectedSem == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            // Navigator.pushReplacementNamed(
                            //   context,
                            //   '/home',
                            //   arguments: {'usn': '', 'dob': ''},
                            // );
                          } else {
                            setState(() {
                              isLoading = true;
                            });
                            // isLoading = true;
                            await webViewController.evaluateJavascript(
                              source: """
                            // console.log(window.location.href);
                            document.querySelector("input[name='username']").value = "${usnController.text}";
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
                        child: Text('Login'),
                      ),
                  // WebView
                  SizedBox(
                    height: 0,
                    child: InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri(
                          "https://globalparents.contineo.in/newparents/index.php",
                          // "https://globalparents.contineo.in/newparents/index.php?option=com_studentdashboard&controller=studentdashboard&task=dashboard",
                        ),
                      ),
                      onWebViewCreated: (controller) {
                        webViewController = controller;
                      },
                      onLoadStop: (controller, url) async {
                        if (url.toString() ==
                            "https://globalparents.contineo.in/newparents/index.php?option=com_studentdashboard&controller=studentdashboard&task=dashboard") {
                          var studentName = await webViewController
                              .evaluateJavascript(
                                source:
                                    """document.querySelector(".cn-stu-data > h3:nth-child(1)").innerText;""",
                              );
                          showDialog(
                            context: context,
                            builder: (context) {
                              return studentName != null
                                  ? AlertDialog(
                                    title: const Text('Verification'),
                                    content: Text('Are you $studentName?\n'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            isLoading = false;
                                          });
                                          Navigator.of(context).pop();
                                          webViewController.loadUrl(
                                            urlRequest: URLRequest(
                                              url: WebUri(
                                                "https://globalparents.contineo.in/newparents/index.php",
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          SharedPreferences prefs =
                                              await SharedPreferences.getInstance();
                                          prefs.setBool('isLoggedIn', true);
                                          prefs.setString(
                                            'usn',
                                            usnController.text,
                                          );
                                          prefs.setString(
                                            'dob',
                                            dobController.text,
                                          );
                                          prefs.setString(
                                            'student_name',
                                            studentName,
                                          );
                                          prefs.setInt(
                                            'selected_sem',
                                            selectedSem,
                                          );
                                          setState(() {
                                            isLoading = false;
                                          });
                                          Navigator.of(context).pop();
                                          Navigator.pushReplacementNamed(
                                            context,
                                            '/home',
                                            // arguments: {
                                            //   'usn': usnController.text,
                                            //   'dob': dobController.text,
                                            // },
                                          );
                                        },
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  )
                                  : AlertDialog(
                                    title: const Text('Verification'),
                                    content: Text('Unable to verify'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            isLoading = false;
                                          });
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                            },
                          );
                        } else if (url.toString() ==
                                "https://globalparents.contineo.in/newparents/index.php" &&
                            isLoading) {
                          setState(() {
                            isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to login!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      onReceivedError: (controller, request, errorResponse) {
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
          ),
        ),
      ),
    );
  }
}
