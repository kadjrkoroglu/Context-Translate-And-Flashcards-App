import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: Colors.grey.shade200,
    primary: Colors.grey.shade300,
    secondary: Colors.grey.shade400,
    tertiary: Colors.grey.shade600,
    surfaceContainer: Colors.black,
    inversePrimary: Colors.grey.shade900,
    outline: Colors.black,
  ),
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Colors.grey.shade900,
    selectionColor: Colors.grey.shade400,
    selectionHandleColor: Colors.grey.shade700,
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: const Color.fromARGB(255, 27, 27, 27),
    primary: Colors.grey.shade800,
    secondary: Colors.grey.shade700,
    tertiary: Colors.grey.shade600,
    surfaceContainer: Colors.grey.shade700,
    inversePrimary: Colors.grey.shade100,
    outline: const Color.fromARGB(255, 27, 27, 27),
  ),
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Colors.white,
    selectionColor: Colors.grey.shade700,
    selectionHandleColor: Colors.grey.shade500,
  ),
);
