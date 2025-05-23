import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:global_contineo_unofficial/pages/attendance/attendance.dart';
import 'package:global_contineo_unofficial/pages/attendance/attendance_details.dart';
import 'package:global_contineo_unofficial/pages/cie/cie.dart';
import 'package:global_contineo_unofficial/pages/cie/cie_details.dart';
import 'package:global_contineo_unofficial/pages/homepage.dart';
import 'package:global_contineo_unofficial/pages/login.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'GAT Contineo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlueAccent,
          primary: Colors.lightBlueAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlueAccent,
          primary: Colors.lightBlueAccent[700],
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: MyApp(),
      routes: {
        '/home': (context) => const Homepage(),
        '/login': (context) => const LoginPage(),
        '/attendance': (context) => const AttendanceHomePage(),
        '/attendance/details': (context) => const AttendanceDetails(),
        '/cie': (context) => const CiePage(),
        '/cie/details': (context) => const CieDetailsPage(),
      },
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn')!;
    });
  }

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn ? Homepage() : LoginPage();
  }
}