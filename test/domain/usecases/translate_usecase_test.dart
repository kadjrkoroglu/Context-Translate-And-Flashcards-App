import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:translate_app/domain/entities/translation_entity.dart';
import 'package:translate_app/domain/repositories/translation_repository.dart';
import 'package:translate_app/domain/usecases/translate_usecase.dart';

class MockTranslationRepository extends Mock implements TranslationRepository {}

void main() {
  late MockTranslationRepository mockRepo;
  late TranslateUsecase usecase;

  setUp(() {
    mockRepo = MockTranslationRepository();
    usecase = TranslateUsecase(mockRepo);
  });

  test('başarılı çeviri döndürür', () async {
    when(() => mockRepo.translate('hello', 'en', 'tr')).thenAnswer(
      (_) async => TranslationEntity(
        originalText: 'hello',
        translatedText: 'merhaba',
        sourceLanguage: 'en',
        targetLanguage: 'tr',
      ),
    );

    final result = await usecase.execute('hello', 'en', 'tr');

    expect(result.translatedText, 'merhaba');
    expect(result.originalText, 'hello');
  });

  test('repository bir kez çağrılır', () async {
    when(() => mockRepo.translate(any(), any(), any())).thenAnswer(
      (_) async => TranslationEntity(
        originalText: 'hello',
        translatedText: 'merhaba',
        sourceLanguage: 'en',
        targetLanguage: 'tr',
      ),
    );

    await usecase.execute('hello', 'en', 'tr');

    verify(() => mockRepo.translate('hello', 'en', 'tr')).called(1);
  });
}
