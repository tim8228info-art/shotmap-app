// ────────────────────────────────────────────────────────────────────────────
// LegalLinksRow – 利用規約・プライバシーポリシーリンク行（iOS / Android 共通）
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalLinksRow extends StatelessWidget {
  /// Apple EULA URL（iOS 固有。null の場合はリンクを非表示）
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
      spacing: 0,
      runSpacing: 4,
      children: [
        // ── Apple EULA（iOS のみ） ─────────────────────────────────────────
        if (appleEulaUrl != null) ...[
          _LegalLink(
            label: '利用規約 (EULA)',
            onTap: () => _open(appleEulaUrl!),
          ),
          _Separator(),
        ],

        // ── プライバシーポリシー ─────────────────────────────────────────────
        _LegalLink(
          label: 'プライバシーポリシー',
          onTap: () => _open(privacyPolicyUrl),
        ),
        _Separator(),

        // ── Shot Map 独自利用規約 ────────────────────────────────────────────
        _LegalLink(
          label: 'Shot Map 利用規約',
          onTap: () => _open(termsOfServiceUrl),
        ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LegalLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF607D8B),
            fontSize: 11,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF607D8B),
          ),
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      '·',
      style: TextStyle(color: Color(0xFF37474F), fontSize: 12),
    );
  }
}
