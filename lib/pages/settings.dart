import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:global_contineo_unofficial/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _selectedThemeOption;

  @override
  void initState() {
    super.initState();
    _selectedThemeOption = Provider.of<ThemeProvider>(context, listen: false).selectedTheme;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // App Theme Section
          ListTile(
            title: const Text('App Theme'),
            subtitle: Text('Current: ${_selectedThemeOption!.toUpperCase()}'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Select Theme'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        RadioListTile<String>(
                          title: const Text('System Default'),
                          value: 'system',
                          groupValue: _selectedThemeOption,
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                _selectedThemeOption = value;
                              });
                              themeProvider.setTheme(value);
                              Navigator.pop(context);
                            }
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Light'),
                          value: 'light',
                          groupValue: _selectedThemeOption,
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                _selectedThemeOption = value;
                              });
                              themeProvider.setTheme(value);
                              Navigator.pop(context);
                            }
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Dark'),
                          value: 'dark',
                          groupValue: _selectedThemeOption,
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                _selectedThemeOption = value;
                              });
                              themeProvider.setTheme(value);
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const Divider(),

          // Min. Attendance % Slider Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Min. Attendance %: ${themeProvider.minAttendance.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  value: themeProvider.minAttendance,
                  min: 50.0,
                  max: 100.0,
                  divisions: 100,
                  label: themeProvider.minAttendance.toStringAsFixed(1),
                  onChanged: (double value) {
                    themeProvider.setMinAttendance(value);
                  },
                ),
              ],
            ),
          ),
          const Divider(),

          // About the App Section
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About the App'),
            onTap: () {
              Navigator.pushNamed(context, '/about'); // Navigate to the AboutPage
            },
          ),
          
          // Feedback Section
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Send Feedback'),
            onTap: () {
              Navigator.pushNamed(context, '/feedback'); // Navigate to the FeedbackPage
            },
          ),
          // Other settings options
        ],
      ),
    );
  }
}