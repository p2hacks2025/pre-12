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

class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email,
    'password': password,
  };
}

class LoginResult {
  const LoginResult({required this.userId});

  final String userId;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id'];
    if (userId is! String || userId.isEmpty) {
      throw Exception('login 応答に user_id がありません');
    }
    return LoginResult(userId: userId);
  }
}

class SignUpRequest {
  const SignUpRequest({
    required this.username,
    required this.email,
    required this.password,
  });

  final String username;
  final String email;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'username': username,
    'email': email,
    'password': password,
  };
}

class SignUpResult {
  const SignUpResult({required this.userId});

  final String userId;

  factory SignUpResult.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id'];
    if (userId is! String || userId.isEmpty) {
      throw Exception('sign-up 応答に user_id がありません');
    }
    return SignUpResult(userId: userId);
  }
}
