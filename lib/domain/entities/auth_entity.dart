class AuthEntity {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;
  final bool isAnonymous;

  const AuthEntity({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.emailVerified,
    this.isAnonymous = false,
  });
}
