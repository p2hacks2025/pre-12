import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config.dart';
import 'models.dart';

class WorksService {
  const WorksService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<List<Work>> getWorks({required String userId}) async {
    if (backendBaseUrl.trim().isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return _dummyWorks;
    }

    final Uri base;
    try {
      base = Uri.parse(backendBaseUrl);
    } catch (_) {
      throw Exception('BACKEND_BASE_URL が不正です: $backendBaseUrl');
    }

    final uri = base
        .resolve('/works')
        .replace(queryParameters: <String, String>{'user_id': userId});

    final client = _client ?? http.Client();
    try {
      final res = await client.get(uri).timeout(const Duration(seconds: 8));

      // フロント単体で確認できるよう、APIが無い/落ちている場合はダミーにフォールバック
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return _dummyWorks;
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! List) {
        return _dummyWorks;
      }

      final works = decoded
          .whereType<Map<String, dynamic>>()
          .map(Work.fromJson)
          .where((w) => w.id.isNotEmpty)
          .toList(growable: false);

      return works.isEmpty ? _dummyWorks : works;
    } catch (_) {
      return _dummyWorks;
    } finally {
      if (_client == null) client.close();
    }
  }

  Future<void> postSwipe({
    required String fromUserId,
    required String toWorkId,
    required bool isLike,
  }) async {
    await postSwipeRequest(
      SwipeRequest(fromUserId: fromUserId, toWorkId: toWorkId, isLike: isLike),
    );
  }

  Future<SwipeResponse?> postSwipeRequest(SwipeRequest request) async {
    if (backendBaseUrl.trim().isEmpty) {
      return null;
    }

    final Uri base;
    try {
      base = Uri.parse(backendBaseUrl);
    } catch (_) {
      throw Exception('BACKEND_BASE_URL が不正です: $backendBaseUrl');
    }

    final client = _client ?? http.Client();
    try {
      // 仕様は /swipes だが、現状のbackendは /swipe のため両対応にしておく。
      final primary = base.resolve('/swipes');
      final fallback = base.resolve('/swipe');

      final res = await _postJson(client, primary, request.toJson());
      final ok = res.statusCode >= 200 && res.statusCode < 300;
      final shouldFallback = res.statusCode == 404 || res.statusCode == 405;

      final finalRes = ok || !shouldFallback
          ? res
          : await _postJson(client, fallback, request.toJson());

      if (finalRes.statusCode < 200 || finalRes.statusCode >= 300) {
        throw Exception('スワイプ送信に失敗: ${finalRes.statusCode} ${finalRes.body}');
      }

      try {
        final decoded = jsonDecode(finalRes.body);
        if (decoded is Map<String, dynamic>) {
          return SwipeResponse.fromJson(decoded);
        }
      } catch (_) {
        // レスポンスJSONが無い場合も許容
      }

      return const SwipeResponse(message: '');
    } finally {
      if (_client == null) client.close();
    }
  }
}

Future<http.Response> _postJson(
  http.Client client,
  Uri uri,
  Map<String, dynamic> json,
) {
  return client
      .post(
        uri,
        headers: const {'content-type': 'application/json'},
        body: jsonEncode(json),
      )
      .timeout(const Duration(seconds: 8));
}

final List<Work> _dummyWorks = <Work>[
  Work(
    id: 'dummy-1',
    userId: 'alice',
    username: 'Alice',
    iconUrl: '',
    imageUrl: 'assets/works/work_01.jpg',
    title: 'ダミー作品 1',
    description: '画像は assets/works に置いたものを表示します。',
    createdAt: _epoch,
  ),
  Work(
    id: 'dummy-2',
    userId: 'bob',
    username: 'Bob',
    iconUrl: '',
    imageUrl: 'assets/works/work_02.jpg',
    title: 'ダミー作品 2',
    description: '右スワイプ=いいね（レビューしたい） / 左スワイプ=スキップ',
    createdAt: _epoch,
  ),
  Work(
    id: 'dummy-3',
    userId: 'charlie',
    username: 'Charlie',
    iconUrl: '',
    imageUrl: 'assets/works/work_03.jpg',
    title: 'ダミー作品 3',
    description: '♡ボタンでも「いいね」できます。',
    createdAt: _epoch,
  ),
  Work(
    id: 'dummy-4',
    userId: 'diana',
    username: 'Diana',
    iconUrl: '',
    imageUrl: 'assets/works/work_04.jpg',
    title: 'ダミー作品 4',
    description: '画像が見えない場合はパスとpubspec.yamlを確認してください。',
    createdAt: _epoch,
  ),
];

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);
