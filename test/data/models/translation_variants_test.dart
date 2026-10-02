import 'package:flutter_test/flutter_test.dart';
import 'package:translate_app/data/models/favorite_word_model.dart';
import 'package:translate_app/data/models/history_model.dart';

void main() {
  final created = DateTime.utc(2026, 10, 2);

  test('history variants survive the cloud round trip', () {
    final item = HistoryItem()
      ..syncId = 's1'
      ..word = 'how are you'
      ..translation = 'nasılsın'
      ..translations = ['nasılsın', 'nasılsınız', 'naber']
      ..createdAt = created
      ..lastModified = created
      ..isGemini = true;

    final restored = HistoryItem.fromMap(item.toMap(), remoteId: 'r1');

    expect(restored.translations, ['nasılsın', 'nasılsınız', 'naber']);
    expect(restored.translation, 'nasılsın');
  });

  test('history saved by an older app version has no variants', () {
    final restored = HistoryItem.fromMap({
      'syncId': 's1',
      'word': 'hello',
      'translation': 'merhaba',
      'createdAt': created.toIso8601String(),
    });

    expect(restored.translations, isEmpty);
    expect(restored.translation, 'merhaba');
  });

  test('favorite variants survive the cloud round trip', () {
    final favorite = FavoriteWord()
      ..syncId = 'f1'
      ..word = 'thanks'
      ..translation = 'teşekkürler'
      ..translations = ['teşekkürler', 'teşekkür ederim', 'sağ ol']
      ..createdAt = created
      ..lastModified = created
      ..isGemini = true;

    final restored = FavoriteWord.fromMap(favorite.toMap());

    expect(restored.translations, ['teşekkürler', 'teşekkür ederim', 'sağ ol']);
  });
}
