import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:translate_app/data/repositories/auth_repository_impl.dart';
import 'package:translate_app/data/repositories/deck_repository_impl.dart';
import 'package:translate_app/data/repositories/favorite_repository_impl.dart';
import 'package:translate_app/data/repositories/history_repository_impl.dart';
import 'package:translate_app/data/repositories/translation_repository_impl.dart';
import 'package:translate_app/domain/usecases/auth_usecase.dart';
import 'package:translate_app/domain/usecases/deck_usecase.dart';
import 'package:translate_app/domain/usecases/favorite_usecase.dart';
import 'package:translate_app/domain/usecases/history_usecase.dart';
import 'package:translate_app/domain/usecases/translate_usecase.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/presentation/pages/auth/auth_wrapper.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:translate_app/presentation/viewmodels/favorite_viewmodel.dart';
import 'package:translate_app/theme/theme_provider.dart';
import 'package:translate_app/theme/theme.dart';
import 'package:translate_app/presentation/viewmodels/main_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/ml_translate_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/history_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';
import 'package:translate_app/data/services/local_storage_service.dart';
import 'package:translate_app/data/services/gemini_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:translate_app/data/services/settings_service.dart';

import 'package:translate_app/data/services/auth_service.dart';
import 'package:translate_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:translate_app/data/services/firestore_service.dart';
import 'package:translate_app/data/services/sync_service.dart';
import 'package:translate_app/data/services/tts_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final localStorage = LocalStorageService();
  await localStorage.init();

  final authService = AuthService();
  final authRepository = AuthRepositoryImpl(authService);
  final authUsecase = AuthUsecase(authRepository);

  final prefs = await SharedPreferences.getInstance();
  final settingsService = SettingsService(prefs);

  final envString = await rootBundle.loadString('env.json');
  final envMap = jsonDecode(envString) as Map<String, dynamic>;
  final apiKey = envMap['api_key'] as String;

  final geminiService = GeminiService(apiKey);
  await geminiService.initialize();

  final firestoreService = FirestoreService();
  final historyRepository = HistoryRepositoryImpl(localStorage, firestoreService);
  final favoriteRepository = FavoriteRepositoryImpl(
    localStorage,
    firestoreService,
  );
  final deckRepository = DeckRepositoryImpl(localStorage, firestoreService);
  final syncService = SyncService(localStorage, firestoreService);

  final historyUsecase = HistoryUsecase(historyRepository);
  final favoriteUsecase = FavoriteUsecase(favoriteRepository);
  final deckUsecase = DeckUsecase(deckRepository);

  runApp(
    MultiProvider(
      providers: [
        Provider<TtsService>(create: (_) => TtsService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(settingsService)),
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authUsecase, syncService),
        ),
        ChangeNotifierProvider(create: (_) => MainViewModel()),
        ChangeNotifierProvider<SyncService>.value(value: syncService),
        Provider<SettingsService>.value(value: settingsService),
        Provider<LocalStorageService>.value(value: localStorage),
        Provider<AuthUsecase>.value(value: authUsecase),
        Provider<HistoryUsecase>.value(value: historyUsecase),
        Provider<FavoriteUsecase>.value(value: favoriteUsecase),
        Provider<DeckUsecase>.value(value: deckUsecase),
        ChangeNotifierProvider(
          create: (context) => FavoriteViewModel(
            context.read<FavoriteUsecase>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => HistoryViewModel(context.read<HistoryUsecase>()),
        ),
        ChangeNotifierProvider(
          create: (context) => DecksViewModel(context.read<DeckUsecase>()),
        ),
        ChangeNotifierProvider(
          create: (context) => GeminiTranslateViewModel(
            TranslateUsecase(TranslationRepositoryImpl(geminiService)),
            context.read<SettingsService>(),
            context.read<HistoryViewModel>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => MLTranslateViewModel(
            context.read<SettingsService>(),
            context.read<HistoryViewModel>(),
          ),
        ),
      ],
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
          home: const AuthWrapper(),
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
        );
      },
    );
  }
}
