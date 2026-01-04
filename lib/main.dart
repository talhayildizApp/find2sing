import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'dart:async';

// Firebase config
import 'firebase_options.dart';

// Providers
import 'package:sarkiapp/providers/auth_provider.dart';

// Services
import 'package:sarkiapp/services/deep_link_service.dart';
import 'package:sarkiapp/services/push_notification_service.dart';

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

// Widgets
import 'package:sarkiapp/widgets/app_link_handler.dart';

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
        builder: (context, child) {
          // Wrap with AppLinkHandler for deep link and notification handling
          return AppLinkHandler(child: child ?? const SizedBox());
        },
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
  final DeepLinkService _deepLinkService = DeepLinkService();
  final PushNotificationService _pushService = PushNotificationService();
  StreamSubscription<DeepLinkData>? _linkSubscription;
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

    _initServices();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _controller.forward();
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _initServices() async {
    // Initialize deep link service
    await _deepLinkService.initialize();
    
    // Initialize push notification service
    await _pushService.initialize();
    
    // Listen for deep links during splash
    _linkSubscription = _deepLinkService.onLink.listen(_handleDeepLink);
    
    // Check for pending link
    if (_deepLinkService.pendingLink != null) {
      _handleDeepLink(_deepLinkService.pendingLink!);
    }
  }

  void _handleDeepLink(DeepLinkData data) {
    if (data.type == DeepLinkType.matchInvite || 
        data.type == DeepLinkType.friendInvite) {
      _pendingDeepLinkOpponentId = data.oderId;
      if (_controller.isCompleted) {
        _navigateToOnlineMatch(_pendingDeepLinkOpponentId!);
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
          prefilledOpponentId: opponentId,
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
