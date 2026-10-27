import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:translate_app/data/services/purchases_service.dart';
import 'package:translate_app/domain/entities/entitlements_entity.dart';
import 'package:translate_app/l10n/l10n.dart';
import 'package:translate_app/presentation/pages/upgrade_page.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/subscription_viewmodel.dart';

class MockEntitlementsViewModel extends ChangeNotifier
    with Mock
    implements EntitlementsViewModel {}

class MockPurchasesService extends Mock implements PurchasesService {}

Package package(String id, String price) => Package(
  '${id}_monthly',
  PackageType.monthly,
  StoreProduct(
    'decklingo_${id}_monthly',
    '',
    '',
    0,
    price,
    'USD',
    introductoryPrice: const IntroductoryPrice(
      0,
      r'$0.00',
      'P2W',
      1,
      PeriodUnit.week,
      2,
    ),
  ),
  const PresentedOfferingContext('default', null, null),
);

Widget subject(AppTier tier, {EntitlementsEntity? entitlements}) {
  final vm = MockEntitlementsViewModel();
  when(() => vm.tier).thenReturn(tier);
  when(() => vm.entitlements).thenReturn(entitlements);
  final purchases = MockPurchasesService();
  when(() => purchases.onCustomerInfoChanged(any())).thenReturn(null);
  when(() => purchases.plans()).thenAnswer(
    (_) async => Offering('default', '', const {}, [
      package('standard', r'$5.99'),
      package('premium', r'$9.99'),
    ]),
  );
  when(() => purchases.trialEligibility(any())).thenAnswer((_) async => {});
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<EntitlementsViewModel>.value(value: vm),
      ChangeNotifierProvider(
        create: (_) => SubscriptionViewModel(purchases, vm),
      ),
    ],
    // As in the app: its delegates also load the date formats.
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: UpgradePage(),
    ),
  );
}

Future<void> open(
  WidgetTester tester,
  AppTier tier, {
  EntitlementsEntity? entitlements,
}) async {
  await tester.pumpWidget(subject(tier, entitlements: entitlements));
  // The App Store plans load after the first frame.
  await tester.pumpAndSettle();
}

ElevatedButton cta(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byType(ElevatedButton));

void main() {
  testWidgets('Premium offers the trial', (tester) async {
    await open(tester, AppTier.free);
    await tester.tap(find.text('Premium'));
    await tester.pumpAndSettle();

    expect(find.text('AI Live translation'), findsOneWidget);
    expect(find.text('Start 14-day free trial'), findsOneWidget);
    expect(find.text(r'then $9.99/month · cancel anytime'), findsOneWidget);
    expect(cta(tester).onPressed, isNotNull);
  });

  testWidgets('Standard is recommended and preselected, with its own list', (
    tester,
  ) async {
    await open(tester, AppTier.free);

    expect(find.text('Recommended'), findsOneWidget);
    expect(find.text('AI Live translation'), findsNothing);
    expect(find.text('Unlimited AI translations'), findsOneWidget);
    expect(find.text(r'then $5.99/month · cancel anytime'), findsOneWidget);
  });

  testWidgets('a Standard subscriber is offered an upgrade, not a trial', (
    tester,
  ) async {
    await open(tester, AppTier.standard);
    await tester.tap(find.text('Premium'));
    await tester.pumpAndSettle();

    expect(find.text('Upgrade to Premium'), findsOneWidget);
    expect(find.text('How the free trial works'), findsNothing);
  });

  testWidgets('a Premium subscriber sees the current plan', (tester) async {
    await open(tester, AppTier.trialPremium);

    expect(find.text('Current plan'), findsOneWidget);
    expect(cta(tester).onPressed, isNull);

    await tester.tap(find.text('Standard'));
    await tester.pumpAndSettle();
    expect(find.text('Switch to Standard'), findsOneWidget);
    expect(
      find.text(r'$5.99/month · starts when your current period ends'),
      findsOneWidget,
    );
    expect(cta(tester).onPressed, isNotNull);
  });

  testWidgets('a switch to Standard already asked for is shown, not offered', (
    tester,
  ) async {
    await open(
      tester,
      AppTier.premium,
      entitlements: EntitlementsEntity.fromJson({
        'tier': 'premium',
        'entitlements': <String, dynamic>{},
        'pendingSwitch': {'plan': 'standard', 'at': '2099-11-27T12:00:00Z'},
      }),
    );
    await tester.tap(find.text('Standard'));
    await tester.pumpAndSettle();

    expect(find.text('Switch to Standard planned'), findsOneWidget);
    expect(find.text('Starts on November 27, 2099'), findsOneWidget);
    expect(cta(tester).onPressed, isNull);
  });
}
