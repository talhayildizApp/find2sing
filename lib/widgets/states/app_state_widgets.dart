import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════
// APP STATE WIDGETS - Empty States, Error Handling, Loading States
// Comprehensive UX for all edge cases in Find2Sing
// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────────────────────

class StateColors {
  static const Color primary = Color(0xFFCAB7FF);
  static const Color darkPurple = Color(0xFF394272);
  static const Color softPurple = Color(0xFF6C6FA4);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFB958);
  static const Color info = Color(0xFF2196F3);
  static const Color skeleton = Color(0xFFE8E8E8);
  static const Color skeletonHighlight = Color(0xFFF5F5F5);
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE WIDGET - Generic empty state with variations
// ─────────────────────────────────────────────────────────────────────────────

enum EmptyStateType {
  noSongs,
  noHistory,
  noFriends,
  noResults,
  noLeaderboard,
  lockedContent,
  noAchievements,
  noNotifications,
  noConnection,
  custom,
}

class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  final String? customEmoji;
  final String? customTitle;
  final String? customMessage;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  const EmptyStateWidget({
    super.key,
    this.type = EmptyStateType.custom,
    this.customEmoji,
    this.customTitle,
    this.customMessage,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  // Preset configurations
  static const Map<EmptyStateType, _EmptyStateConfig> _presets = {
    EmptyStateType.noSongs: _EmptyStateConfig(
      emoji: '🎵',
      title: 'Henüz Şarkı Yok',
      message: 'Bu challenge için henüz şarkı eklenmemiş. Yakında gelecek!',
    ),
    EmptyStateType.noHistory: _EmptyStateConfig(
      emoji: '📜',
      title: 'Geçmiş Boş',
      message: 'Henüz oyun oynamadın. İlk maçını başlat ve geçmişini oluştur!',
    ),
    EmptyStateType.noFriends: _EmptyStateConfig(
      emoji: '👥',
      title: 'Arkadaş Yok',
      message: 'Henüz arkadaş eklemedin. Davet kodunu paylaşarak arkadaşlarını ekle!',
    ),
    EmptyStateType.noResults: _EmptyStateConfig(
      emoji: '🔍',
      title: 'Sonuç Bulunamadı',
      message: 'Aramanızla eşleşen sonuç yok. Farklı bir terim deneyin.',
    ),
    EmptyStateType.noLeaderboard: _EmptyStateConfig(
      emoji: '🏆',
      title: 'Liderlik Tablosu Boş',
      message: 'Henüz kimse bu challenge\'ı tamamlamadı. İlk sen ol!',
    ),
    EmptyStateType.lockedContent: _EmptyStateConfig(
      emoji: '🔒',
      title: 'İçerik Kilitli',
      message: 'Bu içeriğe erişmek için premium\'a geç veya satın al.',
    ),
    EmptyStateType.noAchievements: _EmptyStateConfig(
      emoji: '⭐',
      title: 'Başarı Yok',
      message: 'Henüz başarı kazanmadın. Oynamaya devam et ve başarıları aç!',
    ),
    EmptyStateType.noNotifications: _EmptyStateConfig(
      emoji: '🔔',
      title: 'Bildirim Yok',
      message: 'Şu an yeni bildirim yok. Her şey güncel!',
    ),
    EmptyStateType.noConnection: _EmptyStateConfig(
      emoji: '📡',
      title: 'Bağlantı Yok',
      message: 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final config = _presets[type] ?? const _EmptyStateConfig(
      emoji: '📭',
      title: 'Boş',
      message: 'Burada henüz hiçbir şey yok.',
    );

    final emoji = customEmoji ?? config.emoji;
    final title = customTitle ?? config.title;
    final message = customMessage ?? config.message;

    if (compact) {
      return _buildCompact(emoji, title, message);
    }

    return _buildFull(emoji, title, message);
  }

  Widget _buildFull(String emoji, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated emoji container
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      StateColors.primary.withValues(alpha: 0.2),
                      StateColors.primary.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: StateColors.darkPurple,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: StateColors.softPurple.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              _ActionButton(
                label: actionLabel!,
                onTap: onAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(String emoji, String title, String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: StateColors.darkPurple.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: StateColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: StateColors.darkPurple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: StateColors.softPurple.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onAction != null)
            IconButton(
              onPressed: onAction,
              icon: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: StateColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyStateConfig {
  final String emoji;
  final String title;
  final String message;

  const _EmptyStateConfig({
    required this.emoji,
    required this.title,
    required this.message,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR STATE WIDGET - Error handling with retry
// ─────────────────────────────────────────────────────────────────────────────

enum ErrorType {
  network,
  auth,
  firestore,
  timeout,
  permission,
  validation,
  server,
  unknown,
}

class ErrorStateWidget extends StatelessWidget {
  final ErrorType type;
  final String? customTitle;
  final String? customMessage;
  final String? errorCode;
  final VoidCallback? onRetry;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;
  final bool compact;
  final bool showErrorCode;

  const ErrorStateWidget({
    super.key,
    this.type = ErrorType.unknown,
    this.customTitle,
    this.customMessage,
    this.errorCode,
    this.onRetry,
    this.onSecondaryAction,
    this.secondaryActionLabel,
    this.compact = false,
    this.showErrorCode = false,
  });

  static const Map<ErrorType, _ErrorConfig> _presets = {
    ErrorType.network: _ErrorConfig(
      emoji: '📡',
      title: 'Bağlantı Hatası',
      message: 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.',
      color: StateColors.warning,
    ),
    ErrorType.auth: _ErrorConfig(
      emoji: '🔐',
      title: 'Oturum Hatası',
      message: 'Oturumunuz sona ermiş olabilir. Tekrar giriş yapın.',
      color: StateColors.error,
    ),
    ErrorType.firestore: _ErrorConfig(
      emoji: '💾',
      title: 'Veri Hatası',
      message: 'Veriler yüklenirken bir sorun oluştu. Lütfen tekrar deneyin.',
      color: StateColors.warning,
    ),
    ErrorType.timeout: _ErrorConfig(
      emoji: '⏱️',
      title: 'Zaman Aşımı',
      message: 'İşlem çok uzun sürdü. Bağlantınızı kontrol edip tekrar deneyin.',
      color: StateColors.warning,
    ),
    ErrorType.permission: _ErrorConfig(
      emoji: '🚫',
      title: 'Erişim Engellendi',
      message: 'Bu içeriğe erişim izniniz yok.',
      color: StateColors.error,
    ),
    ErrorType.validation: _ErrorConfig(
      emoji: '⚠️',
      title: 'Geçersiz Giriş',
      message: 'Girdiğiniz bilgileri kontrol edin.',
      color: StateColors.warning,
    ),
    ErrorType.server: _ErrorConfig(
      emoji: '🔧',
      title: 'Sunucu Hatası',
      message: 'Sunucularımızda bir sorun var. Kısa süre sonra tekrar deneyin.',
      color: StateColors.error,
    ),
    ErrorType.unknown: _ErrorConfig(
      emoji: '❌',
      title: 'Bir Şeyler Ters Gitti',
      message: 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
      color: StateColors.error,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final config = _presets[type]!;
    final title = customTitle ?? config.title;
    final message = customMessage ?? config.message;

    if (compact) {
      return _buildCompact(config.emoji, title, message, config.color);
    }

    return _buildFull(config.emoji, title, message, config.color);
  }

  Widget _buildFull(String emoji, String title, String message, Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon with shake animation
            _ShakeWidget(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.2),
                      accentColor.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: accentColor,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: StateColors.softPurple.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),

            // Error code
            if (showErrorCode && errorCode != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: StateColors.skeleton,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hata Kodu: $errorCode',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: StateColors.softPurple.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],

            // Retry button
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              _ActionButton(
                label: 'Tekrar Dene',
                onTap: onRetry!,
                icon: Icons.refresh_rounded,
                color: accentColor,
              ),
            ],

            // Secondary action
            if (onSecondaryAction != null && secondaryActionLabel != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(
                  secondaryActionLabel!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: StateColors.softPurple.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(String emoji, String title, String message, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: StateColors.softPurple.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: Icon(
                Icons.refresh_rounded,
                size: 22,
                color: accentColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorConfig {
  final String emoji;
  final String title;
  final String message;
  final Color color;

  const _ErrorConfig({
    required this.emoji,
    required this.title,
    required this.message,
    required this.color,
  });
}

// Shake animation widget
class _ShakeWidget extends StatefulWidget {
  final Widget child;

  const _ShakeWidget({required this.child});

  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5, end: -5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON CARD - Loading placeholder
// ─────────────────────────────────────────────────────────────────────────────

class SkeletonCard extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry margin;

  const SkeletonCard({
    super.key,
    this.width,
    this.height = 80,
    this.borderRadius = 16,
    this.margin = EdgeInsets.zero,
  });

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: const [
                StateColors.skeleton,
                StateColors.skeletonHighlight,
                StateColors.skeleton,
              ],
            ),
          ),
        );
      },
    );
  }
}

// Pre-built skeleton layouts
class SkeletonLayouts {
  /// Standard list item skeleton
  static Widget listItem({double height = 80}) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const SkeletonCard(width: 52, height: 52, borderRadius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonCard(width: 140, height: 16, borderRadius: 4),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SkeletonCard(width: 60, height: 20, borderRadius: 8),
                    const SizedBox(width: 8),
                    SkeletonCard(width: 50, height: 20, borderRadius: 8),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Category card skeleton
  static Widget categoryCard() {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonCard(width: 36, height: 36, borderRadius: 10),
          const Spacer(),
          const SkeletonCard(width: 80, height: 14, borderRadius: 4),
          const SizedBox(height: 8),
          const SkeletonCard(width: 50, height: 10, borderRadius: 4),
        ],
      ),
    );
  }

  /// Profile header skeleton
  static Widget profileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const SkeletonCard(width: 72, height: 72, borderRadius: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonCard(width: 120, height: 20, borderRadius: 4),
                const SizedBox(height: 8),
                const SkeletonCard(width: 160, height: 14, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Stats grid skeleton
  static Widget statsGrid() {
    return Row(
      children: List.generate(
        4,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 3 ? 10 : 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const SkeletonCard(width: 32, height: 32, borderRadius: 10),
                const SizedBox(height: 8),
                const SkeletonCard(width: 40, height: 18, borderRadius: 4),
                const SizedBox(height: 4),
                const SkeletonCard(width: 50, height: 12, borderRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Leaderboard item skeleton
  static Widget leaderboardItem({int rank = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SkeletonCard(width: 32, height: 32, borderRadius: 16),
          const SizedBox(width: 12),
          const SkeletonCard(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonCard(width: 100, height: 14, borderRadius: 4),
                const SizedBox(height: 6),
                const SkeletonCard(width: 60, height: 12, borderRadius: 4),
              ],
            ),
          ),
          const SkeletonCard(width: 50, height: 24, borderRadius: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP LOADING INDICATOR - Branded spinner
// ─────────────────────────────────────────────────────────────────────────────

class AppLoadingIndicator extends StatefulWidget {
  final String? message;
  final double size;
  final Color? color;
  final bool showMessage;

  const AppLoadingIndicator({
    super.key,
    this.message,
    this.size = 48,
    this.color,
    this.showMessage = true,
  });

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? StateColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing background
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: widget.size * 0.7,
                      height: widget.size * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.15),
                      ),
                    ),
                  );
                },
              ),

              // Rotating music notes
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _MusicNotesPainter(
                      progress: _rotationController.value,
                      color: color,
                    ),
                  );
                },
              ),

              // Center icon
              Text(
                '🎵',
                style: TextStyle(fontSize: widget.size * 0.35),
              ),
            ],
          ),
        ),

        if (widget.showMessage && widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: StateColors.softPurple.withValues(alpha: 0.8),
            ),
          ),
        ],
      ],
    );
  }
}

