import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/data_models.dart';
import '../models/user_profile_provider.dart';

// ═══════════════════════════════════════════════════════════════
// UserProfileScreen  ―  他ユーザーのプロフィール画面
// トレンドのID検索からタップすると表示される
// ═══════════════════════════════════════════════════════════════
class UserProfileScreen extends StatefulWidget {
  final AppUser user;
  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Consumer<UserProfileProvider>(
        builder: (context, provider, _) {
          final isFollowing = provider.isFollowing(u.uid);
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                // ── ヘッダー ──
                _buildHeader(context, u, provider, isFollowing, topPadding),
                // ── タブバー ──
                _buildTabBar(),
                // ── コンテンツ ──
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStatsTab(u),
                      _buildPinsTab(u),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════
  // ヘッダー
  // ════════════════════════════════════════════
  Widget _buildHeader(BuildContext context, AppUser u,
      UserProfileProvider provider, bool isFollowing, double topPadding) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7BBFE0), Color(0xFF5BA4CF), Color(0xFF2E7CB8)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 20),
        child: Column(
          children: [
            // 戻るボタン行
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 16, color: Colors.white),
                  ),
                ),
                const Spacer(),
                Text(
                  '@${u.customId}',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 36), // バランス用
              ],
            ),
            const SizedBox(height: 16),
            // アバター + 名前 + フォローボタン
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // アバター
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      u.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryLight,
                        child: const Icon(Icons.person, color: Colors.white, size: 38),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // 名前・bio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.name,
                        style: GoogleFonts.notoSansJp(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        u.bio,
                        style: GoogleFonts.notoSansJp(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // フォローボタン
                GestureDetector(
                  onTap: () {
                    provider.toggleFollow(u.uid);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        isFollowing
                            ? '@${u.customId} のフォローを解除しました'
                            : '@${u.customId} をフォローしました',
                        style: GoogleFonts.notoSansJp(fontSize: 13),
                      ),
                      backgroundColor: isFollowing
                          ? AppColors.textSecondary
                          : AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    ));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: isFollowing
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: isFollowing
                          ? Border.all(color: Colors.white.withValues(alpha: 0.6))
                          : null,
                    ),
                    child: Text(
                      isFollowing ? 'フォロー中' : 'フォローする',
                      style: GoogleFonts.notoSansJp(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isFollowing ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // フォロワー・フォロー中・スポット数
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _headerStat('${u.pinCount}', 'スポット'),
                _divider(),
                _headerStat('${u.followerCount}', 'フォロワー'),
                _divider(),
                _headerStat('${u.followingCount}', 'フォロー中'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label,
            style: GoogleFonts.notoSansJp(
                fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.3));
  }

  // ════════════════════════════════════════════
  // タブバー
  // ════════════════════════════════════════════
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        labelStyle: GoogleFonts.notoSansJp(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.notoSansJp(fontWeight: FontWeight.w400, fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.person_outline, size: 17), text: 'プロフィール'),
          Tab(icon: Icon(Icons.location_on_outlined, size: 17), text: 'スポット'),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  // タブ① ： 統計・情報
  // ════════════════════════════════════════════
  Widget _buildStatsTab(AppUser u) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        // 実績カード
        Container(
          margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(Icons.bar_chart, 'アクティビティ'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _statTile(
                      icon: Icons.location_on,
                      iconColor: AppColors.primary,
                      bgColor: AppColors.tagBlue,
                      value: '${u.pinCount}',
                      label: '投稿スポット',
                      suffix: '個',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statTile(
                      icon: Icons.people,
                      iconColor: const Color(0xFF5BA4CF),
                      bgColor: AppColors.tagBlue,
                      value: '${u.followerCount}',
                      label: 'フォロワー',
                      suffix: '人',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statTile(
                      icon: Icons.person_add,
                      iconColor: AppColors.accent,
                      bgColor: AppColors.tagPink,
                      value: '${u.followingCount}',
                      label: 'フォロー中',
                      suffix: '人',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statTile(
                      icon: Icons.favorite,
                      iconColor: const Color(0xFFFFAA00),
                      bgColor: const Color(0xFFFFF8E1),
                      value: '−',
                      label: 'いいね',
                      suffix: '件',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // 自己紹介カード
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(Icons.info_outline, '自己紹介'),
              const SizedBox(height: 12),
              Text(
                u.bio.isEmpty ? '自己紹介はまだありません' : u.bio,
                style: GoogleFonts.notoSansJp(
                  fontSize: 14,
                  color: u.bio.isEmpty ? AppColors.textHint : AppColors.textPrimary,
                  height: 1.7,
                  fontStyle: u.bio.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
        // SNSリンクカード（1つでも設定があれば表示）
        if (u.instagramUrl.isNotEmpty ||
            u.youtubeUrl.isNotEmpty ||
            u.xUrl.isNotEmpty ||
            u.tiktokUrl.isNotEmpty)
          _buildSnsCard(u),
      ],
    );
  }

  // ════════════════════════════════════════════
  // SNSリンクカード（マイページと同じデザイン）
  // ════════════════════════════════════════════
  static const List<_SnsConfig> _snsMeta = [
    _SnsConfig(
      key: 'instagram', platform: 'Instagram', icon: Icons.camera_alt,
      gradient: LinearGradient(colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)]),
      shadowColor: Color(0xFFDD2A7B),
    ),
    _SnsConfig(
      key: 'youtube', platform: 'YouTube', icon: Icons.play_circle_fill,
      gradient: LinearGradient(colors: [Color(0xFFFF0000), Color(0xFFCC0000)]),
      shadowColor: Color(0xFFFF0000),
    ),
    _SnsConfig(
      key: 'x', platform: 'X', icon: Icons.close,
      gradient: LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF444444)]),
      shadowColor: Color(0xFF1A1A1A),
    ),
    _SnsConfig(
      key: 'tiktok', platform: 'TikTok', icon: Icons.music_note,
      gradient: LinearGradient(colors: [Color(0xFF010101), Color(0xFF69C9D0)]),
      shadowColor: Color(0xFF010101),
    ),
  ];

  String _urlFor(AppUser u, String key) {
    switch (key) {
      case 'instagram': return u.instagramUrl;
      case 'youtube':   return u.youtubeUrl;
      case 'x':         return u.xUrl;
      case 'tiktok':    return u.tiktokUrl;
      default:          return '';
    }
  }

  Future<void> _launchSns(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('URLを開けませんでした', style: GoogleFonts.notoSansJp()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Widget _buildSnsCard(AppUser u) {
    // URL が設定されているものだけ抽出
    final activeSns = _snsMeta.where((m) => _urlFor(u, m.key).isNotEmpty).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle(Icons.link, 'SNSリンク'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tagBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${activeSns.length}件登録',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 設定済みSNSのみ表示（1列 or 2列グリッド）
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3.0,
            children: activeSns.map((meta) {
              final url = _urlFor(u, meta.key);
              return GestureDetector(
                onTap: () => _launchSns(context, url),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: meta.gradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: meta.shadowColor.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(meta.icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(meta.platform,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text('タップして開く',
                                style: GoogleFonts.notoSansJp(
                                    fontSize: 9, color: Colors.white.withValues(alpha: 0.75))),
                          ],
                        ),
                      ),
                      Icon(Icons.open_in_new,
                          size: 12, color: Colors.white.withValues(alpha: 0.75)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String value,
    required String label,
    required String suffix,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: value,
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              TextSpan(
                text: suffix,
                style: GoogleFonts.notoSansJp(
                    fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ]),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.notoSansJp(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  // タブ② ： スポット（ダミー表示）
  // ════════════════════════════════════════════
  Widget _buildPinsTab(AppUser u) {
    if (u.pinCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(
                    color: AppColors.primaryVeryLight, shape: BoxShape.circle),
                child: const Icon(Icons.location_off_outlined,
                    size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text('まだスポットがありません',
                  style: GoogleFonts.notoSansJp(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('このユーザーはまだスポットを\n投稿していません',
                  style: GoogleFonts.notoSansJp(
                      fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    // ダミーのスポットグリッドを表示
    final spots = SampleData.pins.take(u.pinCount.clamp(0, SampleData.pins.length)).toList();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: spots.length,
      itemBuilder: (context, index) {
        final pin = spots[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                pin.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.tagBlue,
                  child: const Icon(Icons.image, color: AppColors.primary),
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                  child: Text(
                    pin.title,
                    style: const TextStyle(
                        fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════
  // ヘルパー
  // ════════════════════════════════════════════
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 12, offset: const Offset(0, 3)),
      ],
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 6),
        Text(title,
            style: GoogleFonts.notoSansJp(
                fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}

// ════════════════════════════════════════════
// SNS設定メタデータクラス
// ════════════════════════════════════════════
class _SnsConfig {
  final String key;
  final String platform;
  final IconData icon;
  final LinearGradient gradient;
  final Color shadowColor;

  const _SnsConfig({
    required this.key,
    required this.platform,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
  });
}
