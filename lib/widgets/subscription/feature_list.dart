// ────────────────────────────────────────────────────────────────────────────
// FeatureList – Shot Map 機能紹介リスト（iOS / Android 共通）
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class FeatureListItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const FeatureListItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

class FeatureList extends StatelessWidget {
  static const _items = [
    FeatureListItem(
      icon: Icons.map_rounded,
      iconColor: Color(0xFF42A5F5),
      title: 'スポット無制限保存',
      subtitle: 'お気に入りの場所をいくつでも記録',
    ),
    FeatureListItem(
      icon: Icons.photo_camera_rounded,
      iconColor: Color(0xFFEC407A),
      title: '写真付きで投稿・共有',
      subtitle: '風景・グルメ写真をマップに投稿',
    ),
    FeatureListItem(
      icon: Icons.trending_up_rounded,
      iconColor: Color(0xFF66BB6A),
      title: 'トレンドスポット発見',
      subtitle: '世界中のユーザーの投稿をチェック',
    ),
    FeatureListItem(
      icon: Icons.share_rounded,
      iconColor: Color(0xFFFFA726),
      title: 'SNS 共有機能',
      subtitle: 'Instagram・X で友達にシェア',
    ),
  ];

  const FeatureList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: _items
            .map((item) => _FeatureRow(item: item))
            .toList(),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final FeatureListItem item;

  const _FeatureRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          // アイコン背景
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),
          const SizedBox(width: 14),

          // テキスト部
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8BAFCD),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // チェックマーク
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF4CAF50),
            size: 20,
          ),
        ],
      ),
    );
  }
}
