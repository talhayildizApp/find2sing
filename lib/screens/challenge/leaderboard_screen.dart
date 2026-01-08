import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/challenge_model.dart';
import '../../services/challenge_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final ChallengeModel challenge;

  const LeaderboardScreen({
    super.key,
    required this.challenge,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ChallengeService _challengeService = ChallengeService();
  
  List<LeaderboardEntry> _entries = [];
  int? _userRank;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final entries = await _challengeService.getLeaderboard(widget.challenge.id);
      
      final authProvider = context.read<AuthProvider>();
      final uid = authProvider.user?.uid;
      
      int? rank;
      if (uid != null) {
        rank = await _challengeService.getUserRank(widget.challenge.id, uid);
      }

      setState(() {
        _entries = entries;
        _userRank = rank;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUid = authProvider.user?.uid;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE5B4), Color(0xFFFFF8E7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF394272)),
                    ),
                    Expanded(
                      child: Text(
                        'Liderlik Tablosu',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF394272),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Challenge info
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB958).withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.emoji_events, color: Color(0xFFFFB958), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.challenge.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF394272),
                            ),
                          ),
                          const Text(
                            'Real Challenge Modu',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6C6FA4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_userRank != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB958),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#$_userRank',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Leaderboard list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _entries.isEmpty
                        ? _buildEmptyState()
                        : _buildLeaderboardList(currentUid),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.leaderboard, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Henüz kayıt yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C6FA4),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Real Challenge modunda oynayarak\nliderlik tablosuna gir!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6C6FA4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(String? currentUid) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final rank = index + 1;
        final isCurrentUser = entry.uid == currentUid;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCurrentUser 
                ? const Color(0xFFFFB958).withValues(alpha:0.15)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isCurrentUser 
                ? Border.all(color: const Color(0xFFFFB958), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 40,
                child: _buildRankBadge(rank),
              ),
              const SizedBox(width: 12),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCurrentUser ? 'Sen' : 'Oyuncu ${entry.uid.substring(0, 6)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                        color: const Color(0xFF394272),
                      ),
                    ),
                    Text(
                      _formatDuration(entry.bestDurationMs),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C6FA4),
                      ),
                    ),
                  ],
                ),
              ),

              // Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getScoreColor(entry.bestScore).withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entry.bestScore}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _getScoreColor(entry.bestScore),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFFFD700),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text('🥇', style: TextStyle(fontSize: 20)),
        ),
      );
    } else if (rank == 2) {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFC0C0C0),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text('🥈', style: TextStyle(fontSize: 20)),
        ),
      );
    } else if (rank == 3) {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFCD7F32),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text('🥉', style: TextStyle(fontSize: 20)),
        ),
      );
    } else {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$rank',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6C6FA4),
            ),
          ),
        ),
      );
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 20) return const Color(0xFF4CAF50);
    if (score >= 10) return const Color(0xFFFFB958);
    if (score >= 0) return const Color(0xFF6C6FA4);
    return Colors.red;
  }

  String _formatDuration(int ms) {
    final seconds = ms ~/ 1000;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
