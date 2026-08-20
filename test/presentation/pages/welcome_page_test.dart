import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/data/services/settings_service.dart';
import 'package:translate_app/presentation/pages/welcome_page.dart';

class MockSettingsService extends Mock implements SettingsService {}

void main() {
  late MockSettingsService mockSettings;

  setUp(() {
    mockSettings = MockSettingsService();
    when(() => mockSettings.setFirstRunComplete())
        .thenAnswer((_) async {});
  });

  Widget buildSubject() {
    return Provider<SettingsService>.value(
      value: mockSettings,
      child: const MaterialApp(home: WelcomePage()),
    );
  }

  testWidgets('renders welcome page', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.byType(WelcomePage), findsOneWidget);
  });

  testWidgets('displays title text', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text("Don't waste time, add and study!"), findsOneWidget);
  });

  testWidgets('displays subtitle text', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(
      find.text(
        'Translate and create flashcards quickly. Master new languages with smart spaced-repetition.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('displays Get Started button', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('displays Sign in and Sync button', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('Sign in and Sync'), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });

  testWidgets('displays translate icon', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
  });

  testWidgets('displays flashcards icon', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.byIcon(Icons.style_rounded), findsOneWidget);
  });
}
