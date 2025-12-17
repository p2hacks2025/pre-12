import 'package:flutter/material.dart';

// レビュー対象のデータモデル
class ReviewTarget {
  final String id;
  final String userName;
  final String artworkTitle;

  const ReviewTarget({
    required this.id,
    required this.userName,
    required this.artworkTitle,
  });
}

class ReviewListScreen extends StatelessWidget {
  const ReviewListScreen({super.key});

  // ダミーデータ（実際にはAPIから取得）
  List<ReviewTarget> _getReviewTargets() {
    return [
      const ReviewTarget(id: '1', userName: '山田太郎', artworkTitle: '夕暮れの風景'),
      const ReviewTarget(id: '2', userName: '佐藤花子', artworkTitle: '抽象的な表現'),
      const ReviewTarget(id: '3', userName: '田中一郎', artworkTitle: '都会の夜'),
      const ReviewTarget(id: '4', userName: '鈴木美咲', artworkTitle: '自然の美しさ'),
      const ReviewTarget(id: '5', userName: '高橋健太', artworkTitle: 'ポートレート'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final reviewTargets = _getReviewTargets();

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('レビュー待ちリスト'),
      //   elevation: 0,
      // ),
      body: reviewTargets.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'レビュー待ちの作品はありません',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: reviewTargets.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final target = reviewTargets[index];
                return _ReviewTargetCard(target: target);
              },
            ),
    );
  }
}

class _ReviewTargetCard extends StatelessWidget {
  final ReviewTarget target;

  const _ReviewTargetCard({required this.target});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // レビュー画面への遷移（実装予定）
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${target.userName}の「${target.artworkTitle}」をレビュー'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      target.userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          target.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'レビュー待ち',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        target.artworkTitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
