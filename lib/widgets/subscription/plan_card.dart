// ────────────────────────────────────────────────────────────────────────────
// PlanCard – 月額プラン表示カード（iOS / Android 共通）
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class PlanCard extends StatelessWidget {
  /// App Store / Google Play から取得した価格文字列（例: "¥500"）
  /// null の場合はフォールバック文字列を使用
  final String? storePrice;

  /// 購読中かどうか（購読済み UI 切り替え用）
  final bool isSelected;

  const PlanCard({
    super.key,
    this.storePrice,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? Border.all(color: Colors.white, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // バッジ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'スタンダードプラン',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 「月額」ラベル
          const Text(
            '月額',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 4),

          // 価格（ストアから取得した値を優先）
          Text(
            storePrice ?? '¥500',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const Text(
            '（税込）',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 10),

          // キャンセル案内
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.white70, size: 15),
              SizedBox(width: 5),
              Text(
                'いつでもキャンセル可能',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
