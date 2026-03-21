import 'package:flutter/material.dart';
// ignore_for_file: unused_field
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'user_profile_screen.dart';
import '../theme/app_theme.dart';
import '../models/data_models.dart';
import '../models/user_profile_provider.dart';

class TrendScreen extends StatefulWidget {
  final Function(double lat, double lng)? onJumpToMap;

  const TrendScreen({super.key, this.onJumpToMap});

  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  final List<String> _tabs = ['スポット', 'ユーザー検索'];

  // ─── ID 検索 ───
  final TextEditingController _searchCtrl = TextEditingController();
  List<AppUser> _searchResults = [];
  bool _hasSearched = false;

  // ─── おすすめタブ：カテゴリ ───
  int _recCategoryIndex = 0; // 0=観光地 1=カフェ 2=ホテル

  // ─── おすすめタブ：都道府県選択 ───
  String? _selectedPrefecture; // null = すべて

  static const List<String> _prefectures = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県',
    '岐阜県', '静岡県', '愛知県', '三重県',
    '滋賀県', '京都府', '大阪府', '兵庫県', '奈良県', '和歌山県',
    '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県',
    '福岡県', '佐賀県', '長崎県', '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県',
  ];

  // ─── 地方グループ ───
  static const Map<String, List<String>> _regionMap = {
    '北海道': ['北海道'],
    '東北': ['青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県'],
    '関東': ['茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県'],
    '中部': ['新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県', '静岡県', '愛知県'],
    '近畿': ['三重県', '滋賀県', '京都府', '大阪府', '兵庫県', '奈良県', '和歌山県'],
    '中国': ['鳥取県', '島根県', '岡山県', '広島県', '山口県'],
    '四国': ['徳島県', '香川県', '愛媛県', '高知県'],
    '九州・沖縄': ['福岡県', '佐賀県', '長崎県', '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── 外部URL を開く ───
  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('URLを開けませんでした',
              style: GoogleFonts.notoSansJp(fontSize: 13)),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  // ─── ID 検索ロジック ───
  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _hasSearched = true;
      if (q.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = SampleData.sampleUsers.where((u) {
          return u.customId.toLowerCase().contains(q) ||
              u.name.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  // ─── 現在のカテゴリリストを返す ───
  List<RecommendItem> get _currentList {
    final all = _recCategoryIndex == 0
        ? SampleData.sightseeingList
        : _recCategoryIndex == 1
            ? SampleData.cafeList
            : SampleData.hotelList;
    if (_selectedPrefecture == null) return all;
    return all.where((item) => item.prefecture == _selectedPrefecture).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildSliverHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSpotTab(),
                _buildUserSearchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ヘッダー ───
  Widget _buildSliverHeader() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: const SizedBox(height: 4),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        labelStyle: GoogleFonts.notoSansJp(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.notoSansJp(fontWeight: FontWeight.w400, fontSize: 14),
        tabs: [
          const Tab(icon: Icon(Icons.auto_awesome, size: 18), text: 'スポット'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_search, size: 18),
                const SizedBox(width: 4),
                Text('ユーザー検索', style: GoogleFonts.notoSansJp(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // スポット タブ
  // ═══════════════════════════════════════════
  Widget _buildSpotTab() {
    return CustomScrollView(
      slivers: [
        // HOTバナー
        SliverToBoxAdapter(child: _buildHotBanner()),
        // おすすめセクション
        SliverToBoxAdapter(child: _buildRecommendSection()),
      ],
    );
  }

  // ─── おすすめセクション全体 ───
  Widget _buildRecommendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // セクションタイトル
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.recommend, color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              Text(
                'おすすめ情報',
                style: GoogleFonts.notoSansJp(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // カテゴリ切り替え
        _buildCategoryTabs(),
        const SizedBox(height: 12),
        // 都道府県セレクター
        _buildPrefectureSelector(),
        const SizedBox(height: 4),
        // リスト
        _buildRecommendList(),
        const SizedBox(height: 32),
      ],
    );
  }

  // ─── カテゴリタブ（観光地・カフェ・ホテル） ───
  Widget _buildCategoryTabs() {
    const categories = [
      (Icons.landscape, '観光地'),
      (Icons.coffee, 'カフェ'),
      (Icons.hotel, 'ホテル'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(categories.length, (i) {
          final selected = _recCategoryIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _recCategoryIndex = i;
                _selectedPrefecture = null; // カテゴリ切替時に都道府県リセット
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [AppColors.primaryLight, AppColors.primary])
                      : null,
                  color: selected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      categories[i].$1,
                      size: 16,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      categories[i].$2,
                      style: GoogleFonts.notoSansJp(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── 都道府県セレクター ───
  Widget _buildPrefectureSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 現在選択 & 選択ボタン
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _selectedPrefecture == null
                      ? AppColors.primaryVeryLight
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedPrefecture == null
                        ? AppColors.primaryLight
                        : AppColors.primary,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: _selectedPrefecture == null
                          ? AppColors.primary
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _selectedPrefecture ?? 'すべての都道府県',
                      style: GoogleFonts.notoSansJp(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showPrefectureSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune, size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '都道府県を選択',
                        style: GoogleFonts.notoSansJp(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedPrefecture != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _selectedPrefecture = null),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 地方クイックフィルタ（横スクロール）
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _regionMap.entries.map((entry) {
              final isActive = entry.value.contains(_selectedPrefecture);
              return GestureDetector(
                onTap: () {
                  if (entry.value.length == 1) {
                    setState(() => _selectedPrefecture = entry.value.first);
                  } else {
                    _showRegionSheet(entry.key, entry.value);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    entry.key,
                    style: GoogleFonts.notoSansJp(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── 地方→都道府県選択シート ───
  void _showRegionSheet(String regionName, List<String> prefs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$regionName の都道府県',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: prefs.map((pref) {
                    final selected = _selectedPrefecture == pref;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedPrefecture = pref);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? const LinearGradient(
                                  colors: [AppColors.primaryLight, AppColors.primary])
                              : null,
                          color: selected ? null : AppColors.primaryVeryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.primaryLight,
                          ),
                        ),
                        child: Text(
                          pref,
                          style: GoogleFonts.notoSansJp(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── 全47都道府県一覧シート ───
  void _showPrefectureSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '都道府県を選択',
                        style: GoogleFonts.notoSansJp(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // すべて表示ボタン
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedPrefecture = null);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'すべての都道府県を表示',
                      style: GoogleFonts.notoSansJp(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.only(bottom: 24),
                      children: _regionMap.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                entry.key,
                                style: GoogleFonts.notoSansJp(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textHint,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: entry.value.map((pref) {
                                  final selected = _selectedPrefecture == pref;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedPrefecture = pref);
                                      Navigator.pop(context);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 9),
                                      decoration: BoxDecoration(
                                        gradient: selected
                                            ? const LinearGradient(
                                                colors: [
                                                  AppColors.primaryLight,
                                                  AppColors.primary,
                                                ])
                                            : null,
                                        color: selected
                                            ? null
                                            : AppColors.primaryVeryLight,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: selected
                                              ? AppColors.primary
                                              : AppColors.primaryLight,
                                        ),
                                        boxShadow: selected
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.25),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        pref,
                                        style: GoogleFonts.notoSansJp(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── おすすめリスト ───
  Widget _buildRecommendList() {
    final items = _currentList;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.search_off, size: 48, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(
                '${_selectedPrefecture ?? ""}のデータはまだありません',
                style: GoogleFonts.notoSansJp(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '他の都道府県や地方を選択してください',
                style: GoogleFonts.notoSansJp(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 0),
                child: _buildRecommendCard(item),
              ))
          .toList(),
    );
  }

  // ─── おすすめカード ───
  Widget _buildRecommendCard(RecommendItem item) {
    final categoryIcon = item.genre == RecommendGenre.sightseeing
        ? Icons.landscape
        : item.genre == RecommendGenre.cafe
            ? Icons.coffee
            : Icons.hotel;
    final categoryLabel = item.genre == RecommendGenre.sightseeing
        ? '観光地'
        : item.genre == RecommendGenre.cafe
            ? 'カフェ'
            : 'ホテル';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 画像
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(height: 160, color: AppColors.primaryLight),
                  errorWidget: (_, __, ___) => Container(
                    height: 160,
                    color: AppColors.primaryVeryLight,
                    child:
                        const Icon(Icons.image, color: AppColors.primary, size: 40),
                  ),
                ),
                // カテゴリバッジ
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryLight, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcon, size: 11, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          categoryLabel,
                          style: GoogleFonts.notoSansJp(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 都道府県バッジ
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on,
                            size: 11, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          item.prefecture,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タグ
                Wrap(
                  spacing: 6, runSpacing: 4,
                  children: item.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tagBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.notoSansJp(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                // タイトル
                Text(
                  item.title,
                  style: GoogleFonts.notoSansJp(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                // エリア & サイト名
                Row(
                  children: [
                    const Icon(Icons.place,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text(
                      item.area,
                      style: GoogleFonts.notoSansJp(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.open_in_new,
                        size: 12, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text(
                      item.siteName,
                      style: GoogleFonts.notoSansJp(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // 説明
                Text(
                  item.description,
                  style: GoogleFonts.notoSansJp(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // 下部ボタン行
                Row(
                  children: [
                    // 評価
                    if (item.rating != null) ...[
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFFFB300)),
                      const SizedBox(width: 3),
                      Text(
                        item.rating!.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // 詳細を見るボタン
                    GestureDetector(
                      onTap: () => _launchUrl(item.url),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryLight, AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.open_in_new,
                                size: 13, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              '詳細を見る',
                              style: GoogleFonts.notoSansJp(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotBanner() {
    final hotSpots = SampleData.trends.where((t) => t.isHot).toList();
    if (hotSpots.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 200,
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF6B9D)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '今週のHOT',
                        style: GoogleFonts.notoSansJp(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: hotSpots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  _buildHotCard(hotSpots[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotCard(TrendSpot spot) {
    return Consumer<UserProfileProvider>(
      builder: (_, provider, __) {
        final isSaved = provider.isSavedTrend(spot.id);
        return GestureDetector(
          onTap: () => widget.onJumpToMap?.call(spot.lat, spot.lng),
          child: Container(
            width: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: spot.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.primaryLight),
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.primaryVeryLight),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC000000)],
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () {
                        provider.toggleSaveTrend(spot);
                        _showSaveSnack(
                          isSaved ? '保存を解除しました' : '保存しました ✓',
                          isSaved,
                        );
                      },
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSaved
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: 16,
                          color: isSaved
                              ? const Color(0xFFFFD700)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10, left: 10, right: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.title,
                          style: GoogleFonts.notoSansJp(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.favorite,
                                size: 10, color: Colors.pink),
                            const SizedBox(width: 3),
                            Text(
                              '${spot.likeCount}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // ユーザー検索 タブ
  // ═══════════════════════════════════════════
  Widget _buildUserSearchTab() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  onSubmitted: _onSearch,
                  style: GoogleFonts.notoSansJp(
                      fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '@IDまたはニックネームで検索',
                    hintStyle: GoogleFonts.notoSansJp(
                        fontSize: 13, color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.primary, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchResults = [];
                                _hasSearched = false;
                              });
                            },
                            icon: const Icon(Icons.clear,
                                size: 18, color: AppColors.textHint),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.primaryVeryLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _hasSearched
              ? (_searchResults.isEmpty
                  ? _buildEmptySearch()
                  : ListView.builder(
                      padding:
                          const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: _searchResults.length,
                      itemBuilder: (_, i) =>
                          _buildUserCard(_searchResults[i]),
                    ))
              : _buildSearchHint(),
        ),
      ],
    );
  }

  Widget _buildSearchHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primaryVeryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_search,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'ユーザーを検索',
            style: GoogleFonts.notoSansJp(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '@ID またはニックネームで\n気になるユーザーを検索しよう',
            style: GoogleFonts.notoSansJp(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            '例: @yuki_travel  /  Yuki',
            style: GoogleFonts.notoSansJp(
              fontSize: 12,
              color: AppColors.textHint,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            'ユーザーが見つかりませんでした',
            style: GoogleFonts.notoSansJp(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'IDやニックネームを確認してください',
            style: GoogleFonts.notoSansJp(
                fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    return Consumer<UserProfileProvider>(
      builder: (_, provider, __) {
        final isFollowing = provider.isFollowing(user.uid);
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(PageRouteBuilder(
              pageBuilder: (_, __, ___) => UserProfileScreen(user: user),
              transitionsBuilder: (_, anim, __, child) =>
                  SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 300),
            ));
          },
          child: Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primaryLight, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      user.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryLight,
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 30),
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
                            child: Text(
                              user.name,
                              style: GoogleFonts.notoSansJp(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryVeryLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.primaryLight),
                            ),
                            child: Text(
                              '@${user.customId}',
                              style: GoogleFonts.notoSansJp(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.bio,
                        style: GoogleFonts.notoSansJp(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _statChip(Icons.push_pin,
                              '${user.pinCount}', 'スポット'),
                          const SizedBox(width: 8),
                          _statChip(Icons.people,
                              '${user.followerCount}', 'フォロワー'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    provider.toggleFollow(user.uid);
                    _showFollowSnack(isFollowing
                        ? '@${user.customId} のフォローを解除しました'
                        : '@${user.customId} をフォローしました');
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isFollowing
                          ? null
                          : const LinearGradient(colors: [
                              AppColors.primaryLight,
                              AppColors.primary
                            ]),
                      color: isFollowing
                          ? AppColors.primaryVeryLight
                          : null,
                      borderRadius: BorderRadius.circular(20),
                      border: isFollowing
                          ? Border.all(color: AppColors.primaryLight)
                          : null,
                      boxShadow: isFollowing
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Text(
                      isFollowing ? 'フォロー中' : 'フォロー',
                      style: GoogleFonts.notoSansJp(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isFollowing
                            ? AppColors.primary
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textHint),
        const SizedBox(width: 3),
        Text(
          '$value $label',
          style: GoogleFonts.notoSansJp(
            fontSize: 11,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  void _showSaveSnack(String msg, bool wasSaved) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              wasSaved ? Icons.bookmark_remove : Icons.bookmark_added,
              color: Colors.white, size: 18,
            ),
            const SizedBox(width: 8),
            Text(msg, style: GoogleFonts.notoSansJp(fontSize: 13)),
          ],
        ),
        backgroundColor:
            wasSaved ? AppColors.textSecondary : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFollowSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.notoSansJp(fontSize: 13)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
