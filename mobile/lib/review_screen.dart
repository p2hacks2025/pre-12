import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:p2hacks_onyx/config.dart';
import 'package:p2hacks_onyx/features/auth/auth_controller.dart';

class MatchTarget {
  final String matchId;
  final String userId;
  final String username;
  final String iconUrl;
  final String workImageUrl;

  const MatchTarget({
    required this.matchId,
    required this.userId,
    required this.username,
    required this.iconUrl,
    required this.workImageUrl,
  });

  factory MatchTarget.fromJson(Map<String, dynamic> json) {
    return MatchTarget(
      matchId: json['match_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      iconUrl: json['icon_url'] as String? ?? '',
      workImageUrl: json['work_image_url'] as String? ?? '',
    );
  }
}

class ReviewListScreen extends ConsumerStatefulWidget {
  const ReviewListScreen({super.key});

  @override
  ConsumerState<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends ConsumerState<ReviewListScreen> {
  bool _isLoading = false;
  String? _error;
  List<MatchTarget> _targets = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_fetchMatches);
  }

  Future<void> _fetchMatches() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (backendBaseUrl.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'BACKEND_BASE_URL が未設定です';
      });
      return;
    }

    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = '未ログインのためレビュー対象を取得できません';
      });
      return;
    }

    final Uri base;
    try {
      base = Uri.parse(backendBaseUrl);
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'BACKEND_BASE_URL が不正です: $backendBaseUrl';
      });
      return;
    }

    final uri =
        base.resolve('/matches').replace(queryParameters: {'user_id': user.id});

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Failed to load matches: ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! List) {
        throw Exception('Invalid matches response');
      }

      final targets = decoded
          .whereType<Map<String, dynamic>>()
          .map(MatchTarget.fromJson)
          .where((t) => t.matchId.isNotEmpty)
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _targets = targets;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _targets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _targets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchMatches,
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }

    if (_targets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'レビュー待ちの相手がいません',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _fetchMatches,
              icon: const Icon(Icons.refresh),
              label: const Text('更新'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMatches,
      child: ListView.builder(
        itemCount: _targets.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final target = _targets[index];
          return _ReviewTargetCard(target: target);
        },
      ),
    );
  }
}

class _ReviewTargetCard extends StatelessWidget {
  final MatchTarget target;

  const _ReviewTargetCard({required this.target});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewExecutionScreen(
                matchId: target.matchId,
                artworkImageUrl: target.workImageUrl,
                artworkTitle: '作品',
                artistName: target.username,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                backgroundImage: target.iconUrl.isNotEmpty
                    ? NetworkImage(target.iconUrl)
                    : null,
                child: target.iconUrl.isEmpty
                    ? Text(
                        target.username.isNotEmpty
                            ? target.username[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.username,
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
              const SizedBox(width: 12),
              _WorkPreview(imageUrl: target.workImageUrl),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkPreview extends StatelessWidget {
  const _WorkPreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 64,
        child: imageUrl.isEmpty
            ? Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  );
                },
              ),
      ),
    );
  }
}

// レビュー実行画面
class ReviewExecutionScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String artworkImageUrl;
  final String artworkTitle;
  final String artistName;

  const ReviewExecutionScreen({
    super.key,
    required this.matchId,
    required this.artworkImageUrl,
    required this.artworkTitle,
    required this.artistName,
  });

  @override
  ConsumerState<ReviewExecutionScreen> createState() =>
      _ReviewExecutionScreenState();
}

class _ReviewExecutionScreenState extends ConsumerState<ReviewExecutionScreen> {
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

    if (backendBaseUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BACKEND_BASE_URL が未設定です')),
      );
      return;
    }

    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未ログインのため送信できません')),
      );
      return;
    }

    final Uri base;
    try {
      base = Uri.parse(backendBaseUrl);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('BACKEND_BASE_URL が不正です: $backendBaseUrl')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final res = await http
          .post(
            base.resolve('/review'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(<String, dynamic>{
              'match_id': widget.matchId,
              'from_user_id': user.id,
              'comment': _commentController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('レビュー送信に失敗しました: ${res.statusCode}');
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('レビューを送信しました')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
                            widget.artistName.isNotEmpty
                                ? widget.artistName[0].toUpperCase()
                                : '?',
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
