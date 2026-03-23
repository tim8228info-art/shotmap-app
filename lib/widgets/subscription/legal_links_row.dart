// ────────────────────────────────────────────────────────────────────────────
// LegalLinksRow – 利用規約・プライバシーポリシーリンク行（iOS / Android 共通）
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalLinksRow extends StatelessWidget {
  /// Apple EULA URL（iOS 固有。null の場合は汎用 URL を使用）
  final String? appleEulaUrl;

  /// プライバシーポリシー URL
  final String privacyPolicyUrl;

  /// 利用規約 URL
  final String termsOfServiceUrl;

  const LegalLinksRow({
    super.key,
    this.appleEulaUrl,
    required this.privacyPolicyUrl,
    required this.termsOfServiceUrl,
  });

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 利用規約
        TextButton(
          onPressed: () => _open(
            appleEulaUrl ??
                'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '利用規約 (EULA)',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ),
        const Text(
          '・',
          style: TextStyle(color: Colors.white30, fontSize: 12),
        ),
        // プライバシーポリシー
        TextButton(
          onPressed: () => _open(privacyPolicyUrl),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'プライバシーポリシー',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ),
        const Text(
          '・',
          style: TextStyle(color: Colors.white30, fontSize: 12),
        ),
        // 別途利用規約（Shot Map 独自）
        TextButton(
          onPressed: () => _open(termsOfServiceUrl),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Shot Map 利用規約',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
