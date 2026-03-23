// ────────────────────────────────────────────────────────────────────────────
// DisclaimerSection – iOS / Android 別の注意書きウィジェット
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── iOS 向け Apple 規定注意書き ────────────────────────────────────────────
class AppleDisclaimerSection extends StatelessWidget {
  const AppleDisclaimerSection({super.key});

  static const _text =
      '• お支払いはApple IDに請求されます。\n'
      '• 現在の購読期間終了の24時間前までに解約しない限り、'
      'サブスクリプションは自動的に更新されます。\n'
      '• 自動更新の金額は購入時と同額（¥500/月）です。\n'
      '• 購読の管理・解約はお使いのデバイスの「設定」→「Apple ID」→'
      '「サブスクリプション」から行えます。\n'
      '• 無料トライアル期間がある場合、期間終了前にキャンセルしなければ'
      '課金が開始されます。';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: const Text(
        _text,
        style: TextStyle(
          color: Colors.white38,
          fontSize: 11,
          height: 1.75,
        ),
      ),
    );
  }
}

// ─── Android 向け Google Play ポリシー準拠注意書き ────────────────────────
class AndroidDisclaimerSection extends StatelessWidget {
  const AndroidDisclaimerSection({super.key});

  static const String _packageId = 'com.shotmap.pins';
  static const String _productId = 'com.shotmap.pins.monthly';

  static const _text =
      '• お支払いはGoogle Playアカウントに請求されます（¥500/月）。\n'
      '• サブスクリプションはいつでもキャンセル可能です。\n'
      '• キャンセルした場合も、現在の購読期間が終了するまでご利用いただけます。\n'
      '• 定期購入の管理・解約はGoogle Playの「定期購入」から行えます。';

  Future<void> _openGooglePlaySubscriptions() async {
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions'
      '?sku=$_productId&package=$_packageId',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: const Text(
            _text,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              height: 1.75,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Google Play 定期購入管理へのリンクボタン
        TextButton.icon(
          onPressed: _openGooglePlaySubscriptions,
          icon: const Icon(
            Icons.open_in_new,
            color: Colors.white38,
            size: 14,
          ),
          label: const Text(
            'Google Play で定期購入を管理する',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ],
    );
  }
}
