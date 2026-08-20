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
          body: GeminiTranslatePage(outputController: outputController),
        ),
      ),
    );
  }

  testWidgets('renders GeminiTranslatePage', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.byType(GeminiTranslatePage), findsOneWidget);
  });

  testWidgets('displays text input field', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('displays swap languages button', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
  });

  testWidgets('tapping swap button calls swapLanguages', (tester) async {
    when(() => mockViewModel.swapLanguages(any())).thenReturn(null);

    await tester.pumpWidget(buildSubject());
    await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
    await tester.pumpAndSettle();

    verify(() => mockViewModel.swapLanguages(any())).called(1);
  });

  testWidgets('displays clear button when output has text', (tester) async {
    outputController.text = 'Hello';

    await tester.pumpWidget(buildSubject());
    expect(find.byIcon(Icons.clear_rounded), findsOneWidget);
  });

  testWidgets('does not display clear button when output is empty',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.byIcon(Icons.clear_rounded), findsNothing);
  });

  testWidgets('tapping clear button calls clear', (tester) async {
    outputController.text = 'Hello';
    when(() => mockViewModel.clear(any())).thenReturn(null);

    await tester.pumpWidget(buildSubject());
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();

    verify(() => mockViewModel.clear(any())).called(1);
  });

  testWidgets('displays volume button when output has text', (tester) async {
    outputController.text = 'Merhaba';

    await tester.pumpWidget(buildSubject());
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
  });

  testWidgets('tapping volume button calls speakInputText', (tester) async {
    outputController.text = 'Merhaba';
    when(() => mockViewModel.speakInputText(any())).thenAnswer((_) async {});

    await tester.pumpWidget(buildSubject());
    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pumpAndSettle();

    verify(() => mockViewModel.speakInputText(any())).called(1);
  });

  testWidgets('shows Listening overlay when isListening', (tester) async {
    when(() => mockViewModel.isListening).thenReturn(true);

    await tester.pumpWidget(buildSubject());
    expect(find.text('Listening...'), findsOneWidget);
  });
}
