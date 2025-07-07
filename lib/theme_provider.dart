// theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  String _selectedTheme = 'system';
  double _minAttendance = 85.0; // Default value for minimum attendance

  String get selectedTheme => _selectedTheme;
  double get minAttendance => _minAttendance;

  ThemeProvider() {
    _loadSettingsFromPrefs(); // Load all settings when provider is created
  }

  Future<void> _loadSettingsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedTheme = prefs.getString('selectedTheme') ?? 'system';
    _minAttendance = prefs.getDouble('minAttendance') ?? 85.0; // Load minAttendance
    notifyListeners(); // Notify listeners after loading all settings
  }

  Future<void> setTheme(String theme) async {
    if (_selectedTheme == theme) return;
    _selectedTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTheme', theme);
    notifyListeners();
  }

  Future<void> setMinAttendance(double value) async {
    if (_minAttendance == value) return;
    _minAttendance = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('minAttendance', value);
    notifyListeners(); // Notify listeners that minAttendance has changed
  }
}