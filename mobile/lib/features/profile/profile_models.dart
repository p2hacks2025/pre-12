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

class MyWork {
  const MyWork({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final DateTime createdAt;

  factory MyWork.fromJson(Map<String, dynamic> json) {
    return MyWork(
      id: (json['id'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
