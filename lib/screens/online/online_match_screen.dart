import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../models/match_intent_model.dart';
import '../../services/matchmaking_service.dart';
import '../../services/player_id_service.dart';
import '../../widgets/online_game_ui_components.dart';
import 'waiting_screen.dart';

/// Online Match Screen with improved UX
/// - "Davet Kodu" language instead of "Oyuncu ID"
/// - Clear feedback on copy/share actions
/// - Real-time input validation
/// - Context-aware CTA text
/// - Collapsible instructions
/// - Challenge/normal game badge
class OnlineMatchScreen extends StatefulWidget {
  final String? prefilledOpponentId;
  final MatchMode mode;
  final String? challengeId;
  final ModeVariant? modeVariant;
  final String? challengeName;

  // Friends word game end conditions
  final String? endCondition;
  final int? targetRounds;
  final int? timeMinutes;

  const OnlineMatchScreen({
    super.key,
    this.prefilledOpponentId,
    this.mode = MatchMode.friendsWord,
    this.challengeId,
    this.modeVariant,
    this.challengeName,
    this.endCondition,
    this.targetRounds,
    this.timeMinutes,
  });

  @override
  State<OnlineMatchScreen> createState() => _OnlineMatchScreenState();
}

class _OnlineMatchScreenState extends State<OnlineMatchScreen>
    with SingleTickerProviderStateMixin {
  final _opponentIdController = TextEditingController();
  final _matchmakingService = MatchmakingService();
  final _playerIdService = PlayerIdService();

  String? _myPlayerId;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showInstructions = false;
  bool _copied = false;
  bool _isValidInput = false;

  late AnimationController _copyFeedbackController;

  @override
  void initState() {
    super.initState();
    _loadMyPlayerId();
    
    _copyFeedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.prefilledOpponentId != null) {
      _opponentIdController.text = widget.prefilledOpponentId!;
      _validateInput(widget.prefilledOpponentId!);
    }

    _opponentIdController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _opponentIdController.dispose();
    _copyFeedbackController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final value = _opponentIdController.text.trim().toUpperCase();
    _validateInput(value);
  }

  void _validateInput(String value) {
    setState(() {
      _errorMessage = null;
      if (value.isEmpty) {
        _isValidInput = false;
      } else if (!_playerIdService.isValidPlayerIdFormat(value)) {
        _isValidInput = false;
        if (value.length >= 4) {
          _errorMessage = 'Format: XXXX-0000';
        }
      } else if (_myPlayerId == value) {
        _isValidInput = false;
        _errorMessage = 'Kendi kodunuzu giremezsiniz';
      } else {
        _isValidInput = true;
      }
    });
  }

  Future<void> _loadMyPlayerId() async {
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.user?.uid;
    if (uid == null) return;

    final playerId = await _playerIdService.ensurePlayerId(uid);
    if (mounted) {
      setState(() => _myPlayerId = playerId);
    }
  }

  Future<void> _startMatch() async {
    final opponentId = _opponentIdController.text.trim().toUpperCase();

    if (!_isValidInput) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.mediumImpact();

    try {
      final authProvider = context.read<AuthProvider>();
      final uid = authProvider.user?.uid;
      if (uid == null) throw Exception('Giriş yapmalısınız');

      final intent = await _matchmakingService.createIntent(
        fromUid: uid,
        fromPlayerId: _myPlayerId!,
        toPlayerId: opponentId,
        mode: widget.mode,
        challengeId: widget.challengeId,
        modeVariant: widget.modeVariant,
        endCondition: widget.endCondition,
        targetRounds: widget.targetRounds,
        timeMinutes: widget.timeMinutes,
      );

      if (intent == null) throw Exception('Davet gönderilemedi');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => WaitingScreen(
              intentId: intent.id,
              myPlayerId: _myPlayerId!,
              opponentPlayerId: opponentId,
              mode: widget.mode,
              challengeName: widget.challengeName,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _copyPlayerId() {
    if (_myPlayerId == null) return;
    
    Clipboard.setData(ClipboardData(text: _myPlayerId!));
    HapticFeedback.lightImpact();
    
    setState(() => _copied = true);
    _copyFeedbackController.forward(from: 0);
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _sharePlayerId() {
    if (_myPlayerId == null) return;
    
    HapticFeedback.lightImpact();
    
    final link = 'find2sing://match?opponentId=$_myPlayerId';
    final modeText = widget.mode == MatchMode.challengeOnline 
        ? (widget.challengeName ?? 'Challenge') 
        : 'Arkadaşla Oyna';
    
    Share.share(
      '🎵 Find2Sing\'de $modeText modunda benimle oyna!\n\n'
      '📋 Davet Kodum: $_myPlayerId\n\n'
      '🔗 $link',
      subject: 'Find2Sing Davet',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isAuthenticated;
    final isChallenge = widget.mode == MatchMode.challengeOnline;

    return OnlineGameScaffold(
      showBackButton: true,
      titleWidget: Column(
        children: [
          const Text(
            'Arkadaşını Davet Et',
            style: TextStyle(
              color: OnlineGameColors.darkPurple,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          if (isChallenge && widget.challengeName != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: OnlineGameColors.accentOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚔️ ${widget.challengeName}',
                style: const TextStyle(
                  color: OnlineGameColors.accentOrange,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      child: !isLoggedIn
          ? _buildLoginRequired()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildMyCodeCard(),
                  const SizedBox(height: 28),
                  _buildJoinSection(),
                  const SizedBox(height: 20),
                  _buildInstructionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              child: const Icon(Icons.lock_outline, size: 50, color: Color(0xFFCAB7FF)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Giriş Gerekli',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF394272),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Arkadaşlarınla oynamak için\nhesabına giriş yap',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: const Color(0xFF6C6FA4).withValues(alpha:0.8),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCAB7FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Giriş Yap',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCodeCard() {
    if (_myPlayerId == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF2D2D44),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: OnlineGameColors.goldAccent,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return BackstagePassCard(
      code: _myPlayerId!,
      onCopy: _copyPlayerId,
      onShare: _sharePlayerId,
      copied: _copied,
    );
  }

  Widget _buildJoinSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB958).withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    const Text(
                      'DAVETE KATIL',
                      style: TextStyle(
                        color: Color(0xFFFFB958),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Label
          const Text(
            'Arkadaşının Davet Kodu',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF394272),
            ),
          ),
          const SizedBox(height: 10),
          
          // Input
          TextField(
            controller: _opponentIdController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Color(0xFF394272),
            ),
            decoration: InputDecoration(
              hintText: 'XXXX-0000',
              hintStyle: TextStyle(
                color: Colors.grey.shade300,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: const Color(0xFFF5F3FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _isValidInput 
                      ? const Color(0xFF4CAF50).withValues(alpha:0.5) 
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _errorMessage != null 
                      ? const Color(0xFFF85149) 
                      : const Color(0xFFCAB7FF),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              suffixIcon: _isValidInput
                  ? const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24),
                    )
                  : null,
            ),
          ),
          
          // Error message
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFF85149), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFF85149),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 20),
          
          // CTA Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading || !_isValidInput ? null : _startMatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF394272),
                disabledBackgroundColor: const Color(0xFF394272).withValues(alpha:0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: _isValidInput ? 4 : 0,
                shadowColor: const Color(0xFF394272).withValues(alpha:0.3),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isValidInput ? Icons.play_arrow_rounded : Icons.search_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isValidInput ? 'Eşleşmeyi Başlat' : 'Kodu Gir',
                          style: const TextStyle(
                            fontSize: 16,
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
    );
  }

  Widget _buildInstructionsSection() {
    return GestureDetector(
      onTap: () => setState(() => _showInstructions = !_showInstructions),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, color: Color(0xFF6C6FA4), size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Nasıl Çalışır?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF394272),
                    ),
                  ),
                ),
                Icon(
                  _showInstructions ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF6C6FA4),
                ),
              ],
            ),
            if (_showInstructions) ...[
              const SizedBox(height: 16),
              _buildInstructionStep(
                '1',
                'Paylaş',
                'Davet kodunu arkadaşına gönder',
                Icons.share_rounded,
              ),
              _buildInstructionStep(
                '2',
                'Bekle',
                'Arkadaşın senin kodunu girsin',
                Icons.hourglass_top_rounded,
              ),
              _buildInstructionStep(
                '3',
                'Oyna',
                'Eşleşince oyun otomatik başlar',
                Icons.sports_esports_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFCAB7FF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF394272),
                    fontSize: 14,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: const Color(0xFF6C6FA4).withValues(alpha:0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: const Color(0xFFCAB7FF), size: 20),
        ],
      ),
    );
  }
}
