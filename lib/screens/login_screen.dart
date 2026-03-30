import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../theme/app_theme.dart';
import '../main_shell.dart';
import '../services/subscription_service.dart';
import 'paywall_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _isAppleSignInLoading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// ランダムなnonce文字列を生成（Sign in with Apple セキュリティ用）
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// SHA256ハッシュ
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sign in with Apple 処理
  Future<void> _signInWithApple(BuildContext context) async {
    setState(() => _isAppleSignInLoading = true);
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          // 名前・メールアドレスのみ収集（ガイドライン4.8準拠）
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      if (!context.mounted) return;

      // Apple提供の情報（プライベートメールも自動対応）
      final email = credential.email; // nullの場合はプライベートリレーメール
      final givenName = credential.givenName ?? '';
      final familyName = credential.familyName ?? '';
      final fullName = '$familyName$givenName'.trim();
      final displayName = fullName.isNotEmpty ? fullName : 'Appleユーザー';

      if (kDebugMode) {
        debugPrint('Apple Sign In 成功: $displayName / $email');
      }

      // ログイン後の画面遷移
      await _navigateAfterLogin(context);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (!context.mounted) return;
      if (e.code == AuthorizationErrorCode.canceled) {
        // ユーザーがキャンセル → 何もしない
        return;
      }
      _showError(context, 'Sign in with Apple に失敗しました。もう一度お試しください。');
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'ログインに失敗しました。もう一度お試しください。');
    } finally {
      if (mounted) setState(() => _isAppleSignInLoading = false);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  /// ログイン後の画面遷移（サブスク確認）
  Future<void> _navigateAfterLogin(BuildContext context) async {
    final sub = context.read<SubscriptionService>();
    if (sub.isLoading) {
      await Future.delayed(const Duration(milliseconds: 800));
    }
    if (!context.mounted) return;

    if (sub.isSubscribed) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
    }
  }

  void _onLogin(BuildContext context) async {
    await _navigateAfterLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景色
          Container(color: const Color(0xFF3D8FBF)),

          // 富士山背景写真
          Positioned.fill(
            child: Image.asset(
              'assets/images/fuji_bg.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0.0, -0.3),
            ),
          ),

          // 暗オーバーレイ
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ),

          // 下部グラデーション
          Positioned(
            bottom: 0, left: 0, right: 0, height: 460,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xAA000000), Color(0xDD000000)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // メインコンテンツ
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      _buildLogo(),
                      const SizedBox(height: 14),
                      Text(
                        'Shotmap',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'あなたの「お気に入り」が',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.92),
                          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '誰かの「最高の景色」になる。',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      _buildLoginCard(context),
                      const SizedBox(height: 44),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 88, height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.location_on, size: 48, color: AppColors.primary),
          Positioned(
            bottom: 18, right: 18,
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, size: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.22),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'はじめましょう',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1分で登録完了！あなたの発見を共有しよう✨',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // ① Sign in with Apple（Apple審査ガイドライン4.8：最上部に配置）
          _buildAppleSignInButton(context),

          const SizedBox(height: 12),

          // ② LINEでログイン
          _buildSocialButton(
            context: context,
            label: 'LINEでログイン',
            color: const Color(0xFF06C755),
            onTap: () => _onLogin(context),
          ),

          const SizedBox(height: 12),

          // ③ Googleでログイン
          _buildSocialButton(
            context: context,
            label: 'Googleでログイン',
            color: Colors.white,
            textColor: AppColors.textPrimary,
            hasBorder: true,
            onTap: () => _onLogin(context),
          ),

          const SizedBox(height: 20),

          // 利用規約・プライバシーポリシー
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text('ログインすることで',
                    style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TermsScreen())),
                  child: Text('利用規約',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      )),
                ),
                Text('と',
                    style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyScreen())),
                  child: Text('プライバシーポリシー',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      )),
                ),
                Text('に同意します',
                    style: TextStyle(fontSize: 10, color: AppColors.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sign in with Apple ボタン（Apple HIG準拠デザイン）
  Widget _buildAppleSignInButton(BuildContext context) {
    return GestureDetector(
      onTap: _isAppleSignInLoading ? null : () => _signInWithApple(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: _isAppleSignInLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Appleロゴ（SVGの代わりにIcon使用）
                    const Icon(Icons.apple, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Appleでサインイン',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required String label,
    required Color color,
    required VoidCallback onTap,
    Color textColor = Colors.white,
    bool hasBorder = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: hasBorder ? Border.all(color: AppColors.border, width: 1.5) : null,
          boxShadow: hasBorder
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
