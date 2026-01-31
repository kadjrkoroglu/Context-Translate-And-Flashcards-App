import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/pages/main_page.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:translate_app/theme/theme_provider.dart';
import 'package:translate_app/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final envString = await rootBundle.loadString('env.json');
  final envMap = jsonDecode(envString) as Map<String, dynamic>;
  final apiKey = envMap['api_key'] as String;

  Gemini.init(apiKey: apiKey);
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const MainPage(),
          theme: lightTheme, // lib/theme/theme.dart içinden geliyor
          darkTheme: darkTheme, // lib/theme/theme.dart içinden geliyor
          themeMode:
              themeProvider.themeMode, // Sistem ayarını buradan takip eder
        );
      },
    );
  }
}
