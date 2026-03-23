// ────────────────────────────────────────────────────────────────────────────
// PaywallScreen – サブスクリプション購入画面
//
// iOS (StoreKit) / Android (Google Play Billing) 両対応。
// 共通 UI ウィジェットを使用し、プラットフォーム別の表示を切り替えます。
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

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  // ── OS 判定 ────────────────────────────────────────────────────────────
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

  // ────────────────────────────────────────────────────────────────────────
  // ██ プラットフォーム別スタブ関数 ██
  // ────────────────────────────────────────────────────────────────────────

  /// 【スタブ】iOS: App Store からプランを購入する
  /// → SubscriptionService.purchaseSubscription_iOS() に委譲
  Future<void> handleApplePurchase(String productID) async {
    // TODO(iOS): 必要であれば購入前の UI 処理をここに追記
    final sub = context.read<SubscriptionService>();
    await sub.purchaseSubscription_iOS(productID);
  }

  /// 【スタブ】Android: Google Play からプランを購入する
  /// → SubscriptionService.purchaseSubscription_Android() に委譲
  Future<void> handleGooglePurchase(String productID) async {
    // TODO(Android): 必要であれば購入前の UI 処理をここに追記
    final sub = context.read<SubscriptionService>();
    await sub.purchaseSubscription_Android(productID);
  }

  /// 【スタブ】iOS: 購入を復元する（Apple 審査必須）
  Future<void> restorePurchase() async {
    // TODO(iOS): 復元後の追加処理があればここに記述
    final sub = context.read<SubscriptionService>();
    await sub.restorePurchases();
    if (!mounted) return;
    if (sub.isSubscribed) {
      _navigateToMain();
    } else {
      _showSnackBar('復元できる購入が見つかりませんでした。');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _onPurchaseTap() async {
    final productId = SubscriptionService.kProductId;
    if (_isIOS) {
      await handleApplePurchase(productId);
    } else if (_isAndroid) {
      await handleGooglePurchase(productId);
    } else {
      // Web / デスクトップ: 購入不可
      _showSnackBar('このプラットフォームでは購入できません。');
    }
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
  // build
  // ────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, sub, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D1B2A),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 36),

                  // ── ヘッダー（アイコン・タイトル）
                  _buildHeader(),

                  const SizedBox(height: 28),

                  // ── 機能紹介リスト（共通ウィジェット）
                  const FeatureList(),

                  const SizedBox(height: 24),

                  // ── 月額プランカード（共通ウィジェット）
                  PlanCard(storePrice: sub.product?.price),

                  const SizedBox(height: 24),

                  // ── エラーメッセージ
                  if (sub.errorMessage != null)
                    _buildErrorBanner(sub.errorMessage!),

                  // ── 購入ボタン（共通ウィジェット）
                  SubscribeButton(
                    label: _isIOS
                        ? '月額500円でShotMapを始める'
                        : _isAndroid
                            ? 'Google Playで月額500円を購入'
                            : '月額500円でShotMapを始める',
                    onPressed: _onPurchaseTap,
                    isLoading: sub.isLoading,
                  ),

                  // ── iOS のみ: 購入を復元するボタン（Apple 審査必須）
                  if (_isIOS) ...[
                    const SizedBox(height: 10),
                    _buildRestoreButton(sub),
                  ],

                  const SizedBox(height: 20),

                  // ── OS 別注意書き（共通ウィジェット）
                  if (_isIOS)
                    const AppleDisclaimerSection()
                  else
                    const AndroidDisclaimerSection(),

                  const SizedBox(height: 14),

                  // ── 利用規約・プライバシーポリシーリンク（共通ウィジェット）
                  LegalLinksRow(
                    appleEulaUrl: _isIOS ? _appleEulaUrl : null,
                    privacyPolicyUrl: _privacyPolicyUrl,
                    termsOfServiceUrl: _termsOfServiceUrl,
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // ローカルウィジェット（PaywallScreen 固有）
  // ────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        // アプリアイコン風コンテナ
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.35),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Text('📍', style: TextStyle(fontSize: 50)),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Shot Map',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '写真スポット・グルメスポット共有マップ',
          style: TextStyle(color: Colors.white60, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildRestoreButton(SubscriptionService sub) {
    return TextButton(
      onPressed: sub.isLoading ? null : restorePurchase,
      child: const Text(
        '購入を復元する',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 14,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white54,
          decorationThickness: 1,
        ),
      ),
    );
  }
}
