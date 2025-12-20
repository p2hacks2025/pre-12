import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:p2hacks_onyx/config.dart';
import 'package:p2hacks_onyx/features/auth/auth_controller.dart';
import 'package:p2hacks_onyx/uri_helpers.dart';
import 'widgets/inline_error_banner.dart';

class MatchTarget {
  final String matchId;
  final String userId;
  final String username;
  final String iconUrl;
  final String workImageUrl;
  final String workTitle;
  final bool isReviewed;

  const MatchTarget({
    required this.matchId,
    required this.userId,
    required this.username,
    required this.iconUrl,
    required this.workImageUrl,
    required this.workTitle,
    required this.isReviewed,
  });

  factory MatchTarget.fromJson(Map<String, dynamic> json) {
    final matchId = json['match_id'] as String?;
    final userId = json['user_id'] as String?;
    if (matchId == null || matchId.isEmpty) {
      throw const FormatException('match_id is required');
    }
    if (userId == null || userId.isEmpty) {
      throw const FormatException('user_id is required');
    }
    return MatchTarget(
      matchId: matchId,
      userId: userId,
      username: json['username'] as String? ?? '',
      iconUrl: json['icon_url'] as String? ?? '',
      workImageUrl: json['work_image_url'] as String? ?? '',
      workTitle: json['work_title'] as String? ?? '',
      isReviewed: json['is_reviewed'] as bool? ?? false,
    );
  }
}

String _friendlyErrorMessage(Object error) {
  if (error is TimeoutException) {
    return '通信がタイムアウトしました。時間をおいて再試行してください。';
  }
  if (error is SocketException) {
    return 'ネットワークに接続できません。通信環境を確認してください。';
  }
  if (error is http.ClientException) {
    return 'ネットワークエラーが発生しました。';
  }
  if (error is FormatException) {
    return 'サーバーの応答形式が不正です。';
  }
  return '通信に失敗しました。時間をおいて再試行してください。';
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
      joinBasePath(base, '/matches')
          .replace(queryParameters: {'user_id': user.id});

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Failed to load matches: ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! List) {
        throw const FormatException('Invalid matches response');
      }

      final targets = <MatchTarget>[];
      for (final entry in decoded) {
        if (entry is! Map<String, dynamic>) {
          debugPrint('Skipping match entry: invalid type');
          continue;
        }
        try {
          targets.add(MatchTarget.fromJson(entry));
        } catch (e) {
          debugPrint('Skipping match entry: $e');
        }
      }

      targets.sort((a, b) {
        if (a.isReviewed == b.isReviewed) return 0;
        return a.isReviewed ? 1 : -1;
      });

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _targets = targets;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = _friendlyErrorMessage(e);
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
    final isEnabled = !target.isReviewed;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Opacity(
        opacity: isEnabled ? 1 : 0.6,
        child: InkWell(
          onTap: isEnabled
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewExecutionScreen(
                        matchId: target.matchId,
                        artworkImageUrl: target.workImageUrl,
                        artworkTitle: target.workTitle.isNotEmpty
                            ? target.workTitle
                            : '作品',
                        artistName: target.username,
                      ),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: _AvatarContent(
                    imageUrl: target.iconUrl,
                    fallbackText: target.username.isNotEmpty
                        ? target.username[0].toUpperCase()
                        : '?',
                  ),
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
                      const SizedBox(height: 6),
                      _ReviewStatusTag(isReviewed: target.isReviewed),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _WorkPreview(imageUrl: target.workImageUrl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewStatusTag extends StatelessWidget {
  const _ReviewStatusTag({required this.isReviewed});

  final bool isReviewed;

  @override
  Widget build(BuildContext context) {
    final label = isReviewed ? 'レビュー済み' : '未レビュー';
    final color = isReviewed ? Colors.grey : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
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

class _AvatarContent extends StatelessWidget {
  const _AvatarContent({
    required this.imageUrl,
    required this.fallbackText,
  });

  final String imageUrl;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _AvatarFallback(text: fallbackText);
    }

    return ClipOval(
      child: Image.network(
        imageUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _AvatarFallback(text: fallbackText);
        },
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
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
  String? _submitError;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      setState(() {
        _submitError = 'レビューコメントを入力してください。';
      });
      return;
    }

    if (backendBaseUrl.trim().isEmpty) {
      setState(() {
        _submitError = 'BACKEND_BASE_URL が未設定です。';
      });
      return;
    }

    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      setState(() {
        _submitError = '未ログインのため送信できません。';
      });
      return;
    }

    final Uri base;
    try {
      base = Uri.parse(backendBaseUrl);
    } catch (_) {
      setState(() {
        _submitError = 'BACKEND_BASE_URL が不正です。';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final res = await http
          .post(
            joinBasePath(base, '/review'),
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
      setState(() {
        _isSubmitting = false;
        _submitError = _friendlyErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitError = _submitError;
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
                    if (submitError != null) ...[
                      const SizedBox(height: 8),
                      InlineErrorBanner(message: submitError),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      maxLines: 8,
                      maxLength: 500,
                      onChanged: (_) {
                        if (_submitError != null) {
                          setState(() => _submitError = null);
                        }
                      },
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
