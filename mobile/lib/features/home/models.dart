class Work {
  const Work({
    required this.id,
    required this.userId,
    required this.username,
    required this.iconUrl,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String username;
  final String iconUrl;
  final String imageUrl;
  final String title;
  final String description;
  final DateTime createdAt;

  factory Work.fromJson(Map<String, dynamic> json) {
    return Work(
      id: (json['id'] as String?) ?? '',
      userId: (json['user_id'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
      iconUrl: (json['icon_url'] as String?) ?? '',
      imageUrl: (json['image_url'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// POST /swipes に送るリクエスト（ホーム画面のスワイプ送信）
class SwipeRequest {
  const SwipeRequest({
    required this.fromUserId,
    required this.toWorkId,
    required this.isLike,
  });

  final String fromUserId;
  final String toWorkId;
  final bool isLike;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'from_user_id': fromUserId,
    'to_work_id': toWorkId,
    'is_like': isLike,
  };
}

/// POST /swipes のレスポンス（現状は message のみ想定）
class SwipeResponse {
  const SwipeResponse({required this.message});

  final String message;

  factory SwipeResponse.fromJson(Map<String, dynamic> json) {
    return SwipeResponse(message: (json['message'] as String?) ?? '');
  }
}
