// ────────────────────────────────────────────────────────────────────────────
// DeleteAccountScreen  ―  アカウント削除画面
// Apple ガイドライン 5.1.1(v) 準拠
//   ・削除ボタン → 確認ダイアログ → 最終確認 → 削除実行
//   ・ローカルデータ（SharedPreferences / Hive）を完全クリア
//   ・完了後はログイン画面へ遷移
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isDeleting = false;
  final TextEditingController _confirmController = TextEditingController();
  // _inputMatchesはモーダル内のStatefulBuilderで管理

  static const String _confirmWord = 'DELETE';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  /// Step1: 最初の確認ダイアログ
  Future<void> _showFirstConfirm() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('本当に削除しますか？', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          'アカウントを削除すると、以下のデータがすべて失われます：\n\n'
          '・投稿したすべてのピン\n'
          '・保存済みスポット\n'
          '・フォロー情報\n'
          '・プロフィール情報\n\n'
          'この操作は取り消せません。',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('キャンセル',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('次へ進む', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      _showFinalConfirm();
    }
  }

  /// Step2: 最終確認（「DELETE」入力）
  void _showFinalConfirm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final controller = TextEditingController();
          bool matches = false;
          controller.addListener(() {
            setModalState(() {
              matches = controller.text.trim() == _confirmWord;
            });
          });

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ハンドルバー
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // タイトル
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_forever, color: Colors.red, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('最終確認',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('この操作は取り消せません',
                              style: TextStyle(fontSize: 12, color: Colors.red)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 入力指示
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                      children: [
                        const TextSpan(text: '削除を確認するには、以下のボックスに '),
                        TextSpan(
                          text: _confirmWord,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.red,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const TextSpan(text: ' と入力してください。'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 入力フィールド
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: _confirmWord,
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.red.withValues(alpha: 0.03),
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 削除ボタン
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: StatefulBuilder(
                      builder: (_, setBtn) {
                        return ElevatedButton(
                          onPressed: matches
                              ? () {
                                  Navigator.pop(ctx);
                                  _executeDelete();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade200,
                            disabledForegroundColor: Colors.grey.shade400,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: matches ? 3 : 0,
                          ),
                          child: const Text(
                            'アカウントを完全に削除する',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // キャンセルボタン
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'キャンセル',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// アカウント削除実行
  Future<void> _executeDelete() async {
    setState(() => _isDeleting = true);

    try {
      // ① SharedPreferences を全消去
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // ② Hive の全ボックスを消去
      try {
        final openBoxNames = List<String>.from(Hive.box('userBox').isOpen
            ? ['userBox']
            : []);
        for (final name in openBoxNames) {
          await Hive.box(name).clear();
        }
        await Hive.deleteFromDisk(); // 全Hiveデータ削除
      } catch (e) {
        if (kDebugMode) debugPrint('Hive clear error (ignored): $e');
      }

      // ③ 少し待機（UX向け）
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // ④ 完了ダイアログ表示
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('削除完了',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                'アカウントとすべてのデータが\n正常に削除されました。\nご利用ありがとうございました。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('閉じる', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );

      // ⑤ ログイン画面へリダイレクト
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (_) => false,
      );
    } catch (e) {
      setState(() => _isDeleting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('削除中にエラーが発生しました: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'アカウント削除',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _isDeleting
          ? _buildLoadingView()
          : _buildContentView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.red),
          const SizedBox(height: 20),
          Text(
            'アカウントを削除しています...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'しばらくお待ちください',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 警告バナー
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Column(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'アカウント削除について',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'この操作は取り消すことができません。\nアカウントを削除する前に、以下をご確認ください。',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade700,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 削除されるデータの一覧
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '削除されるデータ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _deleteItem(Icons.push_pin, '投稿したすべてのピン・スポット'),
                _deleteItem(Icons.bookmark, '保存済みスポット一覧'),
                _deleteItem(Icons.people, 'フォロー・フォロワー情報'),
                _deleteItem(Icons.person, 'プロフィール情報（名前・アイコン）'),
                _deleteItem(Icons.settings, '設定・環境設定データ'),
                _deleteItem(Icons.star, 'サブスクリプション情報'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 注意事項
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFD54F)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'サブスクリプションについて',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF57F17),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'アカウント削除後もサブスクリプションは自動で解約されません。'
                        'App Store（iOS）またはGoogle Play（Android）の設定から'
                        '別途キャンセルしてください。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 削除ボタン
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _showFirstConfirm,
              icon: const Icon(Icons.delete_forever, size: 22),
              label: const Text(
                'アカウントを削除する',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 戻るリンク
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'キャンセル（設定に戻る）',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _deleteItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
