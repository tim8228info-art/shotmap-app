import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/subscription_service.dart';
import '../main_shell.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // サブスク購入完了を監視してメイン画面へ遷移
    final sub = context.watch<SubscriptionService>();
    if (sub.isSubscribed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const MainShell(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, sub, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D1B2A),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // アイコン
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('📍', style: TextStyle(fontSize: 52)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // タイトル
                    const Text(
                      'Shot Map',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      '写真スポット・グルメスポット共有マップ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // 機能一覧
                    _FeatureRow(
                      icon: Icons.map_outlined,
                      title: '無制限スポット登録',
                      subtitle: 'お気に入りの場所をいくつでも保存',
                    ),
                    _FeatureRow(
                      icon: Icons.photo_camera_outlined,
                      title: '写真付きで共有',
                      subtitle: '風景・グルメ写真をマップに投稿',
                    ),
                    _FeatureRow(
                      icon: Icons.explore_outlined,
                      title: 'トレンドスポット発見',
                      subtitle: '世界中のユーザーの投稿をチェック',
                    ),
                    _FeatureRow(
                      icon: Icons.share_outlined,
                      title: 'SNS共有',
                      subtitle: 'Instagram・Xで友達にシェア',
                    ),

                    const SizedBox(height: 40),

                    // 価格ボックス
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '月額',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sub.product?.price ?? '¥500',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            '（税込）',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'いつでもキャンセル可能',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // エラーメッセージ
                    if (sub.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          sub.errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // 購入ボタン
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: sub.isLoading
                            ? null
                            : () async {
                                await sub.subscribe();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1565C0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: sub.isLoading
                            ? const CupertinoActivityIndicator()
                            : const Text(
                                'サブスクリプションを開始する',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 復元ボタン
                    TextButton(
                      onPressed: sub.isLoading
                          ? null
                          : () async {
                              await sub.restore();
                              if (sub.isSubscribed && context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                      child: const Text(
                        '購入を復元する',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 15,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white54,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 利用規約・プライバシーポリシー
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            _showTerms(context);
                          },
                          child: const Text(
                            '利用規約',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Text(
                          '・',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        TextButton(
                          onPressed: () {
                            _showPrivacy(context);
                          },
                          child: const Text(
                            'プライバシーポリシー',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 注記
                    const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Text(
                        '・お支払いはApple IDに請求されます\n'
                        '・サブスクリプションは期間終了の24時間前までにキャンセルしない限り自動更新されます\n'
                        '・購入後はアカウント設定からキャンセルできます',
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 11,
                          height: 1.7,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ignore: unused_element
  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('利用規約'),
        content: const SingleChildScrollView(
          child: Text(
            'Shot Mapのご利用には月額サブスクリプションが必要です。\n\n'
            '・料金：月額500円（税込）\n'
            '・お支払い：Apple IDに請求\n'
            '・自動更新：期間終了24時間前までにキャンセルしない限り自動更新\n'
            '・キャンセル：iOSの設定 > Apple ID > サブスクリプションから可能\n\n'
            '本サービスはAppleのApp Storeを通じて提供されます。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('プライバシーポリシー'),
        content: const SingleChildScrollView(
          child: Text(
            '本アプリは以下の情報を収集・利用します。\n\n'
            '・位置情報：スポット登録・マップ表示のため\n'
            '・写真：スポット投稿のため\n'
            '・ユーザー情報：アカウント管理のため\n\n'
            '収集した情報は第三者に提供しません。\n\n'
            '詳細：https://tim8228info-art.github.io/shotmap-support/',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
        ],
      ),
    );
  }
}
