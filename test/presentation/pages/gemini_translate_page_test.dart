import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/data/services/tts_service.dart';
import 'package:translate_app/presentation/pages/gemini_translate_page.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';
import 'package:translate_app/theme/theme.dart';

class MockGeminiTranslateViewModel extends ChangeNotifier
    with Mock
    implements GeminiTranslateViewModel {}

class MockTtsService extends Mock implements TtsService {}

class FakeTextEditingController extends Fake implements TextEditingController {}

class FakeTtsService extends Fake implements TtsService {}

void main() {
  late MockGeminiTranslateViewModel mockViewModel;
  late MockTtsService mockTts;
  late TextEditingController outputController;
  late TextEditingController inputController;

  setUpAll(() {
    registerFallbackValue(FakeTextEditingController());
    registerFallbackValue(FakeTtsService());
  });

  setUp(() {
    mockViewModel = MockGeminiTranslateViewModel();
    mockTts = MockTtsService();
    outputController = TextEditingController();
    inputController = TextEditingController();

    when(() => mockViewModel.sourceLanguage).thenReturn('English');
    when(() => mockViewModel.targetLanguage).thenReturn('Turkish');
    when(() => mockViewModel.recentLanguages).thenReturn(['English']);
    when(() => mockViewModel.isLoading).thenReturn(false);
    when(() => mockViewModel.error).thenReturn(null);
    when(() => mockViewModel.isListening).thenReturn(false);
    when(() => mockViewModel.textController).thenReturn(inputController);
  });

  tearDown(() {
    outputController.dispose();
    inputController.dispose();
  });

  Widget buildSubject() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GeminiTranslateViewModel>.value(
          value: mockViewModel,
        ),
        Provider<TtsService>.value(value: mockTts),
      ],
      child: MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: GeminiLanguageHeader(outputController: outputController),
        ),
      ),
    );
  }

  testWidgets('tapping swap button calls swapLanguages', (tester) async {
    when(() => mockViewModel.swapLanguages(any())).thenReturn(null);

    await tester.pumpWidget(buildSubject());
    await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
    await tester.pumpAndSettle();

    verify(() => mockViewModel.swapLanguages(any())).called(1);
  });

  testWidgets('shows Listening overlay when isListening', (tester) async {
    when(() => mockViewModel.isListening).thenReturn(true);

    await tester.pumpWidget(buildSubject());
    expect(find.text('Listening...'), findsOneWidget);
  });
}
