// ────────────────────────────────────────────────────────────────────────────
// DisclaimerSection – プラットフォーム別注意書き  v3.0
//
// Guideline 3.1.2 完全準拠:
//   ✅ プラン名（タイトル）を明示
//   ✅ 期間（1ヶ月）を明示
//   ✅ 価格（¥500）を明示
//   ✅ Apple EULA リンク（iOS）
//   ✅ プライバシーポリシーリンク
//   ✅ 自動更新の明確な説明文
//   ✅ キャンセル方法・更新タイミングを明示
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ────────────────────────────────────────────────────────────────────────────
// iOS – Apple 審査必須テキスト（Guideline 3.1.2 完全準拠）
// ────────────────────────────────────────────────────────────────────────────
class AppleDisclaimerSection extends StatelessWidget {
  const AppleDisclaimerSection({super.key});

  static const _privacyUrl =
      'https://tim8228info-art.github.io/shotmap-support/';
  static const _eulaUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── サブスクリプション概要（Guideline 3.1.2 必須） ──────────────
          _sectionTitle('サブスクリプション内容'),
          const SizedBox(height: 8),
          _infoRow(Icons.star_rounded, const Color(0xFFFFD54F),
              'プラン名', 'Shot Map スタンダードプラン'),
          const SizedBox(height: 6),
          _infoRow(Icons.calendar_month, const Color(0xFF64B5F6),
              '期間', '1ヶ月（自動更新）'),
          const SizedBox(height: 6),
          _infoRow(Icons.payments_outlined, const Color(0xFF81C784),
              '価格', '¥500 / 月（税込）'),

          const SizedBox(height: 14),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          const SizedBox(height: 12),

          // ── 自動更新・請求に関する詳細説明 ───────────────────────────────
          _sectionTitle('お支払い・自動更新について'),
          const SizedBox(height: 8),
          _bulletText(
            '料金はご確認・購入後にApple IDアカウントに請求されます。',
          ),
          const SizedBox(height: 5),
          _bulletText(
            'サブスクリプションは、現在の契約期間が終了する24時間以上前にキャンセルしない限り、自動的に更新されます。',
          ),
          const SizedBox(height: 5),
          _bulletText(
            '更新料金は、現在の期間終了の24時間前以内に請求されます。',
          ),
          const SizedBox(height: 5),
          _bulletText(
            '購入後は「設定」→「Apple ID」→「サブスクリプション」から管理・キャンセルができます。',
          ),
          const SizedBox(height: 5),
          _bulletText(
            '無料トライアル期間がある場合、残っている無料期間はキャンセル時に失われます。',
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          const SizedBox(height: 12),

          // ── 利用規約・プライバシーポリシーリンク（審査必須） ─────────────
          _sectionTitle('利用規約・プライバシーポリシー'),
          const SizedBox(height: 8),
          Row(
            children: [
              _linkButton('Apple 利用規約 (EULA)', _eulaUrl),
              const SizedBox(width: 8),
              _linkButton('プライバシーポリシー', _privacyUrl),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFBBDEFB),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _infoRow(IconData icon, Color iconColor, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Text(
          '$label：',
          style: const TextStyle(
            color: Color(0xFF8BAFCD),
            fontSize: 11.5,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bulletText(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: CircleAvatar(
            radius: 2,
            backgroundColor: Color(0xFF5B8DB8),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF8BAFCD),
              fontSize: 11,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }

  Widget _linkButton(String label, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF90CAF9),
            fontSize: 10.5,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF90CAF9),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Android – Google Play ポリシー必須テキスト（Guideline 準拠）
// ────────────────────────────────────────────────────────────────────────────
class AndroidDisclaimerSection extends StatelessWidget {
  static const _packageId  = 'com.shotmap.pins';
  static const _productId  = 'com.shotmap.pins.monthly';
  static const _manageUrl  =
      'https://play.google.com/store/account/subscriptions'
      '?sku=$_productId&package=$_packageId';
  static const _privacyUrl =
      'https://tim8228info-art.github.io/shotmap-support/';

  const AndroidDisclaimerSection({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── サブスクリプション概要（Guideline 3.1.2 必須） ──────────────
          _sectionTitle('サブスクリプション内容'),
          const SizedBox(height: 8),
          _infoRow(Icons.star_rounded, const Color(0xFFFFD54F),
              'プラン名', 'Shot Map スタンダードプラン'),
          const SizedBox(height: 6),
          _infoRow(Icons.calendar_month, const Color(0xFF64B5F6),
              '期間', '1ヶ月（自動更新）'),
          const SizedBox(height: 6),
          _infoRow(Icons.payments_outlined, const Color(0xFF81C784),
              '価格', '¥500 / 月（税込）'),

          const SizedBox(height: 14),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          const SizedBox(height: 12),

          // ── 自動更新・キャンセル説明 ─────────────────────────────────────
          _sectionTitle('お支払い・キャンセルについて'),
          const SizedBox(height: 8),
          _bulletText(
            'Google Play アカウントに月額 ¥500（税込）が請求されます。',
          ),
          const SizedBox(height: 5),
          _bulletText(
            'サブスクリプションは毎月自動で更新されます。',
          ),
          const SizedBox(height: 5),
          _bulletText(
            'いつでもキャンセルできます。キャンセルは現在の請求期間終了まで有効です。',
          ),
          const SizedBox(height: 5),
          _bulletText(
            'Google Play のサブスクリプション管理ページからキャンセルできます。',
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          const SizedBox(height: 12),

          // ── Google Play 管理ボタン ──────────────────────────────────────
          Center(
            child: OutlinedButton.icon(
              onPressed: () => _openUrl(_manageUrl),
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Google Play でサブスクリプションを管理する'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8BAFCD),
                side: const BorderSide(color: Color(0xFF8BAFCD), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontSize: 11),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0x1AFFFFFF), height: 1),
          const SizedBox(height: 10),

          // ── プライバシーポリシーリンク ──────────────────────────────────
          _sectionTitle('利用規約・プライバシーポリシー'),
          const SizedBox(height: 8),
          _linkButton('プライバシーポリシー・利用規約', _privacyUrl),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFBBDEFB),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _infoRow(IconData icon, Color iconColor, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Text(
          '$label：',
          style: const TextStyle(
            color: Color(0xFF8BAFCD),
            fontSize: 11.5,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bulletText(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: CircleAvatar(
            radius: 2,
            backgroundColor: Color(0xFF5B8DB8),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF8BAFCD),
              fontSize: 11,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }

  Widget _linkButton(String label, String url) {
    return GestureDetector(
      onTap: () => _openUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF90CAF9),
            fontSize: 10.5,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF90CAF9),
          ),
        ),
      ),
    );
  }
}
