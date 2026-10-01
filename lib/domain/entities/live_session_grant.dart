/// Token, setup message and granted time for one Live slice.
class LiveSessionGrant {
  final String sessionId;
  final String token;
  final Map<String, dynamic> setup;
  final int grantedSeconds;

  /// Seconds left this month after this grant.
  final int remainingSeconds;

  const LiveSessionGrant({
    required this.sessionId,
    required this.token,
    required this.setup,
    required this.grantedSeconds,
    required this.remainingSeconds,
  });

  factory LiveSessionGrant.fromJson(Map<String, dynamic> json) {
    return LiveSessionGrant(
      sessionId: json['sessionId'] as String,
      token: json['token'] as String,
      setup: Map<String, dynamic>.from(json['setup'] as Map),
      grantedSeconds: json['grantedSeconds'] as int,
      remainingSeconds: json['remainingSeconds'] as int? ?? 0,
    );
  }
}
