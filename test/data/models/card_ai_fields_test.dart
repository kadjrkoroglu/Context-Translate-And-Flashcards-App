import 'package:flutter_test/flutter_test.dart';
import 'package:translate_app/data/models/card_model.dart';

void main() {
  CardItem item() => CardItem()
    ..syncId = 's1'
    ..word = 'umbrella'
    ..translation = 'şemsiye'
    ..createdAt = DateTime.utc(2026, 10, 1)
    ..lastModified = DateTime.utc(2026, 10, 2);

  test('Study with AI fields survive a sync round trip', () {
    final original = item()
      ..aiStudiedAt = DateTime.utc(2026, 10, 3, 9, 30)
      ..aiNeedsReview = true;

    final copy = CardItem.fromMap(original.toMap());

    expect(copy.aiStudiedAt, DateTime.utc(2026, 10, 3, 9, 30));
    expect(copy.aiNeedsReview, isTrue);
  });

  test('cards synced before the feature read as never studied', () {
    final map = item().toMap()
      ..remove('aiStudiedAt')
      ..remove('aiNeedsReview');

    final copy = CardItem.fromMap(map);

    expect(copy.aiStudiedAt, isNull);
    expect(copy.aiNeedsReview, isFalse);
  });
}
