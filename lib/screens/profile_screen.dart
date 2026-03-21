import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/data_models.dart';
import '../models/user_profile_provider.dart';
import 'edit_profile_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

// ═══════════════════════════════════════════════════════════════
// ProfileScreen  ―  マイページ
// ═══════════════════════════════════════════════════════════════
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<_SnsConfig> _snsMeta = [
    _SnsConfig(
      key: 'instagram',
      platform: 'Instagram',
      icon: Icons.camera_alt,
      gradient: LinearGradient(
          colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)]),
      shadowColor: Color(0xFFDD2A7B),
    ),
    _SnsConfig(
      key: 'youtube',
      platform: 'YouTube',
      icon: Icons.play_circle_fill,
      gradient: LinearGradient(colors: [Color(0xFFFF0000), Color(0xFFCC0000)]),
      shadowColor: Color(0xFFFF0000),
    ),
    _SnsConfig(
      key: 'x',
      platform: 'X',
      icon: Icons.close,
      gradient: LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF444444)]),
      shadowColor: Color(0xFF1A1A1A),
    ),
    _SnsConfig(
      key: 'tiktok',
      platform: 'TikTok',
      icon: Icons.music_note,
      gradient: LinearGradient(colors: [Color(0xFF010101), Color(0xFF69C9D0)]),
      shadowColor: Color(0xFF010101),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _urlFor(UserProfileProvider p, String key) {
    switch (key) {
      case 'instagram': return p.instagramUrl;
      case 'youtube':   return p.youtubeUrl;
      case 'x':         return p.xUrl;
      case 'tiktok':    return p.tiktokUrl;
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

  void _openEditScreen(BuildContext context) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const EditProfileScreen(),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }

  // ────────────────────────────────────────────
  // build
  // ── iOS/Android 両対応: AnnotatedRegion + Scaffold
  // ── iOS TestFlight グレーフラッシュ対策:
  //    ① Scaffold.backgroundColor をヘッダーと同じ青に設定
  //    ② body を Column で包み最上部からグラデーションが見えるようにする
  // ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark, // iOS用
      ),
      child: Consumer<UserProfileProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            // ① ヘッダーグラデーションのトップカラーと同じ色にすることで
            //    IndexedStack初回描画時のグレーフラッシュを防ぐ
            backgroundColor: const Color(0xFFB3D9F2),
            body: Column(
              children: [
                // ── ヘッダー：ステータスバー高さを含む ──
                _buildHeader(context, provider),
                // ── タブバー ──
                ColoredBox(
                  color: AppColors.background,
                  child: _buildTabBar(),
                ),
                // ── コンテンツ ──
                Expanded(
                  child: ColoredBox(
                    color: AppColors.background,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProfileTab(context, provider),
                        _buildSavedTab(provider),
                        _buildFollowTab(context, provider, isOwnProfile: true),
                      ],
                    ),
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
  // MediaQuery.of(context).padding.top でステータスバー高さを取得して埋める
  // ════════════════════════════════════════════
  Widget _buildHeader(BuildContext context, UserProfileProvider provider) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB3D9F2), Color(0xFF7BBFE0), Color(0xFF5BA4CF)],
        ),
      ),
      child: Padding(
        // topにステータスバー高さを加算することで、グレー帯が出なくなる
        padding: EdgeInsets.fromLTRB(20, topPadding + 12, 16, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // アバター
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  provider.avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primaryLight,
                    child: const Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // 名前・ID・bio・編集ボタン
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.name,
                          style: GoogleFonts.notoSansJp(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openEditScreen(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_outlined,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  if (provider.customId.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '@${provider.customId}',
                        style: GoogleFonts.notoSansJp(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    provider.bio.isEmpty ? 'タップして紹介文を追加しよう' : provider.bio,
                    style: GoogleFonts.notoSansJp(
                      fontSize: 12,
                      color: provider.bio.isEmpty
                          ? Colors.white.withValues(alpha: 0.55)
                          : Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                      fontStyle: provider.bio.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _openEditScreen(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_outlined, size: 13, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            'プロフィール編集',
                            style: GoogleFonts.notoSansJp(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
        labelStyle: GoogleFonts.notoSansJp(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.notoSansJp(fontWeight: FontWeight.w400, fontSize: 12),
        tabs: const [
          Tab(icon: Icon(Icons.person_outline, size: 17), text: 'プロフィール'),
          Tab(icon: Icon(Icons.bookmark_outline, size: 17), text: '保存済み'),
          Tab(icon: Icon(Icons.people_outline, size: 17), text: 'フォロー'),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  // タブ① ： プロフィール
  // ════════════════════════════════════════════
  Widget _buildProfileTab(BuildContext context, UserProfileProvider provider) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        _buildStatsSection(provider),
        _buildSnsSection(context, provider),
        _buildLegalSection(context),
      ],
    );
  }

  // ── 実績カード（ランクバナーを削除済み） ──
  Widget _buildStatsSection(UserProfileProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.bar_chart, 'あなたの実績'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statItem(
                  icon: Icons.location_on,
                  iconColor: AppColors.primary,
                  bgColor: AppColors.tagBlue,
                  value: '${provider.pinCount}',
                  label: '立てたピン数',
                  suffix: '個',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statItem(
                  icon: Icons.favorite,
                  iconColor: AppColors.accent,
                  bgColor: AppColors.tagPink,
                  value: '${provider.likeCount}',
                  label: '行きたい！',
                  suffix: '件',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statItem(
                  icon: Icons.bookmark,
                  iconColor: const Color(0xFFFFAA00),
                  bgColor: const Color(0xFFFFF8E1),
                  value: '${provider.savedSpots.length}',
                  label: '保存済みスポット',
                  suffix: '件',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statItem(
                  icon: Icons.people,
                  iconColor: const Color(0xFF5BA4CF),
                  bgColor: AppColors.tagBlue,
                  value: '${provider.followingCount}',
                  label: 'フォロー中',
                  suffix: '人',
                ),
              ),
            ],
          ),
          // ランクバナーは削除
        ],
      ),
    );
  }

  Widget _statItem({
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
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: suffix,
                style: GoogleFonts.notoSansJp(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.notoSansJp(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ── SNS セクション ──
  Widget _buildSnsSection(BuildContext context, UserProfileProvider provider) {
    final anySet = _snsMeta.any((m) => _urlFor(provider, m.key).isNotEmpty);
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
                    color: AppColors.tagBlue, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'あなたの名刺として活用',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3.0,
            children: _snsMeta.map((meta) {
              final url = _urlFor(provider, meta.key);
              return _snsButton(context, meta, url);
            }).toList(),
          ),
          if (!anySet) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => _openEditScreen(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryVeryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_link, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'プロフィール編集でSNSを登録しよう',
                      style: GoogleFonts.notoSansJp(
                        fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _snsButton(BuildContext context, _SnsConfig meta, String url) {
    final hasUrl = url.isNotEmpty;
    return GestureDetector(
      onTap: () {
        if (hasUrl) {
          _launchSns(context, url);
        } else {
          _openEditScreen(context);
        }
      },
      child: AnimatedOpacity(
        opacity: hasUrl ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: meta.gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: hasUrl
                ? [BoxShadow(color: meta.shadowColor.withValues(alpha: 0.28), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
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
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text(hasUrl ? 'タップして開く' : '未設定',
                        style: GoogleFonts.notoSansJp(fontSize: 9, color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ),
              Icon(hasUrl ? Icons.open_in_new : Icons.add,
                  size: 12, color: Colors.white.withValues(alpha: 0.75)),
            ],
          ),
        ),
      ),
    );
  }

  // ── 利用規約・プライバシーポリシー ──
  Widget _buildLegalSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F0F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.textHint),
                const SizedBox(width: 6),
                Text('アプリについて',
                    style: GoogleFonts.notoSansJp(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 0.5)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF3F6)),
          _legalListTile(
            context: context,
            icon: Icons.gavel,
            iconColor: AppColors.primary,
            title: '利用規約',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsScreen())),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFEEF3F6)),
          _legalListTile(
            context: context,
            icon: Icons.privacy_tip_outlined,
            iconColor: const Color(0xFF00897B),
            title: 'プライバシーポリシー',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyScreen())),
          ),
        ],
      ),
    );
  }

  Widget _legalListTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.notoSansJp(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // タブ② ： 保存済みスポット
  // ════════════════════════════════════════════
  Widget _buildSavedTab(UserProfileProvider provider) {
    final saved = List<SavedSpot>.from(provider.savedSpots)
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    if (saved.isEmpty) {
      return _emptyState(
        icon: Icons.bookmark_outline,
        title: '保存済みスポットはありません',
        subtitle: 'マップやトレンドのスポットを\n保存するとここに表示されます',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      itemCount: saved.length,
      itemBuilder: (_, i) => _savedCard(saved[i], provider),
    );
  }

  Widget _savedCard(SavedSpot spot, UserProfileProvider provider) {
    final isPin = spot.type == SavedSpotType.pin;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), bottomLeft: Radius.circular(20),
            ),
            child: Image.network(
              spot.imageUrl, width: 90, height: 90, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90, height: 90, color: AppColors.primaryVeryLight,
                child: const Icon(Icons.image, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPin ? AppColors.tagBlue : const Color(0xFFFFF0E6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPin ? '📍 マップ' : '🔥 トレンド',
                          style: GoogleFonts.notoSansJp(
                            fontSize: 10,
                            color: isPin ? AppColors.primary : const Color(0xFFD4915A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(spot.prefecture,
                          style: GoogleFonts.notoSansJp(fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(spot.title,
                      style: GoogleFonts.notoSansJp(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: spot.tags.take(2).map((tag) {
                      return Text(tag,
                          style: GoogleFonts.notoSansJp(
                              fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600));
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                if (isPin) { provider.unsavePin(spot.id); } else { provider.unsaveTrend(spot.id); }
              },
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: const Icon(Icons.bookmark, size: 17, color: Color(0xFFFFAA00)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  // タブ③ ： フォロー管理
  // ════════════════════════════════════════════
  Widget _buildFollowTab(BuildContext context, UserProfileProvider provider, {bool isOwnProfile = false}) {
    if (!isOwnProfile && provider.hideFollowing) return _followHiddenBlock();
    final following = provider.followingUsers;
    if (following.isEmpty) {
      return _emptyState(
        icon: Icons.people_outline,
        title: 'フォロー中のユーザーはいません',
        subtitle: 'トレンドの「ユーザー検索」タブから\n気になるユーザーをフォローしよう',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      itemCount: following.length + (provider.hideFollowing ? 1 : 0),
      itemBuilder: (_, i) {
        if (provider.hideFollowing && i == 0) return _followHiddenBanner();
        final idx = provider.hideFollowing ? i - 1 : i;
        return _followingCard(context, following[idx], provider);
      },
    );
  }

  Widget _followHiddenBlock() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8), shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Icon(Icons.lock, size: 38, color: AppColors.textHint),
            ),
            const SizedBox(height: 20),
            Text('表示できません',
                style: GoogleFonts.notoSansJp(
                    fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Text('このユーザーはフォロー一覧を\n非公開に設定しています',
                style: GoogleFonts.notoSansJp(fontSize: 14, color: AppColors.textSecondary, height: 1.7),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _followHiddenBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '現在「フォロー一覧非公開」がオンになっています。他のユーザーにはこのリストは見えません。',
              style: GoogleFonts.notoSansJp(fontSize: 12, color: AppColors.primaryDark, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _followingCard(BuildContext context, AppUser user, UserProfileProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight, width: 2),
            ),
            child: ClipOval(
              child: Image.network(
                user.avatarUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primaryLight,
                  child: const Icon(Icons.person, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(user.name,
                          style: GoogleFonts.notoSansJp(
                              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryVeryLight,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: Text('@${user.customId}',
                          style: GoogleFonts.notoSansJp(
                              fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(user.bio,
                    style: GoogleFonts.notoSansJp(
                        fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.push_pin, size: 11, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Text('${user.pinCount}スポット',
                        style: GoogleFonts.notoSansJp(fontSize: 11, color: AppColors.textHint)),
                    const SizedBox(width: 8),
                    const Icon(Icons.people, size: 11, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Text('${user.followerCount}フォロワー',
                        style: GoogleFonts.notoSansJp(fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              provider.unfollow(user.uid);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('@${user.customId} のフォローを解除しました',
                    style: GoogleFonts.notoSansJp(fontSize: 13)),
                backgroundColor: AppColors.textSecondary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
              ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primaryVeryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Text('フォロー中',
                  style: GoogleFonts.notoSansJp(
                      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  // 共通：空状態
  // ════════════════════════════════════════════
  Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: AppColors.primaryVeryLight, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.notoSansJp(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: GoogleFonts.notoSansJp(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                textAlign: TextAlign.center),
          ],
        ),
      ),
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
        BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3)),
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

// ══════════════════════════════════════════════
// SNS設定 定数クラス
// ══════════════════════════════════════════════
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
