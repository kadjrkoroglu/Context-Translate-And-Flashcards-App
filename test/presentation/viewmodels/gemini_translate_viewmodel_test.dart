import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:translate_app/core/languages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translate_app/data/services/settings_service.dart';
import 'package:translate_app/domain/entities/translation_entity.dart';
import 'package:translate_app/domain/repositories/translation_repository.dart';
import 'package:translate_app/domain/usecases/translate_usecase.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/history_viewmodel.dart';

class MockTranslationRepository extends Mock implements TranslationRepository {}

class MockHistoryViewModel extends ChangeNotifier
    with Mock
    implements HistoryViewModel {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTranslationRepository repository;
  late MockHistoryViewModel history;
  late GeminiTranslateViewModel vm;
  late TextEditingController output;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'gemini_source_lang': 'English',
      'gemini_target_lang': 'Turkish',
    });
    final settings = SettingsService(await SharedPreferences.getInstance());
    repository = MockTranslationRepository();
    history = MockHistoryViewModel();
    when(
      () => history.addHistoryItem(
        word: any(named: 'word'),
        translation: any(named: 'translation'),
        translations: any(named: 'translations'),
        isGemini: any(named: 'isGemini'),
      ),
    ).thenAnswer((_) async {});
    vm = GeminiTranslateViewModel(
      TranslateUsecase(repository),
      settings,
      history,
    );
    output = TextEditingController();
  });

  tearDown(() => output.dispose());

  test('all tone variants are saved to history', () async {
    when(() => repository.translate(any(), any(), any())).thenAnswer(
      (_) async => TranslationEntity(
        originalText: 'how are you',
        translatedText: 'nasılsın | nasılsınız | naber',
        sourceLanguage: 'English',
        targetLanguage: 'Turkish',
      ),
    );
    vm.textController.text = 'how are you';

    await vm.translate(output);

    verify(
      () => history.addHistoryItem(
        word: 'how are you',
        translation: 'nasılsın',
        translations: ['nasılsın', 'nasılsınız', 'naber'],
        isGemini: true,
      ),
    ).called(1);
  });

  test('a restored item switches between its own tones', () {
    vm.restore(
      word: 'how are you',
      shown: 'nasılsınız',
      translations: ['nasılsın', 'nasılsınız', 'naber'],
    );

    expect(vm.textController.text, 'how are you');
    expect(vm.selectedToneIndex, 1);

    vm.setSelectedToneIndex(2, output);
    expect(output.text, 'naber');
  });

  test('an older item without variants keeps its one translation', () {
    vm.restore(word: 'hello', shown: 'merhaba', translations: const []);

    vm.setSelectedToneIndex(1, output);

    expect(vm.results, ['merhaba']);
    expect(output.text, 'merhaba');
  });

  test(
    'Translate is up to date until the text or a language changes',
    () async {
      when(() => repository.translate(any(), any(), any())).thenAnswer(
        (_) async => TranslationEntity(
          originalText: 'hello',
          translatedText: 'merhaba',
          sourceLanguage: 'English',
          targetLanguage: 'Turkish',
        ),
      );
      vm.textController.text = 'hello';
      expect(vm.isUpToDate, isFalse);

      await vm.translate(output);
      expect(vm.isUpToDate, isTrue);

      vm.setTargetLanguage('German', output);
      expect(vm.isUpToDate, isFalse);
      await vm.translate(output);
      expect(vm.isUpToDate, isTrue);

      vm.textController.text = 'hello there';
      expect(vm.isUpToDate, isFalse);
      verify(() => repository.translate(any(), any(), any())).called(2);
    },
  );

  test('a restored item counts as translated until something changes', () {
    vm.restore(word: 'hello', shown: 'merhaba', translations: const []);
    expect(vm.isUpToDate, isTrue);

    vm.setTargetLanguage('German', output);
    expect(vm.isUpToDate, isFalse);
  });

  test('Auto-detect source: no swap, never a recent language', () {
    vm.setSourceLanguage(autoDetect, output);
    expect(vm.sourceLanguage, autoDetect);
    expect(vm.recentLanguages, isNot(contains(autoDetect)));

    vm.swapLanguages(output);
    vm.setSourceLanguage(vm.targetLanguage, output);
    expect(vm.sourceLanguage, autoDetect);
    expect(vm.targetLanguage, 'Turkish');
  });
}
