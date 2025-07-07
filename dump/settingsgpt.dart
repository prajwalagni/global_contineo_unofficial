import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:global_contineo_unofficial/main.dart'; // for ThemeProvider

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _minAttendance = 85.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Theme", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            title: const Text("System Default"),
            leading: Radio<ThemeMode>(
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) => themeProvider.setTheme(value!),
            ),
          ),
          ListTile(
            title: const Text("Light"),
            leading: Radio<ThemeMode>(
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) => themeProvider.setTheme(value!),
            ),
          ),
          ListTile(
            title: const Text("Dark"),
            leading: Radio<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) => themeProvider.setTheme(value!),
            ),
          ),
          const Divider(),
          const Text("Min. Attendance %", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Slider(
            value: _minAttendance,
            min: 50,
            max: 100,
            divisions: 10,
            label: "${_minAttendance.round()}%",
            onChanged: (value) {
              setState(() {
                _minAttendance = value;
              });
            },
          ),
          const Divider(),
          const Text("About the App", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("This app helps students manage attendance and marks effectively."),
          TextButton(
            onPressed: () => _launchUrl('https://yourdomain.com/terms'),
            child: const Text("Terms & Conditions / Privacy Policy"),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text("Give Feedback"),
            onTap: () {
              // You will provide method later
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Feedback option coming soon!")),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text("Developer: Prajwal S Agnihothri"),
            subtitle: const Text("View GitHub Repo"),
            onTap: () => _launchUrl('https://github.com/prajwalagni/global_contineo_unofficial/'),
            trailing: TextButton(
              onPressed: () {
                // You will tell the way to contact later
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Contact Developer coming soon!")),
                );
              },
              child: const Text("Contact"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
