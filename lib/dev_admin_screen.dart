import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_seed_service.dart';

/// Geliştirici/Admin ekranı
/// Firestore'a örnek veri yüklemek ve test işlemleri için kullanılır
/// NOT: Production'da bu ekranı kaldır veya gizle!
class DevAdminScreen extends StatefulWidget {
  const DevAdminScreen({super.key});

  @override
  State<DevAdminScreen> createState() => _DevAdminScreenState();
}

class _DevAdminScreenState extends State<DevAdminScreen> {
  final FirestoreSeedService _seedService = FirestoreSeedService();
  bool _isLoading = false;
  String _status = '';
  String _currentOperation = '';

  // İşlem logları
  final List<_LogEntry> _logs = [];

  void _addLog(String message, {bool isError = false, bool isSuccess = false}) {
    setState(() {
      _logs.insert(0, _LogEntry(
        message: message,
        time: DateTime.now(),
        isError: isError,
        isSuccess: isSuccess,
      ));
      // Max 50 log tut
      if (_logs.length > 50) _logs.removeLast();
    });
  }

  Future<void> _seedCategories() async {
    setState(() {
      _isLoading = true;
      _currentOperation = 'Kategoriler yükleniyor...';
    });
    _addLog('📁 Kategoriler yükleniyor...');

    try {
      await _seedService.seedCategories();
      _addLog('✅ Kategoriler başarıyla yüklendi!', isSuccess: true);
    } catch (e) {
      _addLog('❌ Hata: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
        _currentOperation = '';
      });
    }
  }

  Future<void> _seedChallenges() async {
    setState(() {
      _isLoading = true;
      _currentOperation = 'Challenge\'lar yükleniyor...';
    });
    _addLog('🎮 Challenge\'lar yükleniyor...');

    try {
      await _seedService.seedChallenges();
      _addLog('✅ Challenge\'lar başarıyla yüklendi!', isSuccess: true);
    } catch (e) {
      _addLog('❌ Hata: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
        _currentOperation = '';
      });
    }
  }

  Future<void> _seedSongs() async {
    setState(() {
      _isLoading = true;
      _currentOperation = 'Şarkılar yükleniyor...';
    });
    _addLog('🎵 Örnek şarkılar yükleniyor...');

    try {
      await _seedService.seedSampleSongs();
      _addLog('✅ Şarkılar başarıyla yüklendi!', isSuccess: true);
    } catch (e) {
      _addLog('❌ Hata: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
        _currentOperation = '';
      });
    }
  }

  Future<void> _seedAll() async {
    setState(() {
      _isLoading = true;
      _currentOperation = 'Tüm veriler yükleniyor...';
    });
    _addLog('🚀 Tüm veriler yükleniyor...');

    try {
      await _seedService.seedAll();
      _addLog('✅ Kategoriler ve Challenge\'lar yüklendi!', isSuccess: true);
      
      await _seedService.seedSampleSongs();
      _addLog('✅ Örnek şarkılar yüklendi!', isSuccess: true);
      
      _addLog('🎉 Tüm işlemler tamamlandı!', isSuccess: true);
    } catch (e) {
      _addLog('❌ Hata: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
        _currentOperation = '';
      });
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Dikkat!'),
          ],
        ),
        content: const Text(
          'Tüm kategori, challenge ve şarkı verileri silinecek!\n\nBu işlem geri alınamaz. Emin misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _currentOperation = 'Veriler siliniyor...';
    });
    _addLog('🗑️ Tüm veriler siliniyor...');

    try {
      await _seedService.clearAll();
      _addLog('✅ Tüm veriler silindi!', isSuccess: true);
    } catch (e) {
      _addLog('❌ Hata: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
        _currentOperation = '';
      });
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context, user),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Uyarı kartı
                        _buildWarningCard(),

                        const SizedBox(height: 20),

                        // Hızlı işlemler
                        _buildQuickActions(),

                        const SizedBox(height: 20),

                        // Detaylı işlemler
                        _buildDetailedActions(),

                        const SizedBox(height: 20),

                        // Yüklenecek veriler bilgisi
                        _buildDataInfo(),

                        const SizedBox(height: 20),

                        // Log konsolu
                        _buildLogConsole(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.3),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha:0.1)),
        ),
      ),
      child: Row(
        children: [
          // Geri butonu
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Başlık
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🛠️ Developer Panel',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Firestore Seed & Test',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),

          // Kullanıcı bilgisi
          if (user != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha:0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    user.displayName ?? 'User',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha:0.2),
            Colors.red.withValues(alpha:0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha:0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha:0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Geliştirici Modu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Bu ekran sadece test amaçlıdır. Production\'da kaldırılmalıdır.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hızlı İşlemler',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.rocket_launch,
                label: 'Tümünü Yükle',
                color: Colors.green,
                onTap: _isLoading ? null : _seedAll,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.delete_forever,
                label: 'Tümünü Sil',
                color: Colors.red,
                onTap: _isLoading ? null : _clearAll,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detaylı İşlemler',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSmallActionButton(
                icon: Icons.folder,
                label: 'Kategoriler',
                color: Colors.blue,
                onTap: _isLoading ? null : _seedCategories,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSmallActionButton(
                icon: Icons.emoji_events,
                label: 'Challenge',
                color: Colors.purple,
                onTap: _isLoading ? null : _seedChallenges,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSmallActionButton(
                icon: Icons.music_note,
                label: 'Şarkılar',
                color: Colors.pink,
                onTap: _isLoading ? null : _seedSongs,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha:0.3),
              color.withValues(alpha:0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha:0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha:0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha:0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white54, size: 18),
              SizedBox(width: 8),
              Text(
                'Yüklenecek Veriler',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('📁', 'Kategoriler', '4 adet (TR)'),
          _buildInfoRow('🎮', 'Challenge\'lar', '21 adet'),
          _buildInfoRow('🎵', 'Örnek Şarkılar', '~30 adet'),
          _buildInfoRow('🆓', 'Ücretsiz Challenge', '4 adet'),
          const Divider(color: Colors.white24, height: 24),
          const Text(
            'Sanatçılar: Duman, Athena, Sertab Erener, Sezen Aksu, Müslüm Gürses, Ceza, Sagopa Kajmer, Tarkan',
            style: TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.white60),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogConsole() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha:0.1)),
      ),
      child: Column(
        children: [
          // Console header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: Colors.white54, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Konsol',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                if (_logs.isNotEmpty)
                  GestureDetector(
                    onTap: _clearLogs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Temizle',
                        style: TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Console content
          Container(
            height: 200,
            padding: const EdgeInsets.all(12),
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz log yok...',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    reverse: false,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}:${log.time.second.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: Colors.white.withValues(alpha:0.3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                log.message,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: log.isError
                                      ? Colors.red.shade300
                                      : log.isSuccess
                                          ? Colors.green.shade300
                                          : Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha:0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha:0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFFCAB7FF),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _currentOperation,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Log entry model
class _LogEntry {
  final String message;
  final DateTime time;
  final bool isError;
  final bool isSuccess;

  _LogEntry({
    required this.message,
    required this.time,
    this.isError = false,
    this.isSuccess = false,
  });
}
