import 'package:flutter/material.dart';

class MainViewModel extends ChangeNotifier {
  final PageController _pageController = PageController();
  final TextEditingController _outputController = TextEditingController();

  PageController get pageController => _pageController;
  TextEditingController get outputController => _outputController;

  void animateToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    notifyListeners();
  }

  void clearOutput() {
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
