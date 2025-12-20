import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'features/auth/auth_controller.dart';
import 'uri_helpers.dart';
import 'widgets/inline_error_banner.dart';

class UploadArtworkPage extends ConsumerStatefulWidget {
  const UploadArtworkPage({super.key});

  @override
  ConsumerState<UploadArtworkPage> createState() => _UploadArtworkPageState();
}

class _UploadArtworkPageState extends ConsumerState<UploadArtworkPage> {
  // ---- 設定（ここだけ変えればOK） ----
  static const int maxFileBytes = 10 * 1024 * 1024; // 10MB
  static const Set<String> allowedExt = {'jpg', 'jpeg', 'png'};
  // バックエンドの作品作成API（multipart/form-data）
  static const String uploadPath = '/work';
  // ----------------------------------

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _isSubmitting = false;
  String? _submitError;

  // 選択されたファイル情報（Web/モバイル両対応）
  String? _fileName;
  String? _filePath; // モバイル等
  Uint8List? _fileBytes; // Web等
  int? _fileSize;

  @override
  void initState() {
    super.initState();
    // 入力変更時にも再描画して送信ボタンの有効/無効を切り替える
    _titleCtrl.addListener(_handleTextChange);
    _descCtrl.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_handleTextChange);
    _descCtrl.removeListener(_handleTextChange);
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    setState(() => _submitError = null);
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
      _submitError = null;
    });

    final err = _validateSelectedFile();
    if (err != null && mounted) {
      setState(() => _submitError = err);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitError = null);
    // 1) フォーム検証
    final validForm = _formKey.currentState?.validate() ?? false;
    if (!validForm) return;

    // 2) ファイル検証
    final fileErr = _validateSelectedFile();
    if (fileErr != null) {
      setState(() => _submitError = fileErr);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (backendBaseUrl.trim().isEmpty) {
        setState(() {
          _submitError = 'BACKEND_BASE_URL が未設定です。';
        });
        return;
      }

      final authUser = ref.read(authControllerProvider).user;
      if (authUser == null) {
        setState(() {
          _submitError = 'ログインしてください。';
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

      final uri = joinBasePath(base, uploadPath);

      Uint8List bytes;
      if (_fileBytes != null) {
        bytes = _fileBytes!;
      } else if (_filePath != null) {
        bytes = await File(_filePath!).readAsBytes();
      } else {
        throw Exception('ファイルデータが取得できませんでした');
      }

      final req = http.MultipartRequest('POST', uri);
      req.fields['user_id'] = authUser.id;
      req.fields['title'] = _titleCtrl.text.trim();
      final desc = _descCtrl.text.trim();
      if (desc.isNotEmpty) {
        req.fields['description'] = desc;
      }
      req.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: _fileName ?? 'upload.png',
        ),
      );

      final client = http.Client();
      late final http.Response res;
      try {
        final streamed = await client
            .send(req)
            .timeout(const Duration(seconds: 20));
        res = await http.Response.fromStream(streamed);
      } finally {
        client.close();
      }

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
        setState(() {
          _submitError =
              '送信に失敗しました（${res.statusCode}）。時間をおいて再試行してください。';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = '通信エラーが発生しました。時間をおいて再試行してください。';
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileErr = _validateSelectedFile();
    final hasFile = _fileName != null && fileErr == null;
    final submitError = _submitError;

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
                  if (submitError != null) ...[
                    InlineErrorBanner(message: submitError),
                    const SizedBox(height: 12),
                  ],
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
                    if (v != null && v.length > 500) {
                      return '説明文は500文字以内にしてください。';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // 送信
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : (_canSubmit() ? _submit : null),
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
