import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Firebase config
import 'firebase_options.dart';

// Providers
import 'package:sarkiapp/providers/auth_provider.dart';

// Screens
import 'package:sarkiapp/screens/auth/login_screen.dart';
import 'package:sarkiapp/screens/auth/profile_screen.dart';
import 'package:sarkiapp/screens/game/single_player_settings_screen.dart';
import 'package:sarkiapp/screens/game/friends_settings_screen.dart';
import 'package:sarkiapp/screens/challenge/challenge_screen.dart';
import 'package:sarkiapp/screens/admin/dev_admin_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Find2Sing',
        debugShowCheckedModeBanner: false,
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
        },
        initialRoute: '/',
      ),
    );
  }
}

/// SPLASH
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeOutAnimation;

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

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _controller.forward();
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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

/// HOME
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isAuthenticated;
    final user = authProvider.user;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan
          Image.asset(
            'assets/images/home_bg.png',
            fit: BoxFit.cover,
          ),

          SafeArea(
            child: Column(
              children: [
                // Üst bar - Profil butonu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (isLoggedIn) {
                            Navigator.pushNamed(context, '/profile');
                          } else {
                            Navigator.pushNamed(context, '/login');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFCAB7FF),
                                backgroundImage: user?.photoUrl != null
                                    ? NetworkImage(user!.photoUrl!)
                                    : null,
                                child: user?.photoUrl == null
                                    ? Icon(
                                        isLoggedIn ? Icons.person : Icons.login,
                                        size: 16,
                                        color: const Color(0xFF394272),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isLoggedIn
                                    ? (user?.displayName ?? 'Profil')
                                    : 'Giriş Yap',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF394272),
                                ),
                              ),
                              if (user?.isActivePremium == true) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.workspace_premium,
                                  size: 16,
                                  color: Color(0xFFFFB958),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Logo alanı için boşluk
                SizedBox(height: size.height * 0.40),

                // Tek Başına
                ModeButton(
                  label: 'Tek Başına',
                  icon: Icons.music_note,
                  backgroundColor: const Color(0xFFCAB7FF),
                  textColor: const Color(0xFF4B4F72),
                  onTap: () {
                    Navigator.pushNamed(context, '/single-player');
                  },
                ),

                const SizedBox(height: 16),

                // Arkadaşınla
                ModeButton(
                  label: 'Arkadaşınla',
                  icon: Icons.queue_music,
                  backgroundColor: const Color(0xFFFFD891),
                  textColor: const Color(0xFF8C5A1F),
                  onTap: () {
                    Navigator.pushNamed(context, '/friends');
                  },
                ),

                const SizedBox(height: 16),

                // Challenge modu
                ModeButton(
                  label: 'Challenge',
                  icon: Icons.emoji_events,
                  backgroundColor: const Color(0xFF394272),
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.pushNamed(context, '/challenge');
                  },
                ),

                const Spacer(),

                // Alt bilgi
                if (!isLoggedIn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text(
                        'Giriş yap ve ilerlemenı kaydet →',
                        style: TextStyle(
                          color: Color(0xFF6C6FA4),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const ModeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: size.width * 0.65,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 8,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
