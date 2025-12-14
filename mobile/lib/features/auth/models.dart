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
