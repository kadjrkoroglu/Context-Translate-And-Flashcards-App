import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:math';

class DictionaryService {
  static final DictionaryService _instance = DictionaryService._internal();
  factory DictionaryService() => _instance;
  DictionaryService._internal();

  final Map<String, Set<String>> _loadedDictionaries = {};

  // Sözlük dosyalarının indirileceği temel URL (Örnek olarak yaygın bir GitHub kaynağı veya benzeri)
  // Not: Bu URL'ler gerçek ve stabil olmalıdır.
  final Map<String, String> _dictionaryUrls = {
    'tr':
        'https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/tr/tr_full.txt',
    'en':
        'https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/en/en_full.txt',
    'de':
        'https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/de/de_full.txt',
    'fr':
        'https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/fr/fr_full.txt',
    'es':
        'https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/es/es_full.txt',
  };

  Future<bool> isDictionaryDownloaded(String langCode) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/dict_$langCode.txt');
    return await file.exists();
  }

  Future<void> downloadDictionary(String langCode) async {
    if (!_dictionaryUrls.containsKey(langCode)) return;

    final url = _dictionaryUrls[langCode]!;
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/dict_$langCode.txt');

      // Sadece kelimeleri alıp (frekans sayılarını atarak) kaydediyoruz
      final lines = response.body.split('\n');
      final words = lines
          .map((line) => line.split(' ')[0].toLowerCase().trim())
          .where((w) => w.length > 1)
          .take(20000)
          .join('\n');

      await file.writeAsString(words);
    } else {
      throw Exception('Sözlük indirilemedi');
    }
  }

  Future<void> loadDictionary(String langCode) async {
    if (_loadedDictionaries.containsKey(langCode)) return;

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/dict_$langCode.txt');

    if (await file.exists()) {
      final content = await file.readAsString();
      _loadedDictionaries[langCode] = content.split('\n').toSet();
    }
  }

  String correctSentence(String sentence, String langCode) {
    if (!_loadedDictionaries.containsKey(langCode)) return sentence;

    final words = sentence.split(' ');
    final correctedWords = words.map((word) {
      return _correctWord(word.toLowerCase(), langCode);
    }).toList();

    return correctedWords.join(' ');
  }

  String _correctWord(String word, String langCode) {
    final dict = _loadedDictionaries[langCode]!;
    if (dict.contains(word) || word.length < 3) return word;

    String bestMatch = word;
    int minDistance = 3; // Maksimum 2 karakter farka kadar izin veriyoruz

    for (var dictWord in dict) {
      // Performans için sadece benzer uzunluktaki kelimelere bakıyoruz
      if ((dictWord.length - word.length).abs() > 2) continue;

      int distance = _levenshtein(word, dictWord);
      if (distance < minDistance) {
        minDistance = distance;
        bestMatch = dictWord;
      }
      if (minDistance == 1) break; // 1 fark bulduysak yeterli
    }

    return bestMatch;
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }
}
