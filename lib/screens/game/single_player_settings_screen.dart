import 'package:flutter/material.dart';
import 'game_config.dart';          // SongMode & EndCondition
import 'single_game_screen.dart';   // Tek oyunculu oyun ekranı

class SinglePlayerSettingsScreen extends StatefulWidget {
  const SinglePlayerSettingsScreen({super.key});

  @override
  State<SinglePlayerSettingsScreen> createState() =>
      _SinglePlayerSettingsScreenState();
}

class _SinglePlayerSettingsScreenState
    extends State<SinglePlayerSettingsScreen> {
  int _countdownSeconds = 30;
  SongMode _songMode = SongMode.single;
  EndCondition _endCondition = EndCondition.songCount;
  int _songTarget = 10;
  int _timeMinutes = 3;
  int _wordChangeCount = 3;

  // Ortak integer picker bottom sheet
  Future<int?> _showIntPicker({
    required String title,
    required String unit,
    required List<int> options,
  }) async {
    return showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...options.map((value) {
                return ListTile(
                  title: Text('$value $unit'),
                  onTap: () => Navigator.pop(context, value),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectCountdown() async {
    final result = await _showIntPicker(
      title: 'Geri Sayım Süresi',
      unit: 'sn',
      options: const [15, 30, 45],
    );
    if (result != null) {
      setState(() {
        _countdownSeconds = result;
      });
    }
  }

  Future<void> _selectSongTarget() async {
    final result = await _showIntPicker(
      title: 'Şarkı Hedefi',
      unit: 'Şarkı',
      options: const [5, 10, 15, 20],
    );
    if (result != null) {
      setState(() {
        _songTarget = result;
      });
    }
  }

  Future<void> _selectTimeMinutes() async {
    final result = await _showIntPicker(
      title: 'Oyun Süresi',
      unit: 'Dakika',
      options: const [1, 3, 5, 10],
    );
    if (result != null) {
      setState(() {
        _timeMinutes = result;
      });
    }
  }

  Future<void> _selectWordChangeCount() async {
    final result = await _showIntPicker(
      title: 'Kelime Değiştirme Hakkı',
      unit: 'Kelime',
      options: const [1, 3, 5],
    );
    if (result != null) {
      setState(() {
        _wordChangeCount = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg_music_clouds.png',
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // üstte küçük logo
                Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/images/logo_find2sing.png',
                    width: 120,
                  ),
                ),
                const SizedBox(height: 8),
                              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    ),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(
                      Icons.home_rounded,
                      size: 18,
                      color: Color(0xFF394272),
                    ),
                    label: const Text(
                      'Ana Menü',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF394272),
                      ),
                    ),
                  ),
                ),
              ),

              ],
            ),
          ),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: Container(
                      width: size.width * 0.9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7FF),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(
                                child: Text(
                                  'Oyun Ayarları',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF394272),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Geri sayım süresi
                              _SettingsCard(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _selectCountdown,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: Color(0xFF6C6FA4),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Geri Sayım Süresi',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF394272),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '$_countdownSeconds sn',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF394272),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.expand_more,
                                        size: 20,
                                        color: Color(0xFF6C6FA4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Her kelime için kaç şarkı...
                              _SettingsCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Her kelime için kaç şarkı bulacaksın?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF394272),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        _OptionChip(
                                          label: 'Tek',
                                          isSelected:
                                              _songMode == SongMode.single,
                                          onTap: () {
                                            setState(() {
                                              _songMode = SongMode.single;
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 12),
                                        _OptionChip(
                                          label: 'Çoklu',
                                          isSelected:
                                              _songMode == SongMode.multiple,
                                          onTap: () {
                                            setState(() {
                                              _songMode = SongMode.multiple;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Oyun bitiş şartı
                              _SettingsCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.music_note,
                                          color: Color(0xFF6C6FA4),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Oyun Bitiş Şartı',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF394272),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Şarkı bilince
                                    GestureDetector(
                                      onTap: _selectSongTarget,
                                      child: Row(
                                        children: [
                                          Radio<EndCondition>(
                                            value: EndCondition.songCount,
                                            groupValue: _endCondition,
                                            activeColor:
                                                const Color(0xFF6C6FA4),
                                            onChanged: (val) {
                                              setState(() {
                                                _endCondition = val!;
                                              });
                                            },
                                          ),
                                          const Text('Şarkı Bilince'),
                                          const Spacer(),
                                          Text(
                                            '$_songTarget Şarkı',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF394272),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.expand_more,
                                            size: 20,
                                            color: Color(0xFF6C6FA4),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Süre bitince
                                    GestureDetector(
                                      onTap: _selectTimeMinutes,
                                      child: Row(
                                        children: [
                                          Radio<EndCondition>(
                                            value: EndCondition.time,
                                            groupValue: _endCondition,
                                            activeColor:
                                                const Color(0xFF6C6FA4),
                                            onChanged: (val) {
                                              setState(() {
                                                _endCondition = val!;
                                              });
                                            },
                                          ),
                                          const Text('Süre Bitince'),
                                          const Spacer(),
                                          Text(
                                            '$_timeMinutes Dakika',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF394272),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.expand_more,
                                            size: 20,
                                            color: Color(0xFF6C6FA4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Kelime değiştirme hakkı
                              _SettingsCard(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _selectWordChangeCount,
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Kelime Değiştirme Hakkı',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF394272),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '$_wordChangeCount Kelime',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF394272),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.expand_more,
                                        size: 20,
                                        color: Color(0xFF6C6FA4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Başla butonu
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SingleGameScreen(
                                          countdownSeconds:
                                              _countdownSeconds,
                                          songMode: _songMode,
                                          endCondition: _endCondition,
                                          songTarget: _songTarget,
                                          timeMinutes: _timeMinutes,
                                          wordChangeCount:
                                              _wordChangeCount,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFFCAB7FF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 6,
                                  ),
                                  child: const Text(
                                    'Başla',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF394272),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C6FA4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6C6FA4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color:
                isSelected ? Colors.white : const Color(0xFF394272),
          ),
        ),
      ),
    );
  }
}
