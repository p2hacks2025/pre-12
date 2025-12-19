class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String email;
  final String displayName;
}

class AuthLoginResult {
  const AuthLoginResult({required this.user});

  final AuthUser user;
}
