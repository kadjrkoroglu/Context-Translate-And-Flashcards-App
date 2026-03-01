import 'package:flutter/material.dart';

class MainViewModel extends ChangeNotifier {
  final PageController _pageController = PageController();
  final TextEditingController _outputController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();

  PageController get pageController => _pageController;
  TextEditingController get outputController => _outputController;
  TextEditingController get sourceController => _sourceController;

  bool get isMLPage {
    try {
      if (_pageController.hasClients && _pageController.positions.length == 1) {
        return (_pageController.page ?? 0) > 0.5;
      }
    } catch (_) {}
    return false;
  }

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
