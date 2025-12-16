import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReviewScreen extends StatefulWidget {
  final String artworkId;
  final String artworkImageUrl;
  final String artworkTitle;
  final String artistName;

  const ReviewScreen({
    super.key,
    required this.artworkId,
    required this.artworkImageUrl,
    required this.artworkTitle,
    required this.artistName,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  // ---- 設定 ----
  static const String reviewEndpoint =
      'https://example.com/api/reviews'; // TODO: 自分のAPIへ
  static const String userId = 'uuid'; // 本来は認証から取得
  static const int maxCommentLength = 500;
  // -------------

  final _formKey = GlobalKey<FormState>();
  final _commentCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  bool _canSubmit() {
    final comment = _commentCtrl.text.trim();
    return comment.isNotEmpty && comment.length <= maxCommentLength;
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canSubmit()) return;

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'user_id': userId,
        'artwork_id': widget.artworkId,
        'comment': _commentCtrl.text.trim(),
      };

      final res = await http.post(
        Uri.parse(reviewEndpoint),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer ...', // 必要なら
        },
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューを送信しました')),
        );
        // 送信後に前の画面に戻る
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('送信失敗: ${res.statusCode}\n${res.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('通信エラー: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('レビューを送る'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 作品情報カード
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 作品画像
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          widget.artworkImageUrl,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 250,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 64),
                              ),
                            );
                          },
                        ),
                      ),
                      // 作品タイトルとアーティスト名
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.artworkTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'by ${widget.artistName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // レビュー入力セクション
                const Text(
                  'レビューコメント',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _commentCtrl,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'この作品への感想やアドバイスを書いてください',
                    border: const OutlineInputBorder(),
                    counterText:
                        '${_commentCtrl.text.length}/$maxCommentLength',
                  ),
                  maxLines: 6,
                  maxLength: maxCommentLength,
                  onChanged: (_) => setState(() {}), // ボタンの状態更新のため
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'コメントを入力してください。';
                    }
                    if (v.length > maxCommentLength) {
                      return 'コメントは$maxCommentLength文字以内にしてください。';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // 送信ボタン
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : (_canSubmit() ? _submitReview : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit() && !_isSubmitting
                        ? Colors.blue
                        : null,
                    foregroundColor: _canSubmit() && !_isSubmitting
                        ? Colors.white
                        : null,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _canSubmit()
                              ? 'レビューを送信'
                              : 'コメントを入力してください',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
