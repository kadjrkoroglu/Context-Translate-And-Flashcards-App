import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:translate_app/domain/entities/entitlements_entity.dart';
import 'package:translate_app/domain/usecases/entitlements_usecase.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';

class MockEntitlementsUsecase extends Mock implements EntitlementsUsecase {}

EntitlementsEntity plan(String tier) => EntitlementsEntity.fromJson({
  'tier': tier,
  'entitlements': {'maxDecks': tier == 'free' ? 2 : null},
});

void main() {
  late MockEntitlementsUsecase usecase;
  late EntitlementsViewModel vm;

  setUp(() {
    usecase = MockEntitlementsUsecase();
    vm = EntitlementsViewModel(usecase);
  });

  test('only the newest load counts, whichever answers last', () async {
    final older = Completer<EntitlementsEntity>();
    final newer = Completer<EntitlementsEntity>();
    final answers = [older.future, newer.future];
    when(() => usecase.execute()).thenAnswer((_) => answers.removeAt(0));

    final first = vm.load();
    final second = vm.load();
    newer.complete(plan('premium'));
    await second;
    older.complete(plan('free'));
    await first;

    expect(vm.tier, AppTier.premium);
    expect(vm.isLoading, isFalse);
  });

  test(
    'another account starts without the last plan, even if loading fails',
    () async {
      when(() => usecase.execute()).thenAnswer((_) async => plan('premium'));
      await vm.load();
      expect(vm.entitlements, isNotNull);

      vm.reset();
      when(() => usecase.execute()).thenThrow(Exception('server error'));
      await vm.load();

      expect(vm.entitlements, isNull);
      expect(vm.error, isNotNull);
    },
  );

  test('a load still running for the old account is dropped', () async {
    final old = Completer<EntitlementsEntity>();
    when(() => usecase.execute()).thenAnswer((_) => old.future);
    final loading = vm.load();

    vm.reset();
    old.complete(plan('premium'));
    await loading;

    expect(vm.entitlements, isNull);
  });
}
