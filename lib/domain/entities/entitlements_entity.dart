enum AppTier { free, standard, premium }

AppTier tierFromString(String value) {
  return AppTier.values.firstWhere(
    (t) => t.name == value,
    orElse: () => AppTier.free,
  );
}

class TierEntitlements {
  final int? maxDecks;
  final int? maxCardsPerDeck;
  final bool photo;
  final bool live;
  final bool chat;

  const TierEntitlements({
    required this.maxDecks,
    required this.maxCardsPerDeck,
    required this.photo,
    required this.live,
    required this.chat,
  });

  bool get hasUnlimitedDecks => maxDecks == null;
  bool get hasUnlimitedCardsPerDeck => maxCardsPerDeck == null;

  factory TierEntitlements.fromJson(Map<String, dynamic> json) {
    return TierEntitlements(
      maxDecks: json['maxDecks'] as int?,
      maxCardsPerDeck: json['maxCardsPerDeck'] as int?,
      photo: json['photo'] as bool? ?? false,
      live: json['live'] as bool? ?? false,
      chat: json['chat'] as bool? ?? false,
    );
  }
}

/// Translate quota status: either a fixed window (free tier, e.g. "10/day")
/// or a token bucket (standard/premium, continuous refill).
class TranslateQuotaStatus {
  final bool isWindow;
  final int? limit;
  final int? used;
  final int? remaining;
  final DateTime? resetsAt;
  final int? bucketCapacity;
  final int? bucketTokens;

  const TranslateQuotaStatus._({
    required this.isWindow,
    this.limit,
    this.used,
    this.remaining,
    this.resetsAt,
    this.bucketCapacity,
    this.bucketTokens,
  });

  factory TranslateQuotaStatus.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == 'bucket') {
      return TranslateQuotaStatus._(
        isWindow: false,
        bucketCapacity: json['capacity'] as int?,
        bucketTokens: json['tokens'] as int?,
      );
    }
    if (type == 'window') {
      final windows = json['windows'] as List<dynamic>? ?? [];
      final window = windows.isNotEmpty ? windows.first as Map<String, dynamic> : null;
      return TranslateQuotaStatus._(
        isWindow: true,
        limit: window?['limit'] as int?,
        used: window?['used'] as int?,
        remaining: window?['remaining'] as int?,
        resetsAt: window?['resetsAt'] != null ? DateTime.tryParse(window!['resetsAt'] as String) : null,
      );
    }
    return const TranslateQuotaStatus._(isWindow: true);
  }
}

class EntitlementsEntity {
  final AppTier tier;
  final TierEntitlements entitlements;
  final TranslateQuotaStatus translateQuota;

  const EntitlementsEntity({
    required this.tier,
    required this.entitlements,
    required this.translateQuota,
  });

  factory EntitlementsEntity.fromJson(Map<String, dynamic> json) {
    return EntitlementsEntity(
      tier: tierFromString(json['tier'] as String? ?? 'free'),
      entitlements: TierEntitlements.fromJson(
        json['entitlements'] as Map<String, dynamic>? ?? const {},
      ),
      translateQuota: TranslateQuotaStatus.fromJson(
        json['translate'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
