import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../models/match_intent_model.dart';
import '../../services/matchmaking_service.dart';
import '../../services/player_id_service.dart';
import 'waiting_screen.dart';

class OnlineMatchScreen extends StatefulWidget {
  final String? prefillOpponentId;
  final MatchMode mode;
  final String? challengeId;
  final ModeVariant? modeVariant;

  const OnlineMatchScreen({
    super.key,
    this.prefillOpponentId,
    this.mode = MatchMode.friendsWord,
    this.challengeId,
    this.modeVariant,
  });

  @override
  State<OnlineMatchScreen> createState() => _OnlineMatchScreenState();
}

class _OnlineMatchScreenState extends State<OnlineMatchScreen> {
  final _opponentIdController = TextEditingController();
  final _matchmakingService = MatchmakingService();
  final _playerIdService = PlayerIdService();

  String? _myPlayerId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyPlayerId();
    if (widget.prefillOpponentId != null) {
      _opponentIdController.text = widget.prefillOpponentId!;
    }
  }

  @override
  void dispose() {
    _opponentIdController.dispose();
    super.dispose();
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

    if (opponentId.isEmpty) {
      setState(() => _errorMessage = 'Rakip ID giriniz');
      return;
    }

    if (!_playerIdService.isValidPlayerIdFormat(opponentId)) {
      setState(() => _errorMessage = 'Geçersiz ID formatı (örn: MOON-1234)');
      return;
    }

    if (_myPlayerId == opponentId) {
      setState(() => _errorMessage = 'Kendinizle eşleşemezsiniz');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
      );

      if (intent == null) throw Exception('Eşleşme başlatılamadı');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitingScreen(
              intentId: intent.id,
              opponentPlayerId: opponentId,
              mode: widget.mode,
            ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID kopyalandı!')),
    );
  }

  void _sharePlayerId() {
    if (_myPlayerId == null) return;
    final link = 'find2sing://match?opponentId=$_myPlayerId';
    Share.share(
      'Find2Sing\'de benimle oyna!\n\nOyuncu ID: $_myPlayerId\n\nLink: $link',
      subject: 'Find2Sing Davet',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isAuthenticated;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF394272)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.mode == MatchMode.friendsWord
              ? 'Online Eşleşme'
              : 'Challenge Online',
          style: const TextStyle(
            color: Color(0xFF394272),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: !isLoggedIn
          ? _buildLoginRequired()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMyIdCard(),
                  const SizedBox(height: 32),
                  _buildOpponentIdInput(),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildStartButton(),
                  const SizedBox(height: 24),
                  _buildInstructions(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: Color(0xFFCAB7FF)),
          const SizedBox(height: 16),
          const Text(
            'Online oynamak için\ngiriş yapmalısınız',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Color(0xFF394272)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCAB7FF),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Giriş Yap', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMyIdCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCAB7FF), Color(0xFF9B7EDE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCAB7FF).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Senin Oyuncu ID\'n',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _myPlayerId == null
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  _myPlayerId!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(Icons.copy, 'Kopyala', _copyPlayerId),
              const SizedBox(width: 16),
              _buildActionButton(Icons.share, 'Paylaş', _sharePlayerId),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildOpponentIdInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rakip Oyuncu ID',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF394272),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _opponentIdController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          decoration: InputDecoration(
            hintText: 'MOON-1234',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _startMatch,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF394272),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Text(
              'Eşleşmeyi Başlat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nasıl Çalışır?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF394272)),
          ),
          const SizedBox(height: 12),
          _buildInstructionItem('1', 'Oyuncu ID\'nizi arkadaşınızla paylaşın'),
          _buildInstructionItem('2', 'Arkadaşınızın ID\'sini girin'),
          _buildInstructionItem('3', 'Her ikiniz de birbirinizin ID\'sini girdiğinde eşleşme başlar'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: Color(0xFFCAB7FF), shape: BoxShape.circle),
            child: Center(
              child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF6C6FA4)))),
        ],
      ),
    );
  }
}
