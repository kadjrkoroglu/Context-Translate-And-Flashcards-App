import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translate_app/data/services/settings_service.dart';
import 'package:translate_app/presentation/widgets/ai_consent_dialog.dart';

void main() {
  late SettingsService settings;
  late List<bool> results;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsService(await SharedPreferences.getInstance());
    results = [];
  });

  Widget subject() => Provider<SettingsService>.value(
    value: settings,
    child: MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(await ensureAiConsent(context)),
          child: const Text('use AI'),
        ),
      ),
    ),
  );

  testWidgets('asks once, names Google Gemini, then remembers', (tester) async {
    await tester.pumpWidget(subject());
    await tester.tap(find.text('use AI'));
    await tester.pumpAndSettle();

    expect(find.text('Before you use AI'), findsOneWidget);
    expect(find.textContaining('Google Gemini'), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(results, [true]);
    expect(settings.aiConsent, isTrue);

    await tester.tap(find.text('use AI'));
    await tester.pumpAndSettle();
    expect(find.text('Before you use AI'), findsNothing);
    expect(results, [true, true]);
  });

  testWidgets('"Not now" sends nothing and asks again next time', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.tap(find.text('use AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(results, [false]);
    expect(settings.aiConsent, isFalse);
  });
}
