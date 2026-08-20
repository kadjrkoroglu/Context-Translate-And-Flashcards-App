import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/presentation/pages/favorites_page.dart';
import 'package:translate_app/presentation/viewmodels/favorite_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/main_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/ml_translate_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';
import 'package:translate_app/theme/theme.dart';

class MockFavoriteViewModel extends ChangeNotifier
    with Mock
    implements FavoriteViewModel {}

class MockMainViewModel extends ChangeNotifier
    with Mock
    implements MainViewModel {}

class MockMLTranslateViewModel extends ChangeNotifier
    with Mock
    implements MLTranslateViewModel {}

class MockGeminiTranslateViewModel extends ChangeNotifier
    with Mock
    implements GeminiTranslateViewModel {}

class FakeTextEditingController extends Fake implements TextEditingController {}

void main() {
  late MockFavoriteViewModel mockFavoriteVM;
  late MockMainViewModel mockMainVM;
  late MockMLTranslateViewModel mockMlVM;
  late MockGeminiTranslateViewModel mockGeminiVM;

  setUpAll(() {
    registerFallbackValue(FakeTextEditingController());
  });

  setUp(() {
    mockFavoriteVM = MockFavoriteViewModel();
    mockMainVM = MockMainViewModel();
    mockMlVM = MockMLTranslateViewModel();
    mockGeminiVM = MockGeminiTranslateViewModel();

    when(() => mockFavoriteVM.isLoading).thenReturn(false);
    when(() => mockFavoriteVM.errorMessage).thenReturn(null);
    when(() => mockFavoriteVM.favorites).thenReturn([]);
    when(() => mockFavoriteVM.loadFavorites()).thenAnswer((_) async {});
    when(() => mockMainVM.outputController).thenReturn(FakeTextEditingController());
    when(() => mockMlVM.textController).thenReturn(FakeTextEditingController());
    when(() => mockGeminiVM.textController).thenReturn(FakeTextEditingController());
  });

  Widget buildSubject() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FavoriteViewModel>.value(
          value: mockFavoriteVM,
        ),
        ChangeNotifierProvider<MainViewModel>.value(value: mockMainVM),
        ChangeNotifierProvider<MLTranslateViewModel>.value(value: mockMlVM),
        ChangeNotifierProvider<GeminiTranslateViewModel>.value(
          value: mockGeminiVM,
        ),
      ],
      child: MaterialApp(
        theme: lightTheme,
        home: const FavoritesPage(),
      ),
    );
  }

  testWidgets('renders favorites page', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.byType(FavoritesPage), findsOneWidget);
  });

  testWidgets('displays Favorites title', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('Favorites'), findsOneWidget);
  });

  testWidgets('shows empty state when no favorites', (tester) async {
    when(() => mockFavoriteVM.favorites).thenReturn([]);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('No favorites yet'), findsOneWidget);
  });

  testWidgets('shows empty state icon', (tester) async {
    when(() => mockFavoriteVM.favorites).thenReturn([]);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.byIcon(Icons.favorite_outline_rounded), findsOneWidget);
  });

  testWidgets('calls loadFavorites on init', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    verify(() => mockFavoriteVM.loadFavorites()).called(1);
  });

  testWidgets('shows loading indicator when loading', (tester) async {
    when(() => mockFavoriteVM.isLoading).thenReturn(true);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message when error occurs', (tester) async {
    when(() => mockFavoriteVM.errorMessage).thenReturn('Something went wrong');

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Something went wrong'), findsOneWidget);
  });
}
