import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:translate_app/data/services/purchases_service.dart';
import 'package:translate_app/domain/entities/entitlements_entity.dart';
import 'package:translate_app/domain/repositories/entitlements_repository.dart';
import 'package:translate_app/domain/usecases/entitlements_usecase.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/subscription_viewmodel.dart';

class MockPurchasesService extends Mock implements PurchasesService {}

class MockEntitlementsRepository extends Mock
    implements EntitlementsRepository {}

const _context = PresentedOfferingContext('default', null, null);

Package package(
  String id,
  String productId,
  String price, {
  bool trial = true,
}) => Package(
  id,
  PackageType.monthly,
  StoreProduct(
    productId,
    '',
    '',
    5.99,
    price,
    'USD',
    introductoryPrice: trial
        ? const IntroductoryPrice(0, r'$0.00', 'P2W', 1, PeriodUnit.week, 2)
        : null,
  ),
  _context,
);

final standard = package(
  'standard_monthly',
  'decklingo_standard_monthly',
  r'$5.99',
);
final premium = package(
  'premium_monthly',
  'decklingo_premium_monthly',
  r'$9.99',
);

EntitlementsEntity entitlementsOf(String tier) =>
    EntitlementsEntity.fromJson({'tier': tier, 'entitlements': <String, dynamic>{}});

void main() {
  late MockPurchasesService purchases;
  late MockEntitlementsRepository repository;
  late EntitlementsViewModel entitlements;
  late SubscriptionViewModel vm;
  late void Function() customerInfoChanged;

  setUpAll(() => registerFallbackValue(standard));

  setUp(() {
    purchases = MockPurchasesService();
    repository = MockEntitlementsRepository();
    entitlements = EntitlementsViewModel(EntitlementsUsecase(repository));
    when(() => purchases.onCustomerInfoChanged(any())).thenAnswer((call) {
      customerInfoChanged = call.positionalArguments.first as void Function();
    });
    when(() => purchases.plans()).thenAnswer(
      (_) async => Offering('default', '', const {}, [standard, premium]),
    );
    when(() => purchases.trialEligibility(any())).thenAnswer(
      (_) async => {
        'decklingo_standard_monthly': true,
        'decklingo_premium_monthly': true,
      },
    );
    when(
      () => repository.refreshEntitlements(),
    ).thenAnswer((_) async => entitlementsOf('trial_premium'));
    vm = SubscriptionViewModel(purchases, entitlements);
  });

  test('prices and the trial come from the App Store', () async {
    await vm.load();

    expect(vm.priceOf(PlanOption.standard), r'$5.99');
    expect(vm.priceOf(PlanOption.premium), r'$9.99');
    expect(vm.trialDaysOf(PlanOption.premium), 14);
    expect(vm.trialAvailable(PlanOption.premium), isTrue);
    expect(vm.loadFailed, isFalse);
  });

  test('no trial for someone Apple says already had one', () async {
    when(() => purchases.trialEligibility(any())).thenAnswer(
      (_) async => {
        'decklingo_standard_monthly': false,
        'decklingo_premium_monthly': false,
      },
    );

    await vm.load();

    expect(vm.trialAvailable(PlanOption.premium), isFalse);
  });

  test('a missing package counts as a failed load', () async {
    when(
      () => purchases.plans(),
    ).thenAnswer((_) async => Offering('default', '', const {}, [standard]));

    await vm.load();

    expect(vm.loadFailed, isTrue);
    expect(vm.priceOf(PlanOption.premium), isNull);
  });

  test('a purchase refreshes the plan from the server', () async {
    await vm.load();
    when(() => purchases.buy(premium)).thenAnswer((_) async => true);

    expect(await vm.buy(PlanOption.premium), PurchaseOutcome.done);

    verify(() => repository.refreshEntitlements()).called(1);
    expect(entitlements.tier, AppTier.trialPremium);
  });

  test('closing the App Store sheet changes nothing', () async {
    await vm.load();
    when(() => purchases.buy(premium)).thenAnswer((_) async => false);

    expect(await vm.buy(PlanOption.premium), PurchaseOutcome.cancelled);

    verifyNever(() => repository.refreshEntitlements());
  });

  test('a failed purchase is reported', () async {
    await vm.load();
    when(() => purchases.buy(premium)).thenThrow(Exception('store error'));

    expect(await vm.buy(PlanOption.premium), PurchaseOutcome.failed);
    expect(vm.isBusy, isFalse);
  });

  test('restore says whether a subscription came back', () async {
    when(() => purchases.restore()).thenAnswer((_) async => false);
    expect(await vm.restore(), RestoreOutcome.nothing);

    when(() => purchases.restore()).thenAnswer((_) async => true);
    expect(await vm.restore(), RestoreOutcome.restored);
    verify(() => repository.refreshEntitlements()).called(2);
  });

  test('a renewal or expiry reported by RevenueCat reloads the plan', () async {
    customerInfoChanged();
    await Future<void>.delayed(Duration.zero);

    verify(() => repository.refreshEntitlements()).called(1);
  });
}
