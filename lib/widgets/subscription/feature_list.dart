// ────────────────────────────────────────────────────────────────────────────
// FeatureList – 機能紹介リスト（iOS / Android 共通）
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class FeatureListItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const FeatureListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

/// Shot Map の機能紹介リスト
class FeatureList extends StatelessWidget {
  static const _items = [
    FeatureListItem(
      icon: Icons.map_outlined,
      title: 'スポット無制限保存',
      subtitle: 'お気に入りの場所をいくつでも記録',
    ),
    FeatureListItem(
      icon: Icons.photo_camera_outlined,
      title: '写真付きで投稿・共有',
      subtitle: '風景・グルメ写真をマップに投稿',
    ),
    FeatureListItem(
      icon: Icons.explore_outlined,
      title: 'トレンドスポット発見',
      subtitle: '世界中のユーザーの投稿をチェック',
    ),
    FeatureListItem(
      icon: Icons.share_outlined,
      title: 'SNS共有機能',
      subtitle: 'Instagram・Xで友達にシェア',
    ),
  ];

  const FeatureList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
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
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
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
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
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
