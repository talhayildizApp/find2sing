import 'package:flutter/material.dart';
import '../../services/firestore_seed_service.dart';

/// Geliştirici/Admin ekranı
/// Firestore'a örnek veri yüklemek için kullanılır
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

  Future<void> _seedAll() async {
    setState(() {
      _isLoading = true;
      _status = 'Veriler yükleniyor...';
    });

    try {
      await _seedService.seedAll();
      setState(() {
        _status = '✅ Tüm veriler başarıyla yüklendi!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Hata: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Dikkat!'),
        content: const Text(
          'Tüm kategori, challenge ve şarkı verileri silinecek!\n\nEmin misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _status = 'Veriler siliniyor...';
    });

    try {
      await _seedService.clearAll();
      setState(() {
        _status = '✅ Tüm veriler silindi!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Hata: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛠️ Developer Panel'),
        backgroundColor: const Color(0xFF394272),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Uyarı kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bu ekran sadece geliştirme amaçlıdır.\nProduction\'da kaldırılmalıdır.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Seed butonu
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _seedAll,
                icon: const Icon(Icons.cloud_upload),
                label: const Text(
                  'Örnek Verileri Yükle',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Clear butonu
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _clearAll,
                icon: const Icon(Icons.delete_forever),
                label: const Text(
                  'Tüm Verileri Sil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Loading / Status
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),

            if (_status.isNotEmpty && !_isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status.contains('✅')
                      ? Colors.green.shade50
                      : _status.contains('❌')
                          ? Colors.red.shade50
                          : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    fontSize: 14,
                    color: _status.contains('✅')
                        ? Colors.green.shade700
                        : _status.contains('❌')
                            ? Colors.red.shade700
                            : Colors.blue.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const Spacer(),

            // Yüklenen veriler bilgisi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yüklenecek Veriler:',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text('• 5 Kategori (3 TR, 2 EN)'),
                  Text('• 13 Challenge (9 TR, 4 EN)'),
                  Text('• 65 Şarkı'),
                  Text('• 4 Ücretsiz Challenge'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
