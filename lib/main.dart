import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

// Firebase config
import 'firebase_options.dart';

// Providers
import 'package:sarkiapp/providers/auth_provider.dart';

// Screens
import 'package:sarkiapp/screens/auth/login_screen.dart';
import 'package:sarkiapp/screens/auth/profile_screen.dart';
import 'package:sarkiapp/screens/home/home_screen.dart';
import 'package:sarkiapp/screens/game/single_player_settings_screen.dart';
import 'package:sarkiapp/screens/game/friends_settings_screen.dart';
import 'package:sarkiapp/screens/challenge/challenge_screen.dart';
import 'package:sarkiapp/screens/admin/dev_admin_screen.dart';
import 'package:sarkiapp/screens/online/online_match_screen.dart';
import 'package:sarkiapp/models/match_intent_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Sadece dikey mod
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const SarkiApp());
}

class SarkiApp extends StatelessWidget {
  const SarkiApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Find2Sing',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFCAB7FF),
          ),
        ),
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/single-player': (context) => const SinglePlayerSettingsScreen(),
          '/friends': (context) => const FriendsSettingsScreen(),
          '/challenge': (context) => const ChallengeScreen(),
          '/dev-admin': (context) => const DevAdminScreen(),
          '/online-match': (context) => const OnlineMatchScreen(),
        },
        initialRoute: '/',
      ),
    );
  }
}

/// SPLASH SCREEN
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeOutAnimation;
  StreamSubscription? _linkSubscription;
  String? _pendingDeepLinkOpponentId;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _initDeepLinks();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _controller.forward();
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) _handleDeepLink(initialLink);
    } catch (e) {
      debugPrint('Deep link error: $e');
    }

    _linkSubscription = linkStream.listen((String? link) {
      if (link != null) _handleDeepLink(link);
    });
  }

  void _handleDeepLink(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null) return;

    if (uri.host == 'match' || uri.path.contains('match')) {
      final opponentId = uri.queryParameters['opponentId'];
      if (opponentId != null && opponentId.isNotEmpty) {
        _pendingDeepLinkOpponentId = opponentId;
        if (_controller.isCompleted) {
          _navigateToOnlineMatch(opponentId);
        }
      }
    }
  }

  void _navigateToNextScreen() {
    if (_pendingDeepLinkOpponentId != null) {
      _navigateToOnlineMatch(_pendingDeepLinkOpponentId!);
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _navigateToOnlineMatch(String opponentId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OnlineMatchScreen(
          prefillOpponentId: opponentId,
          mode: MatchMode.friendsWord,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeOutAnimation,
        child: Image.asset(
          'assets/images/splash.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
