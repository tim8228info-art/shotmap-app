import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/user_profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _customIdCtrl;
  late TextEditingController _instagramCtrl;
  late TextEditingController _youtubeCtrl;
  late TextEditingController _xCtrl;
  late TextEditingController _tiktokCtrl;

  bool _isSaving = false;
  String? _customIdError;

  /// フォロー一覧を他ユーザーから非公開にするかどうか
  bool _hideFollowing = false;

  final Map<String, bool> _touched = {
    'name': false,
  };

  @override
  void initState() {
    super.initState();
    final p = context.read<UserProfileProvider>();
    _nameCtrl      = TextEditingController(text: p.name == 'あなたの名前' ? '' : p.name);
    _bioCtrl       = TextEditingController(text: p.bio);
    _customIdCtrl  = TextEditingController(text: p.customId);
    _instagramCtrl = TextEditingController(text: p.instagramUrl);
    _youtubeCtrl   = TextEditingController(text: p.youtubeUrl);
    _xCtrl         = TextEditingController(text: p.xUrl);
    _tiktokCtrl    = TextEditingController(text: p.tiktokUrl);
    _hideFollowing = p.hideFollowing; // 現在の設定を反映
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _customIdCtrl.dispose();
    _instagramCtrl.dispose();
    _youtubeCtrl.dispose();
    _xCtrl.dispose();
    _tiktokCtrl.dispose();
    super.dispose();
  }

  // ────────── 保存処理 ──────────
  Future<void> _save() async {
    setState(() {
      _touched['name'] = true;
      _isSaving = true;
    });

    // ニックネーム未入力チェック
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _isSaving = false);
      _showSnack('ニックネームを入力してください', isError: true);
      return;
    }

    // カスタムID バリデーション
    final provider = context.read<UserProfileProvider>();
    final idError = provider.validateCustomId(_customIdCtrl.text);
    if (idError != null) {
      setState(() {
        _customIdError = idError;
        _isSaving = false;
      });
      _showSnack(idError, isError: true);
      return;
    }

    // URL 形式チェック（入力がある場合のみ）
    final urlFields = {
      'Instagram': _instagramCtrl.text.trim(),
      'YouTube': _youtubeCtrl.text.trim(),
      'X (Twitter)': _xCtrl.text.trim(),
      'TikTok': _tiktokCtrl.text.trim(),
    };
    for (final entry in urlFields.entries) {
      if (entry.value.isNotEmpty && !_isValidUrl(entry.value)) {
        setState(() => _isSaving = false);
        _showSnack('${entry.key} のURLが正しくありません\n（https:// から入力してください）',
            isError: true);
        return;
      }
    }

    // 少し待って保存（ローディング演出）
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    context.read<UserProfileProvider>().updateProfile(
          name: _nameCtrl.text,
          bio: _bioCtrl.text,
          customId: _customIdCtrl.text,
          instagramUrl: _instagramCtrl.text.trim(),
          youtubeUrl: _youtubeCtrl.text.trim(),
          xUrl: _xCtrl.text.trim(),
          tiktokUrl: _tiktokCtrl.text.trim(),
          hideFollowing: _hideFollowing,
        );

    setState(() => _isSaving = false);
    if (!mounted) return;
    _showSnack('プロフィールを保存しました ✓');
    Navigator.of(context).pop();
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http');
    } catch (_) {
      return false;
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ────────── UI ──────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // アバター
              _buildAvatarSection(),
              const SizedBox(height: 28),

              // ── 基本情報セクション ──
              _buildSectionHeader(Icons.person_outline, '基本情報'),
              const SizedBox(height: 12),
              _buildCard(children: [
                _buildTextField(
                  controller: _nameCtrl,
                  label: 'ニックネーム',
                  hint: '例: 旅するカメラマン',
                  icon: Icons.badge_outlined,
                  maxLength: 20,
                  isRequired: true,
                  showError: (_touched['name'] ?? false) &&
                      _nameCtrl.text.trim().isEmpty,
                  errorText: 'ニックネームは必須です',
                  onChanged: (_) => setState(() {}),
                ),
                const _Divider(),
                _buildTextField(
                  controller: _bioCtrl,
                  label: '紹介文',
                  hint: '例: 日本全国の絶景を記録しています📍\n写真・旅・カフェが大好き',
                  icon: Icons.edit_note_outlined,
                  maxLines: 4,
                  maxLength: 150,
                  onChanged: (_) => setState(() {}),
                ),
              ]),

              const SizedBox(height: 28),

              // ── カスタムIDセクション ──
              _buildSectionHeader(Icons.tag, 'カスタムID'),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 12),
                child: Text(
                  '半角英数字とアンダースコア(_)で設定できます。IDは他のユーザーと重複できません。',
                  style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.5,
                  ),
                ),
              ),
              _buildCard(children: [
                _buildCustomIdField(),
              ]),

              const SizedBox(height: 28),

              // ── SNSリンクセクション ──
              _buildSectionHeader(Icons.link, 'SNSリンク'),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 12),
                child: Text(
                  'URLを入力すると、マイページのSNSボタンがそのページへリンクされます',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              _buildCard(children: [
                _buildSnsField(
                  controller: _instagramCtrl,
                  platform: 'Instagram',
                  hint: 'https://www.instagram.com/あなたのID',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                  ),
                  icon: Icons.camera_alt,
                ),
                const _Divider(),
                _buildSnsField(
                  controller: _youtubeCtrl,
                  platform: 'YouTube',
                  hint: 'https://www.youtube.com/@あなたのチャンネル',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
                  ),
                  icon: Icons.play_circle_fill,
                ),
                const _Divider(),
                _buildSnsField(
                  controller: _xCtrl,
                  platform: 'X (Twitter)',
                  hint: 'https://x.com/あなたのID',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF444444)],
                  ),
                  icon: Icons.close,
                ),
                const _Divider(),
                _buildSnsField(
                  controller: _tiktokCtrl,
                  platform: 'TikTok',
                  hint: 'https://www.tiktok.com/@あなたのID',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF010101), Color(0xFF69C9D0)],
                  ),
                  icon: Icons.music_note,
                ),
              ]),

              const SizedBox(height: 32),

              // ── プライバシー設定セクション ──
              _buildSectionHeader(Icons.lock_outline, 'プライバシー設定'),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 12),
                child: Text(
                  'フォロー一覧の公開・非公開を設定できます',
                  style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.5,
                  ),
                ),
              ),
              _buildCard(children: [
                _buildFollowPrivacyToggle(),
              ]),

              const SizedBox(height: 32),

              // 保存ボタン
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.border,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close, color: AppColors.textSecondary),
      ),
      title: Text(
        'プロフィール編集',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '保存',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── アバターセクション ──
  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          // アバター画像
          Consumer<UserProfileProvider>(
            builder: (_, provider, __) => Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryLight, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  provider.avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primaryLight,
                    child: const Icon(Icons.person, color: Colors.white, size: 52),
                  ),
                ),
              ),
            ),
          ),
          // カメラアイコン（変更ボタン）
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                // 実機では image_picker を使うが、プレビュー用にダミー表示
                _showSnack('アバター変更は実機でご利用ください');
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── セクションヘッダー ──
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ── カードコンテナ ──
  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ── 汎用テキストフィールド ──
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    bool isRequired = false,
    bool showError = false,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                Text(
                  '必須',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              if (maxLength != null)
                Text(
                  '${controller.text.length} / $maxLength',
                  style: TextStyle(
                    fontSize: 11,
                    color: controller.text.length > (maxLength * 0.8)
                        ? AppColors.accent
                        : AppColors.textHint,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            onChanged: onChanged,
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
                height: 1.5,
              ),
              counterText: '',
              filled: true,
              fillColor: showError
                  ? const Color(0xFFFFF0F0)
                  : AppColors.primaryVeryLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: showError
                    ? const BorderSide(color: Color(0xFFE53935), width: 1.5)
                    : BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: showError
                    ? const BorderSide(color: Color(0xFFE53935), width: 1.5)
                    : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: showError ? const Color(0xFFE53935) : AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          if (showError && errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 2),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 13, color: Color(0xFFE53935)),
                  const SizedBox(width: 4),
                  Text(
                    errorText,
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFFE53935),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── カスタムIDフィールド ──
  Widget _buildCustomIdField() {
    final idVal = _customIdCtrl.text.trim();
    final provider = context.read<UserProfileProvider>();
    final isAvailable = idVal.isEmpty || provider.isCustomIdAvailable(idVal);
    final hasError = _customIdError != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tag, size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      'カスタムID',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (idVal.isNotEmpty && !hasError)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAvailable ? const Color(0xFFDDF6E8) : const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAvailable ? Icons.check_circle : Icons.cancel,
                        size: 11,
                        color: isAvailable ? const Color(0xFF2ECC71) : const Color(0xFFE53935),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isAvailable ? '使用可能' : '使用不可',
                        style: TextStyle(
                          fontSize: 10,
                          color: isAvailable ? const Color(0xFF27AE60) : const Color(0xFFE53935),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (idVal.isEmpty)
                Text(
                  '任意',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customIdCtrl,
            keyboardType: TextInputType.text,
            onChanged: (v) {
              setState(() {
                _customIdError = provider.validateCustomId(v);
              });
            },
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '例: yuki_travel（3〜20文字、半角英数字・_）',
              hintStyle: TextStyle(fontSize: 12, color: AppColors.textHint),
              prefixText: '@',
              prefixStyle: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary,
              ),
              filled: true,
              fillColor: hasError ? const Color(0xFFFFF0F0) : AppColors.primaryVeryLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: hasError
                    ? const BorderSide(color: Color(0xFFE53935), width: 1.5)
                    : BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: hasError
                    ? const BorderSide(color: Color(0xFFE53935), width: 1.5)
                    : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError ? const Color(0xFFE53935) : AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: _customIdCtrl.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _customIdCtrl.clear();
                        setState(() => _customIdError = null);
                      },
                      icon: const Icon(Icons.clear, size: 16, color: AppColors.textHint),
                    )
                  : null,
            ),
          ),
          if (_customIdError != null)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 2),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 13, color: Color(0xFFE53935)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _customIdError!,
                      style: TextStyle(
                        fontSize: 11, color: const Color(0xFFE53935),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (idVal.isNotEmpty && _customIdError == null) ...[
            const SizedBox(height: 5),
            Text(
              '一度設定したIDは他のユーザーと共有できません',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ],
      ),
    );
  }

  // ── SNS専用フィールド（グラデーションバッジ付き） ──
  Widget _buildSnsField({
    required TextEditingController controller,
    required String platform,
    required String hint,
    required Gradient gradient,
    required IconData icon,
  }) {
    final hasValue = controller.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // プラットフォームバッジ
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      platform,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasValue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF6E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 11, color: Color(0xFF2ECC71)),
                      const SizedBox(width: 3),
                      Text(
                        '設定済み',
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF27AE60),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  '未設定',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // URLフィールド
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
              filled: true,
              fillColor: AppColors.primaryVeryLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: hasValue
                  ? const Icon(Icons.link, size: 16, color: AppColors.primary)
                  : const Icon(Icons.add_link, size: 16, color: AppColors.textHint),
              // クリアボタン
              suffixIcon: hasValue
                  ? IconButton(
                      onPressed: () {
                        controller.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear, size: 16, color: AppColors.textHint),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── フォロー非公開トグル ──
  Widget _buildFollowPrivacyToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          // 鍵アイコン（状態に応じて変化）
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Container(
              key: ValueKey(_hideFollowing),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _hideFollowing
                    ? const Color(0xFFE8F4FD)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hideFollowing
                      ? AppColors.primaryLight
                      : AppColors.border,
                ),
              ),
              child: Icon(
                _hideFollowing ? Icons.lock : Icons.lock_open_outlined,
                size: 20,
                color: _hideFollowing
                    ? AppColors.primary
                    : AppColors.textHint,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // ラベル
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'フォロー一覧を非公開にする',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _hideFollowing
                      ? '他のユーザーはフォロー一覧を見られません'
                      : 'フォロー数は誰でも確認できます',
                  style: TextStyle(
                    fontSize: 11,
                    color: _hideFollowing
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // スイッチ
          Switch(
            value: _hideFollowing,
            onChanged: (v) => setState(() => _hideFollowing = v),
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }

  // ── 保存ボタン（大きめ） ──
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                'プロフィールを保存する',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ── 区切り線（カード内） ──
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.border,
    );
  }
}
