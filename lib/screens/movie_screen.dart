import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/data_models.dart';

class MovieScreen extends StatefulWidget {
  final Function(double lat, double lng)? onJumpToMap;

  const MovieScreen({super.key, this.onJumpToMap});

  @override
  State<MovieScreen> createState() => _MovieScreenState();
}

class _MovieScreenState extends State<MovieScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 各ジャンルの表示リスト
  List<RecommendItem> _sightseeingItems = [];
  List<RecommendItem> _gourmetItems = [];
  List<RecommendItem> _hotelItems = [];

  // ローディング状態
  bool _isRefreshing = false;

  // ── 都道府県フィルター ──
  String? _selectedPrefecture;

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

  // ジャンル定義
  static const List<_Genre> _genres = [
    _Genre(
      key: RecommendGenre.sightseeing,
      label: 'おすすめ観光地',
      icon: Icons.photo_camera_outlined,
      activeIcon: Icons.photo_camera,
      color: Color(0xFF5BA4CF),
      gradient: [Color(0xFF5BA4CF), Color(0xFF3D8FBF)],
    ),
    _Genre(
      key: RecommendGenre.gourmet,
      label: 'おすすめグルメ',
      icon: Icons.restaurant_outlined,
      activeIcon: Icons.restaurant,
      color: Color(0xFFD4915A),
      gradient: [Color(0xFFE8A87C), Color(0xFFD4915A)],
    ),
    _Genre(
      key: RecommendGenre.hotel,
      label: 'おすすめホテル',
      icon: Icons.hotel_outlined,
      activeIcon: Icons.hotel,
      color: Color(0xFF9B7EBF),
      gradient: [Color(0xFFB89ED8), Color(0xFF9B7EBF)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _genres.length, vsync: this);
    _loadItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── リストをシャッフルして30件返す（フィルターなし時は常時30件）
  List<RecommendItem> _shuffled(List<RecommendItem> base) {
    final rng = Random();
    final list = List<RecommendItem>.from(base)..shuffle(rng);
    return list.take(30).toList();
  }

  // ── 都道府県フィルター適用 ──
  // 選択中は選択都道府県のアイテムのみ表示（他県では補完しない）
  List<RecommendItem> _filtered(List<RecommendItem> base, List<RecommendItem> allData) {
    if (_selectedPrefecture == null) return base; // フィルターなし: シャッフル済み30件
    // 選択都道府県のアイテムのみ抽出（他県は一切含めない）
    return allData
        .where((item) => item.prefecture == _selectedPrefecture)
        .toList();
  }

  List<RecommendItem> get _currentSightseeing =>
      _filtered(_sightseeingItems, SampleData.sightseeingList);
  List<RecommendItem> get _currentCafe =>
      _filtered(_gourmetItems, SampleData.gourmetList);
  List<RecommendItem> get _currentHotel =>
      _filtered(_hotelItems, SampleData.hotelList);

  void _loadItems() {
    setState(() {
      _sightseeingItems = _shuffled(SampleData.sightseeingList);
      _gourmetItems     = _shuffled(SampleData.gourmetList);
      _hotelItems       = _shuffled(SampleData.hotelList);
    });
  }

  // ── プルダウンリロード ──
  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    // 500ms 待って新しい順序を生成（実際はAPIコールに置き換え）
    await Future.delayed(const Duration(milliseconds: 600));
    _loadItems();
    if (mounted) setState(() => _isRefreshing = false);
  }

  // ── 外部URLを開く ──
  Future<void> _openUrl(String urlStr) async {
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URLを開けませんでした', style: GoogleFonts.notoSansJp()),
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── ヘッダー ──
          _buildHeader(),
          // ── 都道府県フィルター ──
          _buildPrefectureFilter(),
          // ── タブバー ──
          _buildTabBar(),
          // ── タブコンテンツ ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGenreList(_currentSightseeing, _genres[0]),
                _buildGenreList(_currentCafe,        _genres[1]),
                _buildGenreList(_currentHotel,       _genres[2]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ヘッダー ──
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.explore, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 10),
              Text(
                '都道府県で探す',
                style: GoogleFonts.notoSansJp(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryVeryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.open_in_new, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '外部サイト',
                      style: GoogleFonts.notoSansJp(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _onRefresh,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryVeryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: _isRefreshing
                      ? const Padding(
                          padding: EdgeInsets.all(7),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.refresh, size: 17, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 都道府県フィルター UI ──
  Widget _buildPrefectureFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 現在選択表示
              GestureDetector(
                onTap: _showPrefectureSheet,
                child: Container(
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
                      Icon(Icons.location_on, size: 14, color: AppColors.primary),
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
          const SizedBox(height: 8),
          // 地方クイックフィルター
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
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
                      color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.95),
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
      ),
    );
  }

  // ── 地方別都道府県シート ──
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
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
                children: prefs.map((pref) {
                  final isSelected = _selectedPrefecture == pref;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedPrefecture = pref);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [AppColors.primaryLight, AppColors.primary])
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        pref,
                        style: GoogleFonts.notoSansJp(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 全都道府県選択シート ──
  void _showPrefectureSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (_, sc) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: Column(
                      children: [
                        Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              '都道府県を選択',
                              style: GoogleFonts.notoSansJp(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedPrefecture = null);
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryVeryLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primaryLight),
                                ),
                                child: Text(
                                  'すべての都道府県を表示',
                                  style: GoogleFonts.notoSansJp(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: sc,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      children: _regionMap.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                entry.key,
                                style: GoogleFonts.notoSansJp(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: entry.value.map((pref) {
                                final isSelected = _selectedPrefecture == pref;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedPrefecture = pref);
                                    Navigator.pop(context);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? const LinearGradient(
                                              colors: [AppColors.primaryLight, AppColors.primary])
                                          : null,
                                      color: isSelected ? null : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : AppColors.border,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      pref,
                                      style: GoogleFonts.notoSansJp(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const Divider(height: 20),
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

  // ── タブバー ──
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorColor: Colors.transparent,
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        tabs: List.generate(_genres.length, (i) {
          return AnimatedBuilder(
            animation: _tabController,
            builder: (_, __) {
              final isSelected = _tabController.index == i;
              return _TabItem(genre: _genres[i], isSelected: isSelected);
            },
          );
        }),
      ),
    );
  }

  // ── ジャンル別リスト（RefreshIndicator付き） ──
  Widget _buildGenreList(List<RecommendItem> items, _Genre genre) {
    // 都道府県選択中かつ0件の場合は空状態を表示
    if (_selectedPrefecture != null && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(genre.icon, size: 56, color: genre.color.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              '$_selectedPrefecture の${genre.label}情報は\nまだ登録されていません',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansJp(
                fontSize: 15,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: genre.color,
      strokeWidth: 2.5,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // ジャンルバナー
          SliverToBoxAdapter(child: _buildGenreBanner(genre, items.length)),
          // カードリスト
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildRecommendCard(items[index], genre),
                childCount: items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ジャンルバナー ──
  Widget _buildGenreBanner(_Genre genre, int count) {
    final prefLabel = _selectedPrefecture != null ? '📍$_selectedPrefecture' : '全国';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: genre.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: genre.color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(genre.activeIcon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  genre.label,
                  style: GoogleFonts.notoSansJp(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$prefLabel の観光情報 · 下に引いてリロード',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count件',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── おすすめカード ──
  Widget _buildRecommendCard(RecommendItem item, _Genre genre) {
    // 選択都道府県のアイテムかどうか（ハイライト表示用）
    final isSelectedPref = _selectedPrefecture != null &&
        item.prefecture == _selectedPrefecture;
    return GestureDetector(
      onTap: () => _openUrl(item.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelectedPref
              ? Border.all(color: genre.color, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像エリア
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 180,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryVeryLight,
                        child: const Icon(Icons.image,
                            color: AppColors.primary, size: 48),
                      ),
                    ),
                  ),
                  // 上グラデーション
                  Positioned(
                    top: 0, left: 0, right: 0, height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 評価バッジ
                  if (item.rating != null)
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 12, color: Color(0xFFFFD700)),
                            const SizedBox(width: 3),
                            Text(
                              item.rating!.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // エリアバッジ
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: genre.color.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 10, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            item.area,
                            style: GoogleFonts.notoSansJp(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 外部リンクアイコン
                  Positioned(
                    bottom: 10, right: 10,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: genre.gradient),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: genre.color.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.open_in_new, color: Colors.white, size: 15),
                    ),
                  ),
                ],
              ),
            ),
            // テキストエリア
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: genre.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: genre.color.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          item.siteName,
                          style: GoogleFonts.notoSansJp(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: genre.color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            '詳細を見る',
                            style: GoogleFonts.notoSansJp(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                          Icon(Icons.chevron_right,
                              size: 14, color: AppColors.textSecondary),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: GoogleFonts.notoSansJp(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: GoogleFonts.notoSansJp(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: item.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openUrl(item.url),
                      icon: const Icon(Icons.open_in_new, size: 15),
                      label: Text(
                        '${item.siteName}で見る',
                        style: GoogleFonts.notoSansJp(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: genre.color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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
}

// ── タブアイテム ──
class _TabItem extends StatelessWidget {
  final _Genre genre;
  final bool isSelected;
  const _TabItem({required this.genre, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isSelected ? genre.color : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isSelected ? genre.activeIcon : genre.icon,
              key: ValueKey(isSelected),
              size: 22,
              color: isSelected ? genre.color : AppColors.textHint,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            genre.label,
            style: GoogleFonts.notoSansJp(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected ? genre.color : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ジャンル定義 ──
class _Genre {
  final RecommendGenre key;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color color;
  final List<Color> gradient;

  const _Genre({
    required this.key,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.color,
    required this.gradient,
  });
}
