// ────────────────────────────────────────────────────────────────────────────
// PlanCard  v4.0 – 月額料金表示カード
//
// Guideline 3.1.2 完全準拠:
//   ✅ 価格を明示：ストア取得価格 or フォールバック「¥500」
//   ✅ 期間を明示：「1ヶ月ごとに自動更新」
//   ✅ プラン選択制ではなく、通常利用の月額料金として表示
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class PlanCard extends StatelessWidget {
  /// ストアから取得した価格文字列（例: "¥500"）。nullの場合フォールバック表示
  final String? storePrice;
  final bool isSelected;

  const PlanCard({
    super.key,
    this.storePrice,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final priceText = storePrice ?? '¥500';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── ① 月額利用料金ラベル ─────────────────────────────────────
            Text(
              '月額利用料金',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 8),

            // ── ② 価格（大きく表示） ──────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  priceText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    '/ 月（税込）',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: 14),

            // ── ③ 更新・キャンセルバッジ ──────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _badge(Icons.autorenew, '1ヶ月ごとに自動更新'),
                _badge(Icons.cancel_outlined, 'いつでもキャンセル可'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
