import 'package:isar/isar.dart';

part 'history_model.g.dart';

@collection
class HistoryItem {
  Id id = Isar.autoIncrement;

  @Index()
  late String syncId;

  late String word;
  late String translation;

  /// Gemini's Standard/Formal/Slang variants; empty for older items.
  List<String> translations = [];
  late DateTime createdAt;
  late DateTime lastModified;

  String? userId;
  String? remoteId;
  bool isSynced = false;
  bool isDeleted = false;
  bool isGemini = false;

  Map<String, dynamic> toMap() {
    return {
      'syncId': syncId,
      'word': word,
      'translation': translation,
      'translations': translations,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'userId': userId,
      'isDeleted': isDeleted,
      'isGemini': isGemini,
    };
  }

  static HistoryItem fromMap(Map<String, dynamic> map, {String? remoteId}) {
    return HistoryItem()
      ..syncId = map['syncId'] ?? remoteId ?? ''
      ..word = map['word'] ?? ''
      ..translation = map['translation'] ?? ''
      ..translations = List<String>.from(map['translations'] ?? const [])
      ..createdAt = DateTime.parse(map['createdAt'])
      ..lastModified = map['lastModified'] != null
          ? DateTime.parse(map['lastModified'])
          : DateTime.parse(map['createdAt'])
      ..userId = map['userId']
      ..remoteId = remoteId
      ..isSynced = true
      ..isDeleted = map['isDeleted'] ?? false
      ..isGemini = map['isGemini'] ?? false;
  }
}
