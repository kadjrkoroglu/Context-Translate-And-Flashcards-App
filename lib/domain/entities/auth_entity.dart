class AuthEntity {
  final String uid;
  final String? email;
  final String? displayName;
  final bool emailVerified;

  const AuthEntity({
    required this.uid,
    this.email,
    this.displayName,
    required this.emailVerified,
  });
}
