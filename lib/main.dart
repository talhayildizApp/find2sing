import 'package:flutter/material.dart';
import 'package:sarkiapp/screens/game/single_player_settings_screen.dart';
import 'package:sarkiapp/screens/game/friends_settings_screen.dart';
import 'package:flutter/services.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sadece dikey mod:
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const SarkiApp());
}


class SarkiApp extends StatelessWidget {
  const SarkiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Find2Sing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

/// SPLASH – Figma’dan aldığın tam ekran splash.png + fade-out
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

    // 1 sn göster, sonra fade-out
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _controller.forward();
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
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
          'assets/images/splash.png', // Figma’daki tam splash görselin
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}


/// HOME – bulutlu arka plan + BÜYÜK logo + ortalanmış butonlar
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan: logolu PNG
          Image.asset(
            'assets/images/home_bg.png',
            fit: BoxFit.cover,
          ),

          // Butonlar
          SafeArea(
            child: Column(
              children: [
                // üstte biraz boşluk (PNG’deki logoya bağlı)
                SizedBox(height: size.height * 0.52),

                // Tek Başına
                ModeButton(
                  label: 'Tek Başına',
                  icon: Icons.music_note,
                  backgroundColor: const Color(0xFFCAB7FF),
                  textColor: const Color(0xFF4B4F72),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SinglePlayerSettingsScreen(),
                      ),
                    );
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
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                        builder: (_) => const FriendsSettingsScreen(),
                  ),
                  );
        },

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
      width: size.width * 0.65, // daha dar, mockup’a benzer
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