class _MusicNotesPainter extends CustomPainter {
  final double progress;
  final Color color;

  _MusicNotesPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw 4 dots rotating around center
    for (int i = 0; i < 4; i++) {
      final angle = (progress * 2 * math.pi) + (i * math.pi / 2);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      // Size varies based on position
      final dotSize = 4.0 + (math.sin(progress * 2 * math.pi + i) + 1) * 2;

      canvas.drawCircle(Offset(x, y), dotSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MusicNotesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Compact inline loading
class InlineLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const InlineLoadingIndicator({
    super.key,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? StateColors.primary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VALIDATED TEXT FIELD - Form field with validation
// ─────────────────────────────────────────────────────────────────────────────

class ValidatedTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool autovalidate;

  const ValidatedTextField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction,
    this.focusNode,
    this.autovalidate = false,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  late TextEditingController _controller;
  String? _errorText;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _validate(String value) {
    if (!widget.autovalidate && !_hasInteracted) return;

    final error = widget.validator?.call(value);
    if (error != _errorText) {
      setState(() => _errorText = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: StateColors.darkPurple,
            ),
          ),
          const SizedBox(height: 8),
        ],

        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.enabled ? Colors.white : StateColors.skeleton,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _errorText != null
                  ? StateColors.error
                  : StateColors.primary.withValues(alpha: 0.3),
              width: _errorText != null ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _errorText != null
                    ? StateColors.error.withValues(alpha: 0.1)
                    : StateColors.darkPurple.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            textInputAction: widget.textInputAction,
            style: const TextStyle(
              fontSize: 16,
              color: StateColors.darkPurple,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontSize: 16,
                color: StateColors.softPurple.withValues(alpha: 0.5),
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon ?? (_errorText != null
                  ? const Icon(Icons.error_outline, color: StateColors.error)
                  : null),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              counterText: '',
            ),
            onChanged: (value) {
              _hasInteracted = true;
              _validate(value);
              widget.onChanged?.call(value);
            },
            onSubmitted: widget.onSubmitted,
          ),
        ),

        // Error message
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _errorText != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: StateColors.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: StateColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GAME ANSWER FIELD - Inline validation for game inputs
// ─────────────────────────────────────────────────────────────────────────────

enum AnswerFieldState { idle, typing, valid, invalid }

class GameAnswerField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool Function(String)? validator;
  final void Function(String)? onChanged;
  final void Function()? onSubmit;
  final AnswerFieldState state;
  final bool enabled;

  const GameAnswerField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmit,
    this.state = AnswerFieldState.idle,
    this.enabled = true,
  });

