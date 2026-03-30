// ────────────────────────────────────────────────────────────────────────────
// PaywallScreen  v2.0 – サブスクリプション購入画面
//
// iOS (StoreKit) / Android (Google Play Billing) 両対応。
// Apple・Google のレビューガイドライン準拠:
//   ✅ iOS: 復元ボタン、Apple EULA、自動更新説明
//   ✅ Android: 明示的な価格表示、「いつでもキャンセル可能」文言、Google Play リンク
//
// テスト用スキップボタンの制御:
//   TestFlight用ビルド: flutter build ipa --release --dart-define=TESTFLIGHT_MODE=true
//   本番リリース用ビルド: flutter build ipa --release  ← ボタン非表示
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_service.dart';
import '../main_shell.dart';
import '../widgets/subscription/plan_card.dart';
import '../widgets/subscription/subscribe_button.dart';
import '../widgets/subscription/feature_list.dart';
import '../widgets/subscription/disclaimer_section.dart';
import '../widgets/subscription/legal_links_row.dart';

// TestFlight / 審査用ビルドフラグ（本番リリース時は付けない）
// TestFlight用: flutter build ipa --release --dart-define=TESTFLIGHT_MODE=true
// 本番用:       flutter build ipa --release  ← このフラグなしでビルド
// Web開発用:    常に表示（kIsWeb == true の場合）
const bool _kTestFlightMode =
    bool.fromEnvironment('TESTFLIGHT_MODE', defaultValue: false);

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
  // ── プラットフォーム判定 ────────────────────────────────────────────────
  bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // ── URL 定数 ───────────────────────────────────────────────────────────
  static const String _appleEulaUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
  static const String _privacyPolicyUrl =
      'https://tim8228info-art.github.io/shotmap-support/';
  static const String _termsOfServiceUrl =
      'https://tim8228info-art.github.io/shotmap-support/';

  // ── アニメーション ──────────────────────────────────────────────────────
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────
  // 購読完了の検知 → メイン画面へ自動遷移
  // ────────────────────────────────────────────────────────────────────────
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sub = context.watch<SubscriptionService>();
    if (sub.isSubscribed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _navigateToMain();
      });
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // ナビゲーション & UI ヘルパー
  // ────────────────────────────────────────────────────────────────────────
  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // 購入ボタン処理
  // ────────────────────────────────────────────────────────────────────────
  Future<void> _onPurchaseTap() async {
    final sub = context.read<SubscriptionService>();
    await sub.purchaseMonthlyPlan();
  }

  // ────────────────────────────────────────────────────────────────────────
  // 復元ボタン処理（iOS 必須）
  // ────────────────────────────────────────────────────────────────────────
  Future<void> _onRestoreTap() async {
    final sub = context.read<SubscriptionService>();
    await sub.restorePurchases();
    if (!mounted) return;
    if (sub.isSubscribed) {
      _navigateToMain();
    } else if (sub.errorMessage == null) {
      _showSnackBar('復元できる購入が見つかりませんでした。');
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // build
  // ────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, sub, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          body: FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),

                    // ── ① ヘッダー（アイコン・タイトル・サブタイトル）
                    _buildHeader(),

                    const SizedBox(height: 32),

                    // ── ② 機能紹介リスト
                    const FeatureList(),

                    const SizedBox(height: 24),

                    // ── ③ 月額プランカード（価格は常に円建てで固定表示）
                    const PlanCard(
                      storePrice: '¥500',
                      isSelected: true,
                    ),

                    const SizedBox(height: 20),

                    // ── ④ エラーバナー（エラー時のみ表示）
                    if (sub.errorMessage != null) ...[
                      _buildErrorBanner(sub.errorMessage!),
                      const SizedBox(height: 12),
                    ],

                    // ── ⑤ 購入ボタン
                    SubscribeButton(
                      label: _buildButtonLabel(sub),
                      onPressed: sub.isLoading ? null : _onPurchaseTap,
                      isLoading: sub.isLoading,
                    ),

                    // ── ⑥ iOS のみ: 購入を復元する（Apple 審査必須）
                    if (_isIOS) ...[
                      const SizedBox(height: 12),
                      _buildRestoreButton(sub),
                    ],

                    // ── ⑥-b テスト用スキップボタン（全環境で非表示）

                    const SizedBox(height: 24),

                    // ── ⑦ プラットフォーム別注意書き（審査必須テキスト）
                    if (_isIOS)
                      const AppleDisclaimerSection()
                    else if (_isAndroid)
                      const AndroidDisclaimerSection()
                    else
                      const _WebDisclaimerSection(),

                    const SizedBox(height: 16),

                    // ── ⑧ 利用規約・プライバシーポリシーリンク
                    LegalLinksRow(
                      appleEulaUrl: _isIOS ? _appleEulaUrl : null,
                      privacyPolicyUrl: _privacyPolicyUrl,
                      termsOfServiceUrl: _termsOfServiceUrl,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── ボタンラベル ────────────────────────────────────────────────────────
  String _buildButtonLabel(SubscriptionService sub) {
    if (sub.isLoading) return '読み込み中...';
    // 価格は常に日本円固定（ストアのロケールに左右されない）
    const price = '¥500';
    if (_isIOS)     return '$price / 月 で始める';
    if (_isAndroid) return 'Google Play で $price / 月 を購入';
    return '$price / 月 で始める';
  }

  // ── ヘッダー ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        // アイコン
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5BA4CF).withValues(alpha: 0.5),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Text('📍', style: TextStyle(fontSize: 52)),
          ),
        ),
        const SizedBox(height: 16),

        // タイトル
        const Text(
          'Shot Map',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),

        // サブタイトル
        const Text(
          'すべての機能を月額¥500でご利用いただけます',
          style: TextStyle(
            color: Color(0xFF8BAFCD),
            fontSize: 15,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── エラーバナー ─────────────────────────────────────────────────────────
  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── テスト用スキップボタン（TestFlight / デバッグ専用） ──────────────────
  Widget _buildReviewSkipButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1A2A1A),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: const [
                Icon(Icons.science_outlined,
                    size: 14, color: Color(0xFFFFB74D)),
                SizedBox(width: 6),
                Text(
                  'TestFlight / 審査確認用',
                  style: TextStyle(
                    color: Color(0xFFFFB74D),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _navigateToMain,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
              ),
              child: const Text(
                'サブスクリプションをスキップして続ける',
                style: TextStyle(
                  color: Color(0xFFFFB74D),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 復元ボタン（iOS 必須） ────────────────────────────────────────────────
  Widget _buildRestoreButton(SubscriptionService sub) {
    return Center(
      child: TextButton(
        onPressed: sub.isLoading ? null : _onRestoreTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        ),
        child: const Text(
          '購入を復元する',
          style: TextStyle(
            color: Color(0xFF8BAFCD),
            fontSize: 14,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF8BAFCD),
            decorationThickness: 1.2,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Web 向けシンプルな注意書き（ストア課金なし）
// ────────────────────────────────────────────────────────────────────────────
class _WebDisclaimerSection extends StatelessWidget {
  const _WebDisclaimerSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'サブスクリプションの購入はiOS / Android アプリからご利用ください。',
        style: TextStyle(color: Colors.white54, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}
