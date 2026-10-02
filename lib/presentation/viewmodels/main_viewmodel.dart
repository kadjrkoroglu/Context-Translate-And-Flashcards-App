import 'package:flutter/material.dart';

class MainViewModel extends ChangeNotifier {
  // 0 = Live, 1 = AI, 2 = Basic.
  static const int livePage = 0;
  static const int aiPage = 1;
  static const int basicPage = 2;

  final PageController _pageController = PageController(initialPage: aiPage);
  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  bool _isRestoring = false;

  PageController get pageController => _pageController;
  TextEditingController get outputController => _outputController;
  TextEditingController get sourceController => _sourceController;

  double get page {
    try {
      if (_pageController.hasClients && _pageController.positions.length == 1) {
        return _pageController.page ?? aiPage.toDouble();
      }
    } catch (_) {}
    return aiPage.toDouble();
  }

  bool get isRestoring => _isRestoring;
  bool get isLivePage => page < 0.5;
  bool get isMLPage => page > 1.5;

  void animateToPage(int index) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
    notifyListeners();
  }

  void restoreTranslation(String translation, bool isGemini) {
    _isRestoring = true;
    _outputController.text = translation;
    animateToPage(isGemini ? aiPage : basicPage);
    Future.delayed(const Duration(milliseconds: 500), () {
      _isRestoring = false;
    });
  }

  void clearOutput() {
    if (_isRestoring) return;
    _outputController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _outputController.dispose();
    super.dispose();
  }
}
