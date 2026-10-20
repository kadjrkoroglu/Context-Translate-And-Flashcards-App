import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:translate_app/presentation/pages/main_page.dart';
import 'package:translate_app/presentation/pages/welcome_page.dart';
import 'package:translate_app/data/services/settings_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = context.read<SettingsService>();

    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        if (authViewModel.isAuthenticated) {
          return const MainPage();
        } else {
          // If not authenticated, check if it's the first run
          if (settingsService.isFirstRun) {
            return const WelcomePage();
          } else {
            return const MainPage();
          }
        }
      },
    );
  }
}
