import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/data/services/live_audio_service.dart';
import 'package:translate_app/data/services/settings_service.dart';
import 'package:translate_app/domain/repositories/translation_repository.dart';
import 'package:translate_app/domain/usecases/translate_usecase.dart';
import 'package:translate_app/presentation/viewmodels/live_translate_viewmodel.dart';

class MockTranslationRepository extends Mock implements TranslationRepository {}

class MockLiveAudioService extends Mock implements LiveAudioService {}

void main() {
  late MockTranslationRepository repository;
  late MockLiveAudioService audio;
  late SettingsService settings;
  late LiveTranslateViewModel vm;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsService(await SharedPreferences.getInstance());
    repository = MockTranslationRepository();
    audio = MockLiveAudioService();
    when(() => audio.hasMicPermission()).thenAnswer((_) async => true);
    when(() => audio.stop()).thenAnswer((_) async {});
    when(() => audio.dispose()).thenAnswer((_) async {});
    vm = LiveTranslateViewModel(TranslateUsecase(repository), audio, settings);
  });

  test('language names map to the codes Gemini expects', () {
    expect(LiveTranslateViewModel.languageCodeFor('Turkish'), 'tr');
    expect(LiveTranslateViewModel.languageCodeFor('Persian'), 'fa');
    expect(LiveTranslateViewModel.languageCodeFor('Urdu'), 'ur');
  });

  test('target defaults to English and is remembered', () async {
    expect(vm.targetLanguage, 'English');
    vm.setTargetLanguage('German');
    expect(settings.liveTargetLang, 'German');
  });

  test('refused microphone stops before any time is reserved', () async {
    when(() => audio.hasMicPermission()).thenAnswer((_) async => false);

    await vm.start();

    expect(vm.status, LiveStatus.error);
    expect(vm.exception, isA<MicrophoneDeniedException>());
    verifyNever(() => repository.startLiveSession(any()));
  });

  test('a plan without Live ends in FeatureNotAvailable', () async {
    when(
      () => repository.startLiveSession(any()),
    ).thenThrow(const FeatureNotAvailableException('Not available'));

    await vm.start();

    expect(vm.status, LiveStatus.error);
    expect(vm.exception, isA<FeatureNotAvailableException>());
  });

  test('used-up month ends in QuotaExceeded', () async {
    when(() => repository.startLiveSession(any())).thenThrow(
      const QuotaExceededException('quota_exceeded', window: 'month'),
    );

    await vm.start();

    expect(vm.exception, isA<QuotaExceededException>());
    expect(vm.isActive, isFalse);
  });

  test('the target language is sent as its code', () async {
    vm.setTargetLanguage('Turkish');
    when(
      () => repository.startLiveSession(any()),
    ).thenThrow(const GeneralException('x'));

    await vm.start();

    verify(() => repository.startLiveSession('tr')).called(1);
  });

  test('clearError returns to idle', () async {
    when(
      () => repository.startLiveSession(any()),
    ).thenThrow(const GeneralException('x'));
    await vm.start();

    vm.clearError();

    expect(vm.status, LiveStatus.idle);
    expect(vm.exception, isNull);
  });
}
