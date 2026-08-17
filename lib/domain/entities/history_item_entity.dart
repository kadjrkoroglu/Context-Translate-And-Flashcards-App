class HistoryItemEntity {
  final int id;
  final String syncId;
  final String word;
  final String translation;
  final DateTime createdAt;
  DateTime lastModified;

  String? userId;
  String? remoteId;
  bool isSynced = false;
  bool isDeleted = false;
  bool isGemini = false;

  HistoryItemEntity({
    required this.id,
    required this.syncId,
    required this.word,
    required this.translation,
    required this.createdAt,
    required this.lastModified,
    this.userId,
    this.remoteId,
    this.isSynced = false,
    this.isDeleted = false,
    this.isGemini = false,
  });
}
