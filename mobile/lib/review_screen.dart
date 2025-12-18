import 'package:flutter/material.dart';

// レビュー対象のデータモデル
class ReviewTarget {
  final String id;
  final String userName;
  final String artworkTitle;
  final String? artworkImageUrl;

  const ReviewTarget({
    required this.id,
    required this.userName,
    required this.artworkTitle,
    this.artworkImageUrl,
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
          // レビュー画面への遷移
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewExecutionScreen(
                artworkId: target.id,
                artworkImageUrl: target.artworkImageUrl ?? '',
                artworkTitle: target.artworkTitle,
                artistName: target.userName,
              ),
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

// レビュー実行画面
class ReviewExecutionScreen extends StatefulWidget {
  final String artworkId;
  final String artworkImageUrl;
  final String artworkTitle;
  final String artistName;

  const ReviewExecutionScreen({
    super.key,
    required this.artworkId,
    required this.artworkImageUrl,
    required this.artworkTitle,
    required this.artistName,
  });

  @override
  State<ReviewExecutionScreen> createState() => _ReviewExecutionScreenState();
}

class _ReviewExecutionScreenState extends State<ReviewExecutionScreen> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('レビューコメントを入力してください')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // TODO: APIでレビューを送信
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('レビューを送信しました')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('作品をレビュー'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 作品画像
              Container(
                height: 300,
                color: Colors.grey[200],
                child: widget.artworkImageUrl.isEmpty
                    ? Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image, size: 64),
                        ),
                      )
                    : Image.network(
                        widget.artworkImageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 64),
                            ),
                          );
                        },
                      ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 作品情報
                    Text(
                      widget.artworkTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            widget.artistName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.artistName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // レビューコメント入力
                    const Text(
                      'レビューコメント',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      maxLines: 8,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'この作品についてのフィードバックを入力してください...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 送信ボタン
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReview,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'レビューを送信',
                                style: TextStyle(fontSize: 16),
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
