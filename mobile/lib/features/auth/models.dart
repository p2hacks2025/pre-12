class DummyUser {
  const DummyUser({required this.id, required this.displayName});

  final String id;
  final String displayName;

  Map<String, dynamic> toJson() => {'id': id, 'displayName': displayName};
}

class DummyLoginResult {
  const DummyLoginResult({required this.user});

  final DummyUser user;
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
