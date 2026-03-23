import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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

  void _onLogin(BuildContext context) async {
    final sub = context.read<SubscriptionService>();

    // サブスクリプション状態を確認（少し待つ）
    if (sub.isLoading) {
      await Future.delayed(const Duration(milliseconds: 800));
    }

    if (!context.mounted) return;

    if (sub.isSubscribed) {
      // サブスク済み → メイン画面へ
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      // 未購入 → ペイウォール画面へ
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ① 背景（写真読み込み前のフォールバック）
          Container(
            color: const Color(0xFF3D8FBF),
          ),

          // ② 富士山の背景写真
          Positioned.fill(
            child: Image.asset(
              'assets/images/fuji_bg.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0.0, -0.3),
            ),
          ),

          // 全体に薄い暗オーバーレイ（テキスト可読性向上）
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ),

          // ③ 下部グラデーションオーバーレイ（カードとイラストを自然に馴染ませる）
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 420,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xAA000000),
                    Color(0xDD000000),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ④ メインコンテンツ（ロゴ・テキスト・ログインカード）
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

                      // ロゴ
                      _buildLogo(),

                      const SizedBox(height: 14),

                      // アプリ名
                      Text(
                        'Shotmap',
                        style: GoogleFonts.poppins(
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

                      // キャッチコピー
                      Text(
                        'あなたの「お気に入り」が',
                        style: GoogleFonts.notoSansJp(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.92),
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '誰かの「最高の景色」になる。',
                        style: GoogleFonts.notoSansJp(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const Spacer(),

                      // ログインカード
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
      width: 88,
      height: 88,
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
          const Icon(
            Icons.location_on,
            size: 48,
            color: AppColors.primary,
          ),
          Positioned(
            bottom: 18,
            right: 18,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 13,
                color: Colors.white,
              ),
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
            style: GoogleFonts.notoSansJp(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1分で登録完了！あなたの発見を共有しよう✨',
            style: GoogleFonts.notoSansJp(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // LINEボタン（アイコンなし・文字のみ）
          _buildSocialButton(
            context: context,
            label: 'LINEでログイン',
            color: const Color(0xFF06C755),
            onTap: () => _onLogin(context),
          ),

          const SizedBox(height: 12),

          // Googleボタン（アイコンなし・文字のみ）
          _buildSocialButton(
            context: context,
            label: 'Googleでログイン',
            color: Colors.white,
            textColor: AppColors.textPrimary,
            hasBorder: true,
            onTap: () => _onLogin(context),
          ),

          const SizedBox(height: 20),

          // 利用規約・プライバシーポリシー リンク
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text(
                  'ログインすることで',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TermsScreen()),
                  ),
                  child: Text(
                    '利用規約',
                    style: GoogleFonts.notoSansJp(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  'と',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  ),
                  child: Text(
                    'プライバシーポリシー',
                    style: GoogleFonts.notoSansJp(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  'に同意します',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          border: hasBorder
              ? Border.all(color: AppColors.border, width: 1.5)
              : null,
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
            style: GoogleFonts.notoSansJp(
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
