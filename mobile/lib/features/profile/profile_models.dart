class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.iconUrl,
    required this.bio,
  });

  final String id;
  final String username;
  final String email;
  final String iconUrl;
  final String bio;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      iconUrl: (json['icon_url'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
    );
  }
}