  @override
  State<GameAnswerField> createState() => _GameAnswerFieldState();
}

class _GameAnswerFieldState extends State<GameAnswerField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Color get _borderColor {
    switch (widget.state) {
      case AnswerFieldState.idle:
        return StateColors.primary.withValues(alpha: 0.3);
      case AnswerFieldState.typing:
        return StateColors.primary;
      case AnswerFieldState.valid:
        return StateColors.success;
      case AnswerFieldState.invalid:
        return StateColors.error;
    }
  }

  Color get _iconColor {
    switch (widget.state) {
      case AnswerFieldState.idle:
        return StateColors.softPurple;
      case AnswerFieldState.typing:
        return StateColors.primary;
      case AnswerFieldState.valid:
        return StateColors.success;
      case AnswerFieldState.invalid:
        return StateColors.error;
    }
  }

  IconData get _suffixIcon {
    switch (widget.state) {
      case AnswerFieldState.idle:
      case AnswerFieldState.typing:
        return Icons.search_rounded;
      case AnswerFieldState.valid:
        return Icons.check_circle_rounded;
      case AnswerFieldState.invalid:
        return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: StateColors.darkPurple,
          ),
        ),
        const SizedBox(height: 8),

        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _borderColor,
              width: widget.state == AnswerFieldState.idle ? 1 : 2,
            ),
            boxShadow: widget.state != AnswerFieldState.idle
                ? [
                    BoxShadow(
                      color: _borderColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: widget.enabled,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: StateColors.darkPurple,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: StateColors.softPurple.withValues(alpha: 0.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: widget.onChanged,
                  onSubmitted: (_) => widget.onSubmit?.call(),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  key: ValueKey(widget.state),
                  onPressed: widget.state == AnswerFieldState.valid
                      ? widget.onSubmit
                      : null,
                  icon: Icon(
                    _suffixIcon,
                    color: _iconColor,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Feedback message
        if (widget.state == AnswerFieldState.invalid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: StateColors.error,
                ),
                const SizedBox(width: 6),
                Text(
                  'Bu şarkı listede yok. Tekrar dene!',
                  style: TextStyle(
                    fontSize: 12,
                    color: StateColors.error.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTON - Shared button for state widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.color,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? StateColors.primary;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: _isPressed ? 0.2 : 0.4),
                blurRadius: _isPressed ? 8 : 16,
                offset: Offset(0, _isPressed ? 2 : 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INLINE FEEDBACK BANNER - For showing success/error inline
// ─────────────────────────────────────────────────────────────────────────────

class InlineFeedbackBanner extends StatelessWidget {
  final String message;
  final bool isSuccess;
  final VoidCallback? onDismiss;

  const InlineFeedbackBanner({
    super.key,
    required this.message,
    this.isSuccess = true,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? StateColors.success : StateColors.error;
    final icon = isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close_rounded,
                color: color.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
