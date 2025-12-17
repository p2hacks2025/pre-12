import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

class UploadArtworkPage extends StatefulWidget {
  const UploadArtworkPage({super.key});

  @override
  State<UploadArtworkPage> createState() => _UploadArtworkPageState();
}

class _UploadArtworkPageState extends State<UploadArtworkPage> {
  // ---- 設定（ここだけ変えればOK） ----
  static const int maxFileBytes = 10 * 1024 * 1024; // 10MB
  static const Set<String> allowedExt = {'jpg', 'jpeg', 'png'};
  // バックエンドの作品作成API（JSON）
  static const String uploadEndpoint =
      'https://example.com/api/artworks'; // TODO: 自分のAPIへ
  // 画像アップロードAPI（任意）。未設定(null/空)なら data URL を使います。
  static const String? imageUploadEndpoint =
      null; // 例: 'https://example.com/api/uploads'
  // 送信ユーザーID（本来は認証から取得）
  static const String userId = 'uuid';
  // ----------------------------------

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _isSubmitting = false;

  // 選択されたファイル情報（Web/モバイル両対応）
  String? _fileName;
  String? _filePath; // モバイル等
  Uint8List? _fileBytes; // Web等
  int? _fileSize;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String? _validateSelectedFile() {
    if (_fileName == null) return '画像を選択してください。';

    final ext = _fileName!.split('.').last.toLowerCase();
    if (!allowedExt.contains(ext)) {
      return '拡張子が不正です（JPEG / PNG のみ）。';
    }

    final size = _fileSize;
    if (size == null) return 'ファイルサイズを取得できませんでした。';
    if (size > maxFileBytes) {
      return 'ファイルサイズが上限を超えています（最大 ${(maxFileBytes / (1024 * 1024)).toStringAsFixed(0)}MB）。';
    }

    return null;
  }

  bool _canSubmit() {
    // ファイル検証
    if (_validateSelectedFile() != null) return false;
    // タイトル検証
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || title.length > 80) return false;
    // 説明文検証（任意だが長さチェック）
    if (_descCtrl.text.length > 500) return false;
    return true;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final name = image.name;
    final path = image.path;
    final bytes = await image.readAsBytes();
    final size = bytes.lengthInBytes;

    setState(() {
      _fileName = name;
      _fileBytes = bytes;
      _filePath = path;
      _fileSize = size;
    });

    final err = _validateSelectedFile();
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _submit() async {
    // 1) フォーム検証
    final validForm = _formKey.currentState?.validate() ?? false;
    if (!validForm) return;

    // 2) ファイル検証
    final fileErr = _validateSelectedFile();
    if (fileErr != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(fileErr)));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 画像URLを用意（アップロードAPIが未設定なら data URL を生成）
      final imageUrl = await _resolveImageUrl();

      final payload = {
        'user_id': userId,
        'image_url': imageUrl,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
      };

      final res = await http.post(
        Uri.parse(uploadEndpoint),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer ...', // 必要なら
        },
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('送信完了')));
        setState(() {
          _fileName = null;
          _filePath = null;
          _fileBytes = null;
          _fileSize = null;
        });
        _titleCtrl.clear();
        _descCtrl.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('送信失敗: ${res.statusCode}\n${res.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('通信エラー: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // 画像URLを用意する
  // - imageUploadEndpoint が設定されている: マルチパートでアップロード → 応答JSONの url/image_url を返す想定
  // - 未設定: データURL(data:<mime>;base64,...) を返す（テスト用）
  Future<String> _resolveImageUrl() async {
    final filename = _fileName!;
    final mime = lookupMimeType(filename) ?? 'application/octet-stream';

    // バイト列を用意
    Uint8List bytes;
    if (_fileBytes != null) {
      bytes = _fileBytes!;
    } else if (_filePath != null) {
      bytes = await File(_filePath!).readAsBytes();
    } else {
      throw Exception('ファイルデータが取得できませんでした。');
    }

    if (imageUploadEndpoint == null || imageUploadEndpoint!.isEmpty) {
      // テスト用: データURLを返す
      final b64 = base64Encode(bytes);
      return 'data:$mime;base64,$b64';
    }

    // 実アップロード
    final req = http.MultipartRequest('POST', Uri.parse(imageUploadEndpoint!));
    req.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    // 認証が必要ならここでヘッダーを追加
    // req.headers['Authorization'] = 'Bearer ...';

    final resp = await req.send();
    final body = await resp.stream.bytesToString();
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map && decoded['image_url'] is String) {
          return decoded['image_url'] as String;
        } else if (decoded is Map && decoded['url'] is String) {
          return decoded['url'] as String;
        }
      } catch (_) {}
      throw Exception('画像アップロードの応答が不正です: $body');
    } else {
      throw Exception('画像アップロード失敗: ${resp.statusCode}\n$body');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileErr = _validateSelectedFile();
    final hasFile = _fileName != null && fileErr == null;

    Widget preview;
    if (_fileBytes != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(_fileBytes!, height: 180, fit: BoxFit.cover),
      );
    } else if (_filePath != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(_filePath!), height: 180, fit: BoxFit.cover),
      );
    } else {
      preview = Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: const Center(child: Text('未選択')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('作品アップロード')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 画像アップロード
                const Text(
                  'イラスト画像のアップロード',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                preview,
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _pickImage,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('画像を選択（JPEG / PNG）'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _fileName == null
                      ? '条件：拡張子 JPEG/PNG、サイズ上限 ${(maxFileBytes / (1024 * 1024)).toStringAsFixed(0)}MB'
                      : '選択中：$_fileName（${_fileSize ?? "-"} bytes）',
                  style: TextStyle(
                    color: (_fileName == null || hasFile)
                        ? Colors.black54
                        : Colors.red,
                  ),
                ),
                if (_fileName != null && fileErr != null) ...[
                  const SizedBox(height: 6),
                  Text(fileErr, style: const TextStyle(color: Colors.red)),
                ],

                const SizedBox(height: 16),

                // 作品タイトル
                const Text(
                  '作品タイトル',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    hintText: '例：夜の街のスケッチ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '作品タイトルは必須です。';
                    if (v.trim().length > 80) return 'タイトルは80文字以内にしてください。';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // 簡単な説明文（任意）
                const Text(
                  '簡単な説明文（任意入力）',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    hintText: '制作背景やポイントなど（任意）',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (v) {
                    if (v != null && v.length > 500)
                      return '説明文は500文字以内にしてください。';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // 送信
                ElevatedButton(
                  onPressed: _isSubmitting ? null : (_canSubmit() ? _submit : null),
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
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _canSubmit() ? 'バックエンドへ送信' : '入力内容を確認してください',
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
