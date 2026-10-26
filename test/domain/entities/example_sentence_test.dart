import 'package:flutter_test/flutter_test.dart';
import 'package:translate_app/domain/entities/card_entity.dart';
import 'package:translate_app/domain/entities/example_sentence.dart';

void main() {
  test('up to five words get examples, longer text does not', () {
    expect(fitsExamples('Bahnhof'), isTrue);
    expect(fitsExamples('I look forward to it'), isTrue);
    expect(fitsExamples('I really look forward to it'), isFalse);
    expect(fitsExamples('  '), isFalse);
  });

  test('Chinese and Japanese count characters, having no spaces', () {
    expect(fitsExamples('駅'), isTrue);
    expect(fitsExamples('次の駅で降りますか'), isTrue);
    expect(fitsExamples('次の駅で電車を降りてください'), isFalse);
  });

  test('a card has examples only when both sides were saved', () {
    final now = DateTime(2026, 10, 26);
    final card = CardEntity(
      id: 1,
      syncId: 'c1',
      word: 'Bahnhof',
      translation: 'Tren istasyonu',
      createdAt: now,
      lastModified: now,
    );
    expect(card.examples, isNull);

    card
      ..exampleSentences = ['Wo ist der [[Bahnhof]]?']
      ..exampleTranslations = ['[[Tren istasyonu]] nerede?'];
    expect(card.examples!.single.translation, '[[Tren istasyonu]] nerede?');
  });
}
