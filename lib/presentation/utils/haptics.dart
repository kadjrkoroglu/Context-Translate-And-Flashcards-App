import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';

/// Taps on start and on success; an error vibrates with its dialog.
Future<void> translateWithHaptics(
  GeminiTranslateViewModel vm,
  TextEditingController output,
) async {
  final runs =
      !vm.isUpToDate &&
      vm.textController.text.isNotEmpty &&
      vm.targetLanguage != '-';
  if (runs) HapticFeedback.lightImpact();
  await vm.translate(output);
  if (runs && vm.error == null) HapticFeedback.lightImpact();
}

/// iOS only: Android already vibrates on a long press.
void longPressHaptic() {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    HapticFeedback.mediumImpact();
  }
}
