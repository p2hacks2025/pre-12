import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:p2hacks_onyx/features/auth/auth_controller.dart';
import 'package:p2hacks_onyx/config.dart';

// フロントのみでUIを確認したい場合は true にする
const bool _useMockReceivedReviews = false;

// 受信レビューのデータモデル
class ReceivedReview {
  final String id;
  final String matchId;
  final String userId;
  final String userName;
  final String iconUrl;
  final String comment;
  final String? workId;
  final String? workTitle;
  final String workImageUrl;
  final DateTime createdAt;

  ReceivedReview({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.userName,
    required this.iconUrl,
    required this.comment,
    this.workId,
    this.workTitle,
    required this.workImageUrl,
    required this.createdAt,
  });

  factory ReceivedReview.fromJson(Map<String, dynamic> json) {
    return ReceivedReview(
      id: json['review_id'] as String? ?? json['id'] as String? ?? '',
      matchId: json['match_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userName: json['username'] as String? ?? json['user_name'] as String? ?? 'Unknown User',
      iconUrl: json['icon_url'] as String? ?? '',
      comment: json['comment'] as String,
      workId: json['work_id'] as String?,
      workTitle: json['work_title'] as String?,
      workImageUrl: json['work_image_url'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// UI確認用のモックデータ
final List<ReceivedReview> _mockReceivedReviews = <ReceivedReview>[
  ReceivedReview(
    id: '1',
    matchId: 'match-1',
    userId: 'user1',
    userName: '田中太郎',
    iconUrl: '',
    comment: 'とても素晴らしい作品でした！色使いが綺麗で、見ていて心が和みます。',
    workId: 'work1',
    workTitle: '夕焼けの風景画',
    workImageUrl: '',
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
  ),
  ReceivedReview(
    id: '2',
    matchId: 'match-2',
    userId: 'user2',
    userName: '佐藤花子',
    iconUrl: '',
    comment: '構図がとても良いですね。プロの作品かと思いました！',
    workId: 'work2',
    workTitle: '都会の夜景',
    workImageUrl: '',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  ReceivedReview(
    id: '3',
    matchId: 'match-3',
    userId: 'user3',
    userName: '山田次郎',
    iconUrl: '',
    comment: '感動しました。これからも頑張ってください！応援しています。',
    workId: null,
    workTitle: null,
    workImageUrl: '',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  ReceivedReview(
    id: '4',
    matchId: 'match-4',
    userId: 'user4',
    userName: 'Mike Johnson',
    iconUrl: '',
    comment: 'Amazing work! I love the attention to detail.',
    workId: 'work3',
    workTitle: '春の桜',
    workImageUrl: '',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  ReceivedReview(
    id: '5',
    matchId: 'match-5',
    userId: 'user5',
    userName: '鈴木一郎',
    iconUrl: '',
    comment: '独創的なアイデアですね。',
    workId: 'work4',
    workTitle: '抽象画アート',
    workImageUrl: '',
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
  ),
];

// 受信レビューのリストを管理するプロバイダー
final receivedReviewsProvider = StateProvider<AsyncValue<List<ReceivedReview>>>(
  (ref) {
    return const AsyncValue.loading();
  },
);

// レビューサービスのプロバイダー
final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(ref);
});

class ReviewService {
  final Ref ref;

  ReviewService(this.ref);

  // 受信レビューを取得
  Future<void> fetchReceivedReviews() async {
    ref.read(receivedReviewsProvider.notifier).state =
        const AsyncValue.loading();

    // モックデータでUI確認
    if (_useMockReceivedReviews) {
      await Future.delayed(const Duration(milliseconds: 400));
      ref.read(receivedReviewsProvider.notifier).state = AsyncValue.data(
        _mockReceivedReviews,
      );
      return;
    }

    if (backendBaseUrl.trim().isEmpty) {
      ref.read(receivedReviewsProvider.notifier).state = AsyncValue.error(
        Exception('BACKEND_BASE_URL が未設定です'),
        StackTrace.current,
      );
      return;
    }

    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      ref.read(receivedReviewsProvider.notifier).state = AsyncValue.error(
        Exception('未ログインのためレビューを取得できません'),
        StackTrace.current,
      );
      return;
    }

    final Uri base;
    try {
      base = Uri.parse(backendBaseUrl);
    } catch (_) {
      ref.read(receivedReviewsProvider.notifier).state = AsyncValue.error(
        Exception('BACKEND_BASE_URL が不正です: $backendBaseUrl'),
        StackTrace.current,
      );
      return;
    }

    final uri = base
        .resolve('/reviews')
        .replace(queryParameters: <String, String>{'user_id': user.id});

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // TODO: 認証トークンを追加
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final reviews = data
            .map((json) => ReceivedReview.fromJson(json))
            .toList();

        ref.read(receivedReviewsProvider.notifier).state = AsyncValue.data(
          reviews,
        );
      } else {
        throw Exception(
          'Failed to load received reviews: ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      ref.read(receivedReviewsProvider.notifier).state = AsyncValue.error(
        e,
        stack,
      );
    }
  }
}
