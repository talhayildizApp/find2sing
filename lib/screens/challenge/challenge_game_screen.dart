import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/challenge_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/challenge_service.dart';
import '../../services/haptic_service.dart';
import '../../services/rewards_service.dart';
import '../../widgets/challenge_ui_components.dart';
import 'challenge_result_screen.dart';

/// Challenge Game Screen - Premium UI Refactor
/// 
/// Features:
/// - Soft cloudy background with glass cards
/// - Searchable bottom sheet pickers (not long column lists)
/// - Always visible "Bulduğun Şarkılar" section
/// - Consistent header with mode pill + timer pill
/// - Freeze overlay for wrong answers
class ChallengeGameScreen extends StatefulWidget {
  final ChallengeModel challenge;
  final ChallengePlayMode playMode;
  final ChallengeSingleMode singleMode;

  const ChallengeGameScreen({
    super.key,
    required this.challenge,
    this.playMode = ChallengePlayMode.solo,
    this.singleMode = ChallengeSingleMode.relax,
  });

  @override
  State<ChallengeGameScreen> createState() => _ChallengeGameScreenState();
}

class _ChallengeGameScreenState extends State<ChallengeGameScreen>
    with TickerProviderStateMixin {
  final ChallengeService _challengeService = ChallengeService();
  final RewardsService _rewardsService = RewardsService();
  final Random _random = Random();

  // Challenge joker state (local copy for UI)
  List<bool> _challengeJokers = [false, false, false];

  // Game state
  List<ChallengeSongModel> _allSongs = [];
  List<ChallengeSongModel> _remainingSongs = [];
  final List<ChallengeSongModel> _solvedSongs = [];
  final Set<String> _solvedSongIds = {};

  String _currentWord = '';
  List<ChallengeSongModel> _validSongsForWord = [];

  // Selection state
  String? _selectedArtist;
  ChallengeSongModel? _selectedSong;
  List<String> _artistList = [];

  // Timing
  int _totalSeconds = 0;
  int _roundSeconds = 30;
  int _freezeSeconds = 0;
  int _totalFreezeTime = 3;
  Timer? _timer;

  // Scoring (Real mode)
  int _score = 0;
  int _correctCount = 0;
  int _wrongCount = 0;

  // Relax mode progressive freeze
  int _currentFreezeTime = 1;

  // UI state
  bool _isLoading = true;
  bool _isFinished = false;
  bool _isFrozen = false;
  bool _isSubmitting = false;

  // Feedback state
  String? _feedbackMessage;
  bool? _feedbackIsCorrect;
  String? _feedbackBonus;
  bool _showFeedback = false;

  // Mode settings
  int get _totalTimeLimit => 5 * 60; // 5 minutes for Time Race
  // Round time: Real mode = 15s, Relax mode = 30s
  int get _roundTimeLimit => widget.singleMode == ChallengeSingleMode.real ? 15 : 30;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _challengeService.getSongsForChallenge(widget.challenge.id);
      
      if (!mounted) return;
      
      setState(() {
        _allSongs = songs;
        _remainingSongs = List.from(songs);
        _isLoading = false;
      });

      _selectNextWord();
      _startTimer();
      HapticService.gameStart();
    } catch (e) {
      debugPrint('Error loading songs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectNextWord() {
    if (_remainingSongs.isEmpty) {
      _finishGame();
      return;
    }

    // Get available words from topKeywords
    final availableWords = <String>{};
    for (final song in _remainingSongs) {
      if (song.topKeywords.isNotEmpty) {
        availableWords.addAll(song.topKeywords);
      } else if (song.keywords.isNotEmpty) {
        availableWords.addAll(song.keywords);
      }
    }

    if (availableWords.isEmpty) {
      _finishGame();
      return;
    }

    // Random word selection
    final wordList = availableWords.toList();
    final word = wordList[_random.nextInt(wordList.length)];

    // Find valid songs for this word
    final validSongs = _remainingSongs.where((song) {
      return song.containsWord(word) && !_solvedSongIds.contains(song.id);
    }).toList();

    if (validSongs.isEmpty) {
      // Try again with different word
      if (wordList.length > 1) {
        _selectNextWord();
        return;
      }
      _finishGame();
      return;
    }

    // Get unique artists for this word
    final artistSet = validSongs.map((s) => s.artist).toSet().toList()..sort();

    setState(() {
      _currentWord = word;
      _validSongsForWord = validSongs;
      _artistList = artistSet;
      _selectedArtist = null;
      _selectedSong = null;
      _roundSeconds = _roundTimeLimit;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    
    _totalSeconds = widget.singleMode == ChallengeSingleMode.timeRace 
        ? _totalTimeLimit 
        : 0;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isFinished) return;

      setState(() {
        // Handle freeze countdown (but don't block main timer)
        if (_isFrozen) {
          if (_freezeSeconds > 0) {
            _freezeSeconds--;
          } else {
            _isFrozen = false;
            HapticService.freezeEnd();
          }
        }

        // Time Race mode: 5 dakikadan geriye doğru say (countdown)
        // Timer frozen olsa bile devam etmeli
        if (widget.singleMode == ChallengeSingleMode.timeRace) {
          if (_totalSeconds > 0) {
            _totalSeconds--; // Geriye say (countdown)

            // Son 30 saniyede haptic feedback
            if (_totalSeconds <= 30 && _totalSeconds > 0) {
              HapticService.timeCritical();
            }
          } else {
            // Süre bitti - oyunu bitir
            _finishGame();
          }
        }

        // Round timer for Relax and Real modes
        // Frozen durumda round timer'ı durdur ama genel süreyi say
        if (widget.singleMode != ChallengeSingleMode.timeRace) {
          // Genel süreyi artır (elapsed time) - frozen olsa bile
          _totalSeconds++;

          // Round timer sadece frozen değilse azalsın
          if (!_isFrozen) {
            if (_roundSeconds > 0) {
              _roundSeconds--;

              if (_roundSeconds <= 5) {
                HapticService.timeCritical();
              }
            } else {
              // Time expired for this word - move to next
              _selectNextWord();
            }
          }
        }
      });
    });
  }

  void _onSubmit() {
    if (_selectedArtist == null || _selectedSong == null || _isFrozen || _isSubmitting) return;

    // Prevent duplicate submissions - check if song already solved
    if (_solvedSongIds.contains(_selectedSong!.id)) return;

    setState(() => _isSubmitting = true);

    // Check if selection is correct
    final isCorrect = _validSongsForWord.any((s) => s.id == _selectedSong!.id);

    if (isCorrect) {
      _handleCorrectAnswer();
    } else {
      _handleWrongAnswer();
    }

    setState(() => _isSubmitting = false);
  }

  void _handleCorrectAnswer() {
    HapticService.correct();
    _currentFreezeTime = 1;

    // Scoring based on mode
    int points = 1;
    String? bonus;

    switch (widget.singleMode) {
      case ChallengeSingleMode.timeRace:
        // Time Race: Sadece hız önemli, puan bildirimi yok
        points = 0; // Time Race'de puan yok
        bonus = null; // Puan bildirimi gösterme
        break;
      case ChallengeSingleMode.relax:
        points = 1;
        break;
      case ChallengeSingleMode.real:
        points = 1;
        break;
    }

    setState(() {
      _score += points;
      _correctCount++;
      _solvedSongs.add(_selectedSong!);
      _solvedSongIds.add(_selectedSong!.id);
      _remainingSongs.removeWhere((s) => s.id == _selectedSong!.id);
      
      _feedbackMessage = 'Doğru! 🎉';
      _feedbackIsCorrect = true;
      _feedbackBonus = bonus;
      _showFeedback = true;
    });

    // Hide feedback and move to next word
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _showFeedback = false);
        _selectNextWord();
      }
    });
  }

  void _handleWrongAnswer() {
    HapticService.wrong();

    // Scoring and freeze based on mode
    int freezeTime = 0;
    int penalty = 0;

    switch (widget.singleMode) {
      case ChallengeSingleMode.timeRace:
        freezeTime = 3;
        break;
      case ChallengeSingleMode.relax:
        // Progressive freeze: 1s, 2s, 3s, 4s...
        freezeTime = _currentFreezeTime;
        _currentFreezeTime = (_currentFreezeTime + 1).clamp(1, 5);
        break;
      case ChallengeSingleMode.real:
        penalty = 3;
        break;
    }

    setState(() {
      _score -= penalty;
      _wrongCount++;
      
      if (freezeTime > 0) {
        _isFrozen = true;
        _freezeSeconds = freezeTime;
        _totalFreezeTime = freezeTime;
        HapticService.freezeStart();
      }
      
      _feedbackMessage = 'Yanlış! ❌';
      _feedbackIsCorrect = false;
      _feedbackBonus = penalty > 0 ? '-$penalty puan' : null;
      _showFeedback = true;
    });

    // Clear selection
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showFeedback = false;
          _selectedArtist = null;
          _selectedSong = null;
        });
      }
    });
  }

  void _finishGame() {
    if (_isFinished) return;

    _timer?.cancel();
    setState(() => _isFinished = true);

    HapticService.challengeComplete();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeResultScreen(
          challenge: widget.challenge,
          mode: widget.singleMode,
          solvedSongs: _solvedSongs,
          totalSongs: _allSongs.length,
          score: _score,
          correctCount: _correctCount,
          wrongCount: _wrongCount,
          durationSeconds: widget.singleMode == ChallengeSingleMode.timeRace 
              ? _totalTimeLimit - _totalSeconds 
              : _totalSeconds,
          timedOut: widget.singleMode == ChallengeSingleMode.timeRace && _totalSeconds <= 0,
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Oyundan Çık'),
        content: const Text('İlerlemeniz kaydedilmeyecek. Çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Çık', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openArtistPicker() {
    if (_isFrozen) return;

    // Filter out solved songs, then get unique artists
    final availableSongs = _remainingSongs.where((s) => !_solvedSongIds.contains(s.id)).toList();
    final artists = availableSongs.map((s) => s.artist).toSet().toList()..sort();

    // Fallback to all artists if no available songs
    final artistsToShow = artists.isNotEmpty ? artists : _artistList;
    if (artistsToShow.isEmpty) return;

    SearchableBottomSheetPicker.show<String>(
      context: context,
      title: 'Sanatçı Seç',
      items: artistsToShow,
      itemLabel: (artist) => artist,
      selectedItem: _selectedArtist,
      searchHint: 'Sanatçı ara...',
      accentColor: ChallengeColors.primaryPurple,
      onSelect: (artist) {
        setState(() {
          _selectedArtist = artist;
          _selectedSong = null;
        });
      },
    );
  }

  void _openSongPicker() {
    if (_isFrozen) return;

    // Filter out solved songs
    final availableSongs = _remainingSongs.where((s) => !_solvedSongIds.contains(s.id)).toList();

    // Fallback to remaining songs if no available
    final baseSongs = availableSongs.isNotEmpty ? availableSongs : _remainingSongs;
    if (baseSongs.isEmpty) return;

    // Show filtered songs if artist is selected, otherwise show all available songs
    final songsToShow = _selectedArtist != null
        ? baseSongs.where((s) => s.artist == _selectedArtist).toList()
        : baseSongs;

    if (songsToShow.isEmpty) return;

    SearchableBottomSheetPicker.show<ChallengeSongModel>(
      context: context,
      title: 'Şarkı Seç',
      items: songsToShow,
      itemLabel: (song) => song.title,
      itemSubtitle: (song) => song.artist,
      selectedItem: _selectedSong,
      searchHint: 'Şarkı ara...',
      accentColor: ChallengeColors.primaryPurple,
      onSelect: (song) {
        setState(() {
          _selectedSong = song;
          // Auto-select artist when song is selected
          _selectedArtist = song.artist;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          _buildBackground(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header - Just back button
                _buildHeader(),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // HERO WORD - Glowing card with timer
                        // Time Race: 5 dakika countdown + arc
                        // Relax/Real: round timer only (genel süre header'da)
                        Center(
                          child: WordHeroCard(
                            word: _currentWord,
                            categoryName: null,
                            // Time Race: 5 dakika countdown (arc var)
                            // Relax/Real: round timer (countdown, arc var)
                            timerSeconds: widget.singleMode == ChallengeSingleMode.timeRace
                                ? _totalSeconds  // Time Race: 5 dk countdown
                                : _roundSeconds,
                            totalSeconds: widget.singleMode == ChallengeSingleMode.timeRace
                                ? _totalTimeLimit  // Time Race: 5 dakika = 300 saniye
                                : _roundTimeLimit,
                            // Bottom badge kaldırıldı - genel süre header'a taşındı
                            gameTimeSeconds: null,
                            isGameTimeCountdown: false,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Selection card with yan yana pickers + Onayla
                        SelectionInputCard(
                          selectedArtist: _selectedArtist,
                          selectedSong: _selectedSong?.title,
                          enabled: !_isFrozen,
                          onArtistTap: _openArtistPicker,
                          onSongTap: _openSongPicker,
                          onSubmit: _onSubmit,
                          isSubmitting: _isSubmitting,
                        ),

                        const SizedBox(height: 16),

                        // Solved songs - white card
                        SolvedSongsCard(
                          songs: _solvedSongs,
                          maxVisible: 4,
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Bottom stats bar
                _buildBottomStats(),
              ],
            ),
          ),

          // Freeze overlay
          if (_isFrozen)
            Positioned.fill(
              child: ChallengeFreezeOverlay(
                secondsLeft: _freezeSeconds,
                totalSeconds: _totalFreezeTime,
              ),
            ),

          // Feedback toast
          if (_showFeedback && _feedbackMessage != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
              left: 40,
              right: 40,
              child: Center(
                child: ChallengeFeedbackToast(
                  message: _feedbackMessage!,
                  isCorrect: _feedbackIsCorrect ?? false,
                  bonus: _feedbackBonus,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base image
        Image.asset(
          'assets/images/bg_music_clouds.png',
          fit: BoxFit.cover,
        ),
        // Soft overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.25),
                Colors.white.withValues(alpha:0.1),
                ChallengeColors.softPurple.withValues(alpha:0.3),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          Center(
            child: GlassCard(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: ChallengeColors.primaryPurple,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Şarkılar yükleniyor...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ChallengeColors.darkPurple,
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sol: Back button
          GestureDetector(
            onTap: _showExitDialog,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF394272),
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Orta: Mode + Kategori badge (Time Race | Tarkan)
          Expanded(
            child: Center(
              child: _buildModeCategoryBadge(),
            ),
          ),

          const SizedBox(width: 12),

          // Sağ: Symmetry placeholder (tüm modlar için)
          // Time Race: timer güneşte
          // Relax: elapsed time bottom bar'da
          // Real: puan bottom bar'da
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// Mode + Kategori badge - "Time Race | Tarkan" format
  Widget _buildModeCategoryBadge() {
    // Mode renkleri - mor yerine daha canlı renkler
    Color modeColor;
    IconData modeIcon;
    String modeName;

    switch (widget.singleMode) {
      case ChallengeSingleMode.timeRace:
        modeColor = const Color(0xFFFF6B6B); // Coral red
        modeIcon = Icons.flash_on_rounded;
        modeName = 'Time Race';
        break;
      case ChallengeSingleMode.relax:
        modeColor = const Color(0xFF4ECDC4); // Teal
        modeIcon = Icons.spa_rounded;
        modeName = 'Relax';
        break;
      case ChallengeSingleMode.real:
        modeColor = const Color(0xFFFFB347); // Orange
        modeIcon = Icons.emoji_events_rounded;
        modeName = 'Real';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode icon + name
          Icon(
            modeIcon,
            color: modeColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            modeName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: modeColor,
            ),
          ),

          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 1,
            height: 16,
            color: Colors.grey.shade300,
          ),

          // Category icon + name
          const Icon(
            Icons.person_rounded,
            color: Color(0xFF394272),
            size: 16,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              widget.challenge.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF394272),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStats() {
    final solvedCount = _solvedSongs.length;
    final totalSlots = _allSongs.length.clamp(0, 10);
    final showScore = widget.singleMode == ChallengeSingleMode.real;
    final showElapsedTime = widget.singleMode == ChallengeSingleMode.relax;

    // Current dot color based on mode
    Color currentDotColor;
    switch (widget.singleMode) {
      case ChallengeSingleMode.timeRace:
        currentDotColor = const Color(0xFFFF6B6B); // Coral
        break;
      case ChallengeSingleMode.relax:
        currentDotColor = const Color(0xFF4ECDC4); // Teal
        break;
      case ChallengeSingleMode.real:
        currentDotColor = const Color(0xFFFFB347); // Orange
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Sol: Progress dots + şarkı sayısı
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress dots
                if (totalSlots > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(totalSlots.clamp(0, 10), (index) {
                      final isFilled = index < solvedCount;
                      final isNext = index == solvedCount;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? const Color(0xFF4CAF50)
                              : isNext
                                  ? currentDotColor.withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.15),
                          border: Border.all(
                            color: isFilled
                                ? const Color(0xFF4CAF50)
                                : isNext
                                    ? currentDotColor
                                    : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: isFilled
                            ? const Icon(
                                Icons.check_rounded,
                                size: 10,
                                color: Colors.white,
                              )
                            : null,
                      );
                    }),
                  ),

                const SizedBox(height: 6),

                // Şarkı sayısı
                Text(
                  '$solvedCount/${_allSongs.length} şarkı',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF394272).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // Sağ: Badge (mode'a göre)
          // Real: Puan badge
          // Relax: Elapsed time badge
          if (showScore) ...[
            Container(
              margin: const EdgeInsets.only(left: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB347), Color(0xFFFFCC80)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB347).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_score',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (showElapsedTime) ...[
            Container(
              margin: const EdgeInsets.only(left: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF7EDDD6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_totalSeconds ~/ 60}:${(_totalSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
