class FavoriteWordEntity {
  final int id;
  final String syncId;
  final String word;
  final String translation;
  final List<String> translations;
  final DateTime createdAt;
  DateTime lastModified;

  String? userId;
  String? remoteId;
  bool isSynced = false;
  bool isDeleted = false;
  bool isGemini = false;

  FavoriteWordEntity({
    required this.id,
    required this.syncId,
    required this.word,
    required this.translation,
    this.translations = const [],
    required this.createdAt,
    required this.lastModified,
    this.userId,
    this.remoteId,
    this.isSynced = false,
    this.isDeleted = false,
    this.isGemini = false,
  });
}
