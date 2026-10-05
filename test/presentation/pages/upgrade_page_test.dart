import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/domain/entities/entitlements_entity.dart';
import 'package:translate_app/presentation/pages/upgrade_page.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';

class MockEntitlementsViewModel extends ChangeNotifier
    with Mock
    implements EntitlementsViewModel {}

Widget subject(AppTier tier) {
  final vm = MockEntitlementsViewModel();
  when(() => vm.tier).thenReturn(tier);
  return ChangeNotifierProvider<EntitlementsViewModel>.value(
    value: vm,
    child: const MaterialApp(home: UpgradePage()),
  );
}

ElevatedButton cta(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byType(ElevatedButton));

void main() {
  testWidgets('Premium is preselected and offers the trial', (tester) async {
    await tester.pumpWidget(subject(AppTier.free));

    expect(find.text('Live translation'), findsOneWidget);
    expect(find.text('Start 14-day free trial'), findsOneWidget);
    expect(find.text(r'then $9.99/month · cancel anytime'), findsOneWidget);
    expect(cta(tester).onPressed, isNotNull);
  });

  testWidgets('choosing Standard shows its own list and price', (tester) async {
    await tester.pumpWidget(subject(AppTier.free));
    await tester.tap(find.text('Standard'));
    await tester.pumpAndSettle();

    expect(find.text('Live translation'), findsNothing);
    expect(find.text('Unlimited AI translations'), findsOneWidget);
    expect(find.text(r'then $5.99/month · cancel anytime'), findsOneWidget);
  });

  testWidgets('a Standard subscriber is offered an upgrade, not a trial', (
    tester,
  ) async {
    await tester.pumpWidget(subject(AppTier.standard));

    expect(find.text('Upgrade to Premium'), findsOneWidget);
    expect(find.text('How the free trial works'), findsNothing);
  });

  testWidgets('a Premium subscriber sees the current plan', (tester) async {
    await tester.pumpWidget(subject(AppTier.trialPremium));

    expect(find.text('Current plan'), findsOneWidget);
    expect(cta(tester).onPressed, isNull);

    await tester.tap(find.text('Standard'));
    await tester.pumpAndSettle();
    expect(find.text('Included in Premium'), findsOneWidget);
  });
}
