import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  // Follows system theme by default
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void useSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
}
