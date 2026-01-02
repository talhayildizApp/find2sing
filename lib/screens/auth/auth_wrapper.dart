import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

/// Auth durumuna göre widget gösterir
/// - Authenticated: child widget
/// - Unauthenticated: LoginScreen veya guest widget
class AuthWrapper extends StatelessWidget {
  /// Giriş yapıldığında gösterilecek widget
  final Widget child;
  
  /// Misafir erişimine izin verilsin mi?
  final bool allowGuest;
  
  /// Misafir modunda gösterilecek widget (allowGuest true ise)
  final Widget? guestChild;

  const AuthWrapper({
    super.key,
    required this.child,
    this.allowGuest = false,
    this.guestChild,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        switch (authProvider.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const _LoadingScreen();
          
          case AuthStatus.authenticated:
            return child;
          
          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            if (allowGuest && guestChild != null) {
              return guestChild!;
            }
            return const LoginScreen();
        }
      },
    );
  }
}

/// Yükleme ekranı
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg_music_clouds.png',
            fit: BoxFit.cover,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo_find2sing.png',
                  width: 180,
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  color: Color(0xFFCAB7FF),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sadece giriş yapılmışsa erişilebilir sayfalar için
class AuthGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AuthGuard({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;

    if (isAuthenticated) {
      return child;
    }

    return fallback ?? const _LoginRequiredWidget();
  }
}

/// Giriş gerekli uyarı widget'ı
class _LoginRequiredWidget extends StatelessWidget {
  const _LoginRequiredWidget();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg_music_clouds.png',
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCAB7FF).withValues(alpha:0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 50,
                      color: Color(0xFF6C6FA4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Giriş Gerekli',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF394272),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bu özelliği kullanmak için giriş yapmalısın.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6C6FA4),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCAB7FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Giriş Yap',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF394272),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Geri Dön',
                      style: TextStyle(
                        color: Color(0xFF6C6FA4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
