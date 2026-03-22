import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/map_screen.dart';
import '../screens/trend_screen.dart';
import '../screens/movie_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/post_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;

  // マップ画面のコントローラー
  final GlobalKey<_MapScreenWrapperState> _mapKey =
      GlobalKey<_MapScreenWrapperState>();

  void _jumpMapTo(double lat, double lng) {
    setState(() => _currentIndex = 0);
    // マップタブに切り替え後、少し待ってカメラ移動
    Future.delayed(const Duration(milliseconds: 300), () {
      _mapKey.currentState?.jumpTo(lat, lng);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _MapScreenWrapper(key: _mapKey),
          TrendScreen(onJumpToMap: _jumpMapTo),
          const SizedBox.shrink(), // 投稿ボタンのプレースホルダー
          MovieScreen(onJumpToMap: _jumpMapTo),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.map_outlined, Icons.map, 'マップ'),
              _buildNavItem(1, Icons.auto_awesome_outlined, Icons.auto_awesome, 'トレンド'),
              _buildPostButton(),
              _buildNavItem(3, Icons.location_city_outlined, Icons.location_city, '都道府県'),
              _buildNavItem(4, Icons.person_outline, Icons.person, 'マイページ'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? filledIcon : outlinedIcon,
                key: ValueKey(isSelected),
                size: 26,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const PostScreen(),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.primary],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

// マップ画面ラッパー（外部から位置ジャンプを受け取るため）
class _MapScreenWrapper extends StatefulWidget {
  const _MapScreenWrapper({super.key});

  @override
  State<_MapScreenWrapper> createState() => _MapScreenWrapperState();
}

class _MapScreenWrapperState extends State<_MapScreenWrapper> {
  final MapScreenController _controller = MapScreenController();

  @override
  Widget build(BuildContext context) {
    return MapScreen(controller: _controller);
  }

  void jumpTo(double lat, double lng) {
    _controller.jumpTo(lat, lng);
  }
}
