import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/post_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/trend_screen.dart';
import 'screens/movie_screen.dart';
import 'main_shell.dart';
import 'models/user_profile_provider.dart';
import 'services/subscription_service.dart';

Widget _resolveHome() {
  if (kIsWeb) {
    final screen = Uri.base.queryParameters['screen'];
    switch (screen) {
      case 'main':      return const MainShell(initialTab: 0);
      case 'trend':     return const MainShell(initialTab: 1);
      case 'post':      return const PostScreen();
      case 'prefecture':return const MainShell(initialTab: 3);
      case 'profile':   return const MainShell(initialTab: 4);
      case 'paywall':   return const PaywallScreen();
    }
  }
  return const LoginScreen();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ShotmapApp());
}

class ShotmapApp extends StatelessWidget {
  const ShotmapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionService()),
      ],
      child: MaterialApp(
        title: 'Shotmap',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: _resolveHome(),
        routes: {
          '/main': (_) => const MainShell(),
          '/login': (_) => const LoginScreen(),
        },
      ),
    );
  }
}
