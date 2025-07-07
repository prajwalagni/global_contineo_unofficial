import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Import package_info_plus
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appVersion = 'Loading...';
  int _tapCount = 0; // Tap counter for the Easter egg
  bool _showBetaToggle = false; // Controls visibility of the beta toggle
  bool _betaUpdatesEnabled = false; // State of the beta updates toggle

  late SharedPreferences _prefs; // SharedPreferences instance

  @override
  void initState() {
    super.initState();
    _loadAppData();
  }

  Future<void> _loadAppData() async {
    _prefs =
        await SharedPreferences.getInstance(); // Initialize SharedPreferences

    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
      // Load beta updates state and determine initial toggle visibility
      _betaUpdatesEnabled = _prefs.getBool('betaUpdates') ?? false;
      // If beta updates were previously enabled, show the toggle immediately
      if (_betaUpdatesEnabled) {
        _showBetaToggle = true;
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $uri';
    }
  }

  // Helper function to show a SnackBar (toast-like message)
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar(); // Hide any current snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(
          seconds: 2,
        ), // Short duration for a toast effect
      ),
    );
  }

  // Easter egg tap logic
  void _handleVersionTap() {
    // Only count taps if the toggle is not yet visible
    if (!_showBetaToggle) {
      setState(() {
        _tapCount++;
        int tapsRemaining = 6 - _tapCount;

        if (tapsRemaining > 0 && tapsRemaining <= 4) {
          // Show message for 2nd click onwards (4 remaining, 3 remaining, etc.)
          _showSnackBar('$tapsRemaining more taps to reveal Beta Updates!');
        }

        if (_tapCount >= 6) {
          _showBetaToggle = true;
          _tapCount = 0; // Reset tap count after revealing
          _showSnackBar('Beta Updates option revealed!');
        }
      });
    }
  }

  // Toggle switch logic
  void _toggleBetaUpdates(bool value) async {
    setState(() {
      _betaUpdatesEnabled = value;
    });
    await _prefs.setBool('betaUpdates', value); // Save to SharedPreferences

    if (value) {
      _showSnackBar('Beta Updates Enabled');
    } else {
      _showSnackBar('Beta Updates Disabled');
    }
  }

  static const String _fullTerms = '''
★ 1. Introduction
Welcome to GAT Contineo (Unofficial), a mobile application developed to simplify access to academic information for students of Global Academy of Technology. This app is independently developed by a student and is not officially affiliated with or endorsed by Global Academy of Technology, contineo.in, or its associated organizations.
By using this app, you agree to the terms outlined below. If you do not agree, please refrain from using the app.

---
★ 2. Information We Collect
To provide, maintain, and improve the app's functionality, we collect the following types of information:
• ★Student Information
    • University Seat Number (USN)
    • Date of Birth (DOB)
    • Full Name
    • Semester, Section, Branch
    • Attendance Details
    • CIE (Continuous Internal Evaluation) and Internal Assessment Marks
• ★ Device Information
    • Device System Details (Model, OS version, etc.)
    • Network Information (IP Address, Network Type)
    • Screen Orientation, Screen Brightness
    • Battery Level and Status
    • Anonymous diagnostic and usage data (for crash reports and analytics)
⚠️ The app merely retrieves information already accessible to the student via the official portal [contineo.in] after a successful login. It does not bypass any security mechanisms or extract unauthorized data.

---
★ 3. How We Collect Information
Information is collected:
• Directly from user input within the app
• By automating the login process to https://globalparents.contineo.in with the user's consent, retrieving academic data displayed on the platform
• Automatically from the device for app improvement and diagnostics

---
★ 4. How We Use Your Information
The collected information is used strictly to:
• Display academic data conveniently within the app
• Provide access to academic data even when the official portal is temporarily unavailable
• Notify users of any changes or discrepancies in their academic records
• Improve app functionality and user experience
• Enhance app stability through diagnostics and crash analytics
We DO NOT:
• Sell, rent, or trade your personal or academic information to third parties
• Use your data for purposes unrelated to the app's intended academic features

---
★ 5. Data Storage and Security
Your data may be stored:
• Locally on your device using Shared Preferences
• Securely in Google Firebase Firestore, for backup and offline access purposes
While reasonable technical measures are in place to protect your data, no method of transmission or storage is 100% secure. By using the app, you acknowledge and accept this risk.

---
★ 6. Third-Party Services
The app uses trusted third-party services, including:
• Firebase Analytics and Crashlytics (for usage analytics and crash reporting)
• GitHub Releases (for distributing app updates)
These services may independently collect technical information under their own privacy policies.

---
★ 7. User Responsibility
You are responsible for:
• Keeping your login credentials secure
• Using the app ethically and only for your personal academic tracking
• Ensuring your device remains secure and up to date

---
★ 8. Changes to This Policy
We reserve the right to modify these Terms of Service and Privacy Policy at any time. Changes will be communicated within the app or through app updates.

---
★ 9. Contact
For questions, feedback, or concerns, you can contact the developer:
• Developer: Prajwal S.
• Contact: Available through GitHub issues or in-app contact options

---
★ 10. Acknowledgment
By using this app, you confirm that:
• You have read, understood, and agree to these Terms of Service and Privacy Policy
• You are aware that the app retrieves your academic data directly from https://globalparents.contineo.in after your consent-based login
• You are responsible for the lawful use of the app
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About GAT Contineo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Description
            Text(
              'GAT Contineo (Unofficial)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8.0),
            Text(
              'GAT Contineo (Unofficial) helps GAT(Global Academy of Technology) students quickly access their Attendance, CIE/IA Marks, and academic details directly from contineo.in. Clean design, offline backup, and visual change alerts — all in one place. Unofficial, student-made, open-source.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16.0),
            // App Version with GestureDetector for tap detection
            GestureDetector(
              onTap: _handleVersionTap,
              child: Text(
                'Version: $_appVersion', // Display app version here
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 24.0),
            // Beta Updates Toggle (conditionally visible)
            if (_showBetaToggle) // Only display if _showBetaToggle is true
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Beta Updates'),
                    subtitle: const Text(
                      'Receive early access to new features and bug fixes.',
                    ),
                    value: _betaUpdatesEnabled,
                    onChanged: _toggleBetaUpdates,
                  ),
                  const Divider(),
                  const SizedBox(
                    height: 16.0,
                  ), // Add some spacing after the toggle
                ],
              ),

            // Terms of Service & Privacy Policy Section (Truncated with Read More)
            Text(
              'Terms of Service & Privacy Policy',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8.0),
            Text(
              _fullTerms.split('---')[0].trim(),
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Terms of Service & Privacy Policy'),
                        content: SingleChildScrollView(
                          child: Text(
                            _fullTerms,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Close'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('Read More'),
              ),
            ),
            const SizedBox(height: 24.0),

            // Contact Developer Section
            Text(
              'Contact Developer',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8.0),
            ListTile(
              leading: const Icon(Icons.telegram),
              title: const Text('Prajwal S A'),
              subtitle: const Text('Chat on Telegram'),
              onTap: () => _launchUrl('https://t.me/prajwalsa'),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}
