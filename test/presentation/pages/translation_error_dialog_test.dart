import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/presentation/pages/gemini_translate_page.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';
import 'package:translate_app/theme/theme.dart';

class MockGeminiTranslateViewModel extends ChangeNotifier
    with Mock
    implements GeminiTranslateViewModel {}

void main() {
  final cases = <AppException, String>{
    const AiServiceException('x', AiFailure.unavailable): 'Service Unavailable',
    const AiServiceException('x', AiFailure.busy): 'AI Is Busy',
    const AiServiceException('x', AiFailure.timeout): 'Took Too Long',
    const AiServiceException('x', AiFailure.blocked): "Can't Translate This",
    const AiServiceException('x', AiFailure.failed): 'Something Went Wrong',
    const NetworkException('x'): 'Connection Error',
  };

  for (final MapEntry(key: exception, value: title) in cases.entries) {
    testWidgets('${exception.runtimeType} shows "$title"', (tester) async {
      final vm = MockGeminiTranslateViewModel();
      final input = TextEditingController();
      addTearDown(input.dispose);
      when(() => vm.textController).thenReturn(input);
      when(() => vm.error).thenReturn('failed');
      when(() => vm.lastException).thenReturn(exception);
      when(() => vm.isListening).thenReturn(false);
      when(() => vm.isLoading).thenReturn(false);
      when(() => vm.clearError()).thenReturn(null);

      await tester.pumpWidget(
        ChangeNotifierProvider<GeminiTranslateViewModel>.value(
          value: vm,
          child: MaterialApp(
            theme: lightTheme,
            home: Scaffold(
              body: GeminiInputBody(outputController: TextEditingController()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(title), findsOneWidget);

      // Closing resets the page's one-dialog-at-a-time guard for the next case.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });
  }

  test('backend error codes map to failure kinds', () {
    expect(
      AiServiceException.kindFromCode('ai_unavailable'),
      AiFailure.unavailable,
    );
    expect(AiServiceException.kindFromCode('ai_busy'), AiFailure.busy);
    expect(AiServiceException.kindFromCode('ai_timeout'), AiFailure.timeout);
    expect(AiServiceException.kindFromCode('ai_blocked'), AiFailure.blocked);
    expect(
      AiServiceException.kindFromCode('Too many requests'),
      AiFailure.failed,
    );
    expect(AiServiceException.kindFromCode(null), AiFailure.failed);
  });
}
