import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../config.dart';
import 'profile_models.dart';

class ProfileService {
  const ProfileService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Uri _baseUri() {
    try {
      return Uri.parse(backendBaseUrl);
    } catch (_) {
      throw Exception('BACKEND_BASE_URL が不正です: $backendBaseUrl');
    }
  }

  Future<UserProfile?> getMyProfile({required String userId}) async {
    if (backendBaseUrl.trim().isEmpty) return null;

    final base = _baseUri();
    final uri = base
        .resolve('/me')
        .replace(queryParameters: <String, String>{'user_id': userId});

    final client = _client ?? http.Client();
    try {
      final res = await client.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('プロフィール取得に失敗: ${res.statusCode} ${res.body}');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('プロフィール取得の応答が不正です');
      }

      return UserProfile.fromJson(decoded);
    } finally {
      if (_client == null) client.close();
    }
  }

  Future<UserProfile?> updateMyProfile({
    required String userId,
    required String username,
    required String bio,
    XFile? icon,
  }) async {
    if (backendBaseUrl.trim().isEmpty) {
      return UserProfile(
        id: userId,
        username: username,
        email: '',
        iconUrl: '',
        bio: bio,
      );
    }

    final base = _baseUri();
    final uri = base
        .resolve('/update-profile')
        .replace(queryParameters: <String, String>{'user_id': userId});

    final req = http.MultipartRequest('POST', uri);
    req.fields['username'] = username;
    req.fields['bio'] = bio;

    if (icon != null) {
      final bytes = await icon.readAsBytes();
      req.files.add(
        http.MultipartFile.fromBytes('icon', bytes, filename: icon.name),
      );
    }

    final client = _client ?? http.Client();
    try {
      final streamed = await client
          .send(req)
          .timeout(const Duration(seconds: 12));
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('プロフィール更新に失敗: ${res.statusCode} ${res.body}');
      }

      // update-profile のレスポンスだけだと全項目揃わないので、更新後に /me を取り直す
      return await getMyProfile(userId: userId);
    } finally {
      if (_client == null) client.close();
    }
  }
}
