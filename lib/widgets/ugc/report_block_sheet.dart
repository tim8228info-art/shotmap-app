// ────────────────────────────────────────────────────────────────────────────
// ReportBlockSheet  – UGC 通報 & ブロック UI
//
// Apple Guideline 2.1 準拠:
//   ✅ ユーザー生成コンテンツの不適切通報機能
//   ✅ 特定ユーザーのブロック機能
//   ✅ 投稿メニュー（3点ドット）から呼び出し可能
//
// 使い方:
//   showReportBlockSheet(context, authorName: 'Yuki', postId: 'pin_001');
// ────────────────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ── 通報カテゴリ ─────────────────────────────────────────────────────────────
enum ReportReason {
  spam('スパム・宣伝目的', Icons.block),
  inappropriate('不適切・わいせつなコンテンツ', Icons.no_adult_content),
  copyright('著作権・肖像権の侵害', Icons.copyright),
  harassment('嫌がらせ・ハラスメント', Icons.report_problem),
  misinformation('虚偽・誤った情報', Icons.fact_check),
  other('その他', Icons.more_horiz);

  final String label;
  final IconData icon;
  const ReportReason(this.label, this.icon);
}

// ────────────────────────────────────────────────────────────────────────────
// エントリーポイント：BottomSheet を表示する
// ────────────────────────────────────────────────────────────────────────────
Future<void> showReportBlockSheet(
  BuildContext context, {
  required String authorName,
  required String postId,
  String? authorId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportBlockSheet(
      authorName: authorName,
      postId: postId,
      authorId: authorId,
    ),
  );
}

// ────────────────────────────────────────────────────────────────────────────
// BottomSheet 本体
// ────────────────────────────────────────────────────────────────────────────
class _ReportBlockSheet extends StatefulWidget {
  final String authorName;
  final String postId;
  final String? authorId;

  const _ReportBlockSheet({
    required this.authorName,
    required this.postId,
    this.authorId,
  });

  @override
  State<_ReportBlockSheet> createState() => _ReportBlockSheetState();
}

class _ReportBlockSheetState extends State<_ReportBlockSheet> {
  // 0 = メニュー, 1 = 通報理由選択, 2 = 完了
  int _step = 0;
  ReportReason? _selectedReason;
  bool _isSubmitting = false;

  // ── 通報送信（実装はバックエンド連携時に置き換え） ───────────────────────
  Future<void> _submitReport() async {
    if (_selectedReason == null) return;
    setState(() => _isSubmitting = true);

    // TODO: バックエンドへの通報送信 API を実装
    if (kDebugMode) {
      debugPrint(
        '[Report] postId=${widget.postId}, reason=${_selectedReason!.name}',
      );
    }
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) setState(() => _step = 2);
  }

  // ── ブロック実行（実装はバックエンド連携時に置き換え） ──────────────────
  Future<void> _blockUser() async {
    if (kDebugMode) {
      debugPrint(
        '[Block] authorId=${widget.authorId ?? widget.authorName}',
      );
    }
    // TODO: ブロック API を実装（SharedPreferences or Firestore）
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.authorName} さんをブロックしました'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: const Color(0xFF424242),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (_step) {
            0 => _buildMenu(),
            1 => _buildReasonList(),
            _ => _buildDone(),
          },
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // ① メインメニュー
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildMenu() {
    return Column(
      key: const ValueKey('menu'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHandle(),
        _buildHeader('このコンテンツについて'),
        const SizedBox(height: 4),
        _buildMenuTile(
          icon: Icons.flag_outlined,
          iconColor: const Color(0xFFE53935),
          label: '不適切なコンテンツを報告する',
          onTap: () => setState(() => _step = 1),
        ),
        const Divider(height: 1, indent: 56),
        _buildMenuTile(
          icon: Icons.person_off_outlined,
          iconColor: const Color(0xFF616161),
          label: '${widget.authorName} さんをブロックする',
          sublabel: 'このユーザーの投稿が表示されなくなります',
          onTap: () => _showBlockConfirmDialog(),
        ),
        const Divider(height: 1, indent: 56),
        _buildMenuTile(
          icon: Icons.close,
          iconColor: const Color(0xFF9E9E9E),
          label: 'キャンセル',
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // ② 通報理由選択
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildReasonList() {
    return Column(
      key: const ValueKey('reasons'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHandle(),
        _buildHeader('通報する理由を選択してください'),
        const SizedBox(height: 4),
        ...ReportReason.values.map((reason) {
          final isSelected = _selectedReason == reason;
          return InkWell(
            onTap: () => setState(() => _selectedReason = reason),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE3F2FD)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1565C0).withValues(alpha: 0.12)
                          : const Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      reason.icon,
                      size: 18,
                      color: isSelected
                          ? const Color(0xFF1565C0)
                          : const Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      reason.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected
                            ? const Color(0xFF1565C0)
                            : const Color(0xFF212121),
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF1565C0),
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // 戻るボタン
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _step = 0;
                    _selectedReason = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF616161),
                    side: const BorderSide(color: Color(0xFFBDBDBD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('戻る'),
                ),
              ),
              const SizedBox(width: 12),
              // 送信ボタン
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: (_selectedReason != null && !_isSubmitting)
                      ? _submitReport
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFEF9A9A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '通報を送信する',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // ③ 送信完了
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildDone() {
    return Padding(
      key: const ValueKey('done'),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF2E7D32),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '通報を受け付けました',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'ご報告ありがとうございます。\n内容を確認の上、適切に対処いたします。\nコミュニティのルールに反するコンテンツは削除される場合があります。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF757575),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: const Text(
                '閉じる',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // ブロック確認ダイアログ
  // ────────────────────────────────────────────────────────────────────────
  Future<void> _showBlockConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('${widget.authorName} さんをブロック'),
        content: Text(
          '${widget.authorName} さんの投稿がマップやトレンドに表示されなくなります。\n\nこの操作は設定から解除できます。',
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: Color(0xFF9E9E9E)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'ブロックする',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await _blockUser();
  }

  // ────────────────────────────────────────────────────────────────────────
  // 共通 UI パーツ
  // ────────────────────────────────────────────────────────────────────────
  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFBDBDBD),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF212121),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    String? sublabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212121),
                    ),
                  ),
                  if (sublabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sublabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (label != 'キャンセル')
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFBDBDBD),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
