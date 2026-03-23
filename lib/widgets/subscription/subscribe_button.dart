// ────────────────────────────────────────────────────────────────────────────
// SubscribeButton – 購入ボタン（iOS / Android 共通）
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SubscribeButton extends StatelessWidget {
  /// ボタンに表示するラベル
  final String label;

  /// タップ時のコールバック（null = 無効化）
  final VoidCallback? onPressed;

  /// ローディング中フラグ
  final bool isLoading;

  const SubscribeButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1565C0),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const CupertinoActivityIndicator(color: Color(0xFF1565C0))
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
