import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:translate_app/presentation/utils/haptics.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';

class MockGeminiTranslateViewModel extends ChangeNotifier
    with Mock
    implements GeminiTranslateViewModel {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final haptics = <Object?>[];
  final input = TextEditingController(text: 'hello');
  final output = TextEditingController();
  late MockGeminiTranslateViewModel vm;

  setUp(() {
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        });
    vm = MockGeminiTranslateViewModel();
    when(() => vm.textController).thenReturn(input);
    when(() => vm.targetLanguage).thenReturn('Italian');
    when(() => vm.isUpToDate).thenReturn(false);
    when(() => vm.translate(output)).thenAnswer((_) async {});
  });

  test('taps on start and on success', () async {
    when(() => vm.error).thenReturn(null);
    await translateWithHaptics(vm, output);
    expect(haptics, [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.lightImpact',
    ]);
  });

  test('an error leaves the vibration to its dialog', () async {
    when(() => vm.error).thenReturn('No internet');
    await translateWithHaptics(vm, output);
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  test('stays still when already translated', () async {
    when(() => vm.isUpToDate).thenReturn(true);
    when(() => vm.error).thenReturn(null);
    await translateWithHaptics(vm, output);
    expect(haptics, isEmpty);
    verify(() => vm.translate(output)).called(1);
  });
}
