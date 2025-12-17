import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// フロントのみでUIを確認したい場合は true にする
const bool _useMockAcceptedReviews = true;

// 承認済みレビューのデータモデル
class AcceptedReview {
  final String id;
  final String userId;
  final String userName;
  final String comment;
  final String? workId;
  final String? workTitle;
  final DateTime createdAt;
  final bool isAccepted;

  AcceptedReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.comment,
    this.workId,
    this.workTitle,
    required this.createdAt,
    required this.isAccepted,
  });

  factory AcceptedReview.fromJson(Map<String, dynamic> json) {
    return AcceptedReview(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Unknown User',
      comment: json['comment'] as String,
      workId: json['work_id'] as String?,
      workTitle: json['work_title'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isAccepted: json['is_accepted'] as bool? ?? false,
    );
  }
}

// UI確認用のモックデータ
final List<AcceptedReview> _mockAcceptedReviews = <AcceptedReview>[
  AcceptedReview(
    id: '1',
    userId: 'user1',
    userName: '田中太郎',
    comment: 'とても素晴らしい作品でした！色使いが綺麗で、見ていて心が和みます。',
    workId: 'work1',
    workTitle: '夕焼けの風景画',
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    isAccepted: true,
  ),
  AcceptedReview(
    id: '2',
    userId: 'user2',
    userName: '佐藤花子',
    comment: '構図がとても良いですね。プロの作品かと思いました！',
    workId: 'work2',
    workTitle: '都会の夜景',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    isAccepted: true,
  ),
  AcceptedReview(
    id: '3',
    userId: 'user3',
    userName: '山田次郎',
    comment: '感動しました。これからも頑張ってください！応援しています。',
    workId: null,
    workTitle: null,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    isAccepted: true,
  ),
  AcceptedReview(
    id: '4',
    userId: 'user4',
    userName: 'Mike Johnson',
    comment: 'Amazing work! I love the attention to detail.',
    workId: 'work3',
    workTitle: '春の桜',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    isAccepted: true,
  ),
  AcceptedReview(
    id: '5',
    userId: 'user5',
    userName: '鈴木一郎',
    comment: '独創的なアイデアですね。',
    workId: 'work4',
    workTitle: '抽象画アート',
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    isAccepted: true,
  ),
];

// 承認済みレビューのリストを管理するプロバイダー
final acceptedReviewsProvider = StateProvider<AsyncValue<List<AcceptedReview>>>(
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

  // 承認済みレビューを取得
  Future<void> fetchAcceptedReviews() async {
    ref.read(acceptedReviewsProvider.notifier).state =
        const AsyncValue.loading();

    // モックデータでUI確認
    if (_useMockAcceptedReviews) {
      await Future.delayed(const Duration(milliseconds: 400));
      ref.read(acceptedReviewsProvider.notifier).state = AsyncValue.data(
        _mockAcceptedReviews,
      );
      return;
    }

    try {
      // TODO: 実際のAPIエンドポイントに置き換える
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/reviews/accepted'),
        headers: {
          'Content-Type': 'application/json',
          // TODO: 認証トークンを追加
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final reviews = data
            .map((json) => AcceptedReview.fromJson(json))
            .toList();

        ref.read(acceptedReviewsProvider.notifier).state = AsyncValue.data(
          reviews,
        );
      } else {
        throw Exception(
          'Failed to load accepted reviews: ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      ref.read(acceptedReviewsProvider.notifier).state = AsyncValue.error(
        e,
        stack,
      );
    }
  }

  // レビューを承認する
  Future<bool> acceptReview(String reviewId) async {
    // モック時は即成功にしてリストをリフレッシュ
    if (_useMockAcceptedReviews) {
      await Future.delayed(const Duration(milliseconds: 200));
      await fetchAcceptedReviews();
      return true;
    }

    try {
      // TODO: 実際のAPIエンドポイントに置き換える
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/reviews/$reviewId/accept'),
        headers: {
          'Content-Type': 'application/json',
          // TODO: 認証トークンを追加
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // 承認後、リストを再取得
        await fetchAcceptedReviews();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
