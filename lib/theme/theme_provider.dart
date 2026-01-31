import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  // Başlangıçta sistem temasını takip etmesi için ThemeMode.system kullanıyoruz
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // Temayı manuel değiştirmek istersen diye bu metodları tutuyoruz
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
