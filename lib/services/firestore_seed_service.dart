import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge_model.dart';
import 'pricing_service.dart';

/// Firestore'a örnek veri ekleyen servis
/// NOT: Bu sadece geliştirme/test amaçlıdır!
class FirestoreSeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Tüm örnek verileri ekle
  Future<void> seedAll() async {
    print('🌱 Seed başlıyor...');
    
    // Önce kategorileri ekle
    await seedCategories();
    
    // Sonra challenge'ları ekle
    await seedChallenges();
    
    // Son olarak şarkıları ekle
    await seedSongs();
    
    print('✅ Seed tamamlandı!');
  }

  /// Kategorileri ekle
  Future<void> seedCategories() async {
    print('📁 Kategoriler ekleniyor...');

    final categories = [
      // Türkçe Kategoriler
      {
        'id': 'turkce_pop',
        'title': 'Türkçe Pop',
        'subtitle': 'En sevilen Türkçe pop şarkılar',
        'description': 'Türkiye\'nin en popüler pop şarkıcılarının hit şarkıları',
        'language': 'tr',
        'iconEmoji': '🎤',
        'challengeCount': 5,
        'challengeIds': ['tarkan', 'sezen_aksu', 'ajda_pekkan', 'sertab_erener', 'hadise'],
        'priceUsd': PricingService.calculateCategoryPrice(5),
        'discountPercent': 40.0,
        'isActive': true,
        'sortOrder': 1,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'turkce_rock',
        'title': 'Türkçe Rock',
        'subtitle': 'Anadolu rock\'un efsaneleri',
        'description': 'Türk rock müziğinin en iyi örnekleri',
        'language': 'tr',
        'iconEmoji': '🎸',
        'challengeCount': 4,
        'challengeIds': ['duman', 'mor_ve_otesi', 'teoman', 'manga'],
        'priceUsd': PricingService.calculateCategoryPrice(4),
        'discountPercent': 40.0,
        'isActive': true,
        'sortOrder': 2,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': '90lar_turkce',
        'title': '90\'lar Türkçe',
        'subtitle': 'Nostaljik 90\'lar hitleri',
        'description': '90\'ların unutulmaz Türkçe şarkıları',
        'language': 'tr',
        'iconEmoji': '📻',
        'challengeCount': 3,
        'challengeIds': ['90lar_pop', '90lar_slow', '90lar_dance'],
        'priceUsd': PricingService.calculateCategoryPrice(3),
        'discountPercent': 40.0,
        'isActive': true,
        'sortOrder': 3,
        'createdAt': FieldValue.serverTimestamp(),
      },
      // İngilizce Kategoriler
      {
        'id': 'english_pop',
        'title': 'English Pop',
        'subtitle': 'Global pop hits',
        'description': 'The biggest pop hits from around the world',
        'language': 'en',
        'iconEmoji': '🌍',
        'challengeCount': 4,
        'challengeIds': ['taylor_swift', 'ed_sheeran', 'adele', 'bruno_mars'],
        'priceUsd': PricingService.calculateCategoryPrice(4),
        'discountPercent': 40.0,
        'isActive': true,
        'sortOrder': 1,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'english_rock',
        'title': 'Rock Classics',
        'subtitle': 'Legendary rock bands',
        'description': 'Classic rock hits that never get old',
        'language': 'en',
        'iconEmoji': '🤘',
        'challengeCount': 4,
        'challengeIds': ['queen', 'beatles', 'coldplay', 'u2'],
        'priceUsd': PricingService.calculateCategoryPrice(4),
        'discountPercent': 40.0,
        'isActive': true,
        'sortOrder': 2,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final category in categories) {
      final id = category['id'] as String;
      await _db.collection('categories').doc(id).set(category);
      print('  ✓ Kategori eklendi: $id');
    }
  }

  /// Challenge'ları ekle
  Future<void> seedChallenges() async {
    print('🏆 Challenge\'lar ekleniyor...');

    final challenges = [
      // === TÜRKÇE POP ===
      {
        'id': 'tarkan',
        'categoryId': 'turkce_pop',
        'title': 'Tarkan Challenge',
        'subtitle': 'Megastar\'ın en hit şarkıları',
        'description': 'Tarkan\'ın 90\'lardan bugüne en sevilen şarkılarını bil!',
        'type': 'artist',
        'difficulty': 'easy',
        'language': 'tr',
        'songIds': ['tarkan_1', 'tarkan_2', 'tarkan_3', 'tarkan_4', 'tarkan_5'],
        'totalSongs': 5,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'sezen_aksu',
        'categoryId': 'turkce_pop',
        'title': 'Sezen Aksu Challenge',
        'subtitle': 'Minik Serçe\'nin şaheserleri',
        'description': 'Türk pop müziğinin divası Sezen Aksu\'nun unutulmaz şarkıları',
        'type': 'artist',
        'difficulty': 'medium',
        'language': 'tr',
        'songIds': ['sezen_1', 'sezen_2', 'sezen_3', 'sezen_4', 'sezen_5'],
        'totalSongs': 5,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'ajda_pekkan',
        'categoryId': 'turkce_pop',
        'title': 'Ajda Pekkan Challenge',
        'subtitle': 'Süperstar\'ın klasikleri',
        'description': 'Ajda Pekkan\'ın tüm zamanların en sevilen şarkıları',
        'type': 'artist',
        'difficulty': 'hard',
        'language': 'tr',
        'songIds': ['ajda_1', 'ajda_2', 'ajda_3', 'ajda_4', 'ajda_5'],
        'totalSongs': 5,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'sertab_erener',
        'categoryId': 'turkce_pop',
        'title': 'Sertab Erener Challenge',
        'subtitle': 'Eurovision şampiyonu',
        'description': 'Sertab Erener\'in en güzel şarkıları',
        'type': 'artist',
        'difficulty': 'medium',
        'language': 'tr',
        'songIds': ['sertab_1', 'sertab_2', 'sertab_3', 'sertab_4', 'sertab_5'],
        'totalSongs': 5,
        'priceUsd': 0.99,
        'isFree': true, // ÜCRETSİZ!
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'hadise',
        'categoryId': 'turkce_pop',
        'title': 'Hadise Challenge',
        'subtitle': 'Dans pistinin kraliçesi',
        'description': 'Hadise\'nin en hit şarkıları',
        'type': 'artist',
        'difficulty': 'easy',
        'language': 'tr',
        'songIds': ['hadise_1', 'hadise_2', 'hadise_3', 'hadise_4', 'hadise_5'],
        'totalSongs': 5,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // === TÜRKÇE ROCK ===
      {
        'id': 'duman',
        'categoryId': 'turkce_rock',
        'title': 'Duman Challenge',
        'subtitle': 'Alternatif rock\'un öncüleri',
        'description': 'Duman grubunun en sevilen şarkıları',
        'type': 'artist',
        'difficulty': 'medium',
        'language': 'tr',
        'songIds': ['duman_1', 'duman_2', 'duman_3', 'duman_4', 'duman_5'],
        'totalSongs': 5,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'mor_ve_otesi',
        'categoryId': 'turkce_rock',
        'title': 'Mor ve Ötesi Challenge',
        'subtitle': 'Türk rock\'unun efsanesi',
        'description': 'Mor ve Ötesi\'nin unutulmaz şarkıları',
        'type': 'artist',
        'difficulty': 'medium',
        'language': 'tr',
        'songIds': ['mvo_1', 'mvo_2', 'mvo_3', 'mvo_4', 'mvo_5'],
        'totalSongs': 5,
        'priceUsd': 0.99,
        'isFree': true, // ÜCRETSİZ!
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'teoman',
        'categoryId': 'turkce_rock',
        'title': 'Teoman Challenge',
        'subtitle': 'Türk rock\'unun yıldızı',
        'description': 'Teoman\'ın en güzel şarkıları',
        'type': 'artist',
        'difficulty': 'medium',
        'language': 'tr',
        'songIds': ['teoman_1', 'teoman_2', 'teoman_3', 'teoman_4', 'teoman_5'],
        'totalSongs': 5,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'manga',
        'categoryId': 'turkce_rock',
        'title': 'maNga Challenge',
        'subtitle': 'Nu-metal\'in Türk temsilcisi',
        'description': 'maNga\'nın en hit şarkıları',
        'type': 'artist',
        'difficulty': 'hard',
        'language': 'tr',
        'songIds': ['manga_1', 'manga_2', 'manga_3', 'manga_4', 'manga_5'],
        'totalSongs': 5,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // === ENGLISH POP ===
      {
        'id': 'taylor_swift',
        'categoryId': 'english_pop',
        'title': 'Taylor Swift Challenge',
        'subtitle': 'Pop princess hits',
        'description': 'Taylor Swift\'s biggest hits from all eras',
        'type': 'artist',
        'difficulty': 'easy',
        'language': 'en',
        'songIds': ['taylor_1', 'taylor_2', 'taylor_3', 'taylor_4', 'taylor_5'],
        'totalSongs': 5,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'ed_sheeran',
        'categoryId': 'english_pop',
        'title': 'Ed Sheeran Challenge',
        'subtitle': 'The ginger genius',
        'description': 'Ed Sheeran\'s most loved songs',
        'type': 'artist',
        'difficulty': 'easy',
        'language': 'en',
        'songIds': ['ed_1', 'ed_2', 'ed_3', 'ed_4', 'ed_5'],
        'totalSongs': 5,
        'priceUsd': 0.99,
        'isFree': true, // FREE!
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'adele',
        'categoryId': 'english_pop',
        'title': 'Adele Challenge',
        'subtitle': 'The voice of a generation',
        'description': 'Adele\'s emotional ballads and hits',
        'type': 'artist',
        'difficulty': 'medium',
        'language': 'en',
        'songIds': ['adele_1', 'adele_2', 'adele_3', 'adele_4', 'adele_5'],
        'totalSongs': 5,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'bruno_mars',
        'categoryId': 'english_pop',
        'title': 'Bruno Mars Challenge',
        'subtitle': 'Uptown funk master',
        'description': 'Bruno Mars\' groovy hits',
        'type': 'artist',
        'difficulty': 'easy',
        'language': 'en',
        'songIds': ['bruno_1', 'bruno_2', 'bruno_3', 'bruno_4', 'bruno_5'],
        'totalSongs': 5,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final challenge in challenges) {
      final id = challenge['id'] as String;
      await _db.collection('challenges').doc(id).set(challenge);
      print('  ✓ Challenge eklendi: $id');
    }
  }

  /// Şarkıları ekle
  Future<void> seedSongs() async {
    print('🎵 Şarkılar ekleniyor...');

    final songs = [
      // === TARKAN ===
      {'id': 'tarkan_1', 'title': 'Şımarık', 'artist': 'Tarkan', 'keywords': ['simarik', 'kiss kiss'], 'year': 1997},
      {'id': 'tarkan_2', 'title': 'Dudu', 'artist': 'Tarkan', 'keywords': ['dudu'], 'year': 2003},
      {'id': 'tarkan_3', 'title': 'Kuzu Kuzu', 'artist': 'Tarkan', 'keywords': ['kuzu'], 'year': 2001},
      {'id': 'tarkan_4', 'title': 'Verme', 'artist': 'Tarkan', 'keywords': ['verme'], 'year': 2017},
      {'id': 'tarkan_5', 'title': 'Öp', 'artist': 'Tarkan', 'keywords': ['op'], 'year': 2008},

      // === SEZEN AKSU ===
      {'id': 'sezen_1', 'title': 'Gülümse', 'artist': 'Sezen Aksu', 'keywords': ['gulumse'], 'year': 1991},
      {'id': 'sezen_2', 'title': 'Hadi Bakalım', 'artist': 'Sezen Aksu', 'keywords': ['hadi bakalim'], 'year': 2006},
      {'id': 'sezen_3', 'title': 'Firuze', 'artist': 'Sezen Aksu', 'keywords': ['firuze'], 'year': 1982},
      {'id': 'sezen_4', 'title': 'Kaybolan Yıllar', 'artist': 'Sezen Aksu', 'keywords': ['kaybolan yillar'], 'year': 1984},
      {'id': 'sezen_5', 'title': 'Küçüğüm', 'artist': 'Sezen Aksu', 'keywords': ['kucugum'], 'year': 1993},

      // === AJDA PEKKAN ===
      {'id': 'ajda_1', 'title': 'Oyalama Beni', 'artist': 'Ajda Pekkan', 'keywords': ['oyalama'], 'year': 1976},
      {'id': 'ajda_2', 'title': 'Bambaşka Biri', 'artist': 'Ajda Pekkan', 'keywords': ['bambaska'], 'year': 1978},
      {'id': 'ajda_3', 'title': 'Süperstar', 'artist': 'Ajda Pekkan', 'keywords': ['superstar'], 'year': 1977},
      {'id': 'ajda_4', 'title': 'Arada Sırada', 'artist': 'Ajda Pekkan', 'keywords': ['arada sirada'], 'year': 2012},
      {'id': 'ajda_5', 'title': 'Yakar Geçerim', 'artist': 'Ajda Pekkan', 'keywords': ['yakar gecerim'], 'year': 1996},

      // === SERTAB ERENER ===
      {'id': 'sertab_1', 'title': 'Everyway That I Can', 'artist': 'Sertab Erener', 'keywords': ['everyway'], 'year': 2003},
      {'id': 'sertab_2', 'title': 'Aşk', 'artist': 'Sertab Erener', 'keywords': ['ask'], 'year': 1997},
      {'id': 'sertab_3', 'title': 'Olsun', 'artist': 'Sertab Erener', 'keywords': ['olsun'], 'year': 1999},
      {'id': 'sertab_4', 'title': 'Lal', 'artist': 'Sertab Erener', 'keywords': ['lal'], 'year': 2000},
      {'id': 'sertab_5', 'title': 'Açık Adres', 'artist': 'Sertab Erener', 'keywords': ['acik adres'], 'year': 1999},

      // === HADISE ===
      {'id': 'hadise_1', 'title': 'Düm Tek Tek', 'artist': 'Hadise', 'keywords': ['dum tek'], 'year': 2009},
      {'id': 'hadise_2', 'title': 'Nerdesin Aşkım', 'artist': 'Hadise', 'keywords': ['nerdesin askim'], 'year': 2008},
      {'id': 'hadise_3', 'title': 'Farkımız Var', 'artist': 'Hadise', 'keywords': ['farkimiz var'], 'year': 2006},
      {'id': 'hadise_4', 'title': 'Prenses', 'artist': 'Hadise', 'keywords': ['prenses'], 'year': 2014},
      {'id': 'hadise_5', 'title': 'Şampiyon', 'artist': 'Hadise', 'keywords': ['sampiyon'], 'year': 2013},

      // === DUMAN ===
      {'id': 'duman_1', 'title': 'Senden Daha Güzel', 'artist': 'Duman', 'keywords': ['senden daha guzel'], 'year': 2002},
      {'id': 'duman_2', 'title': 'Bu Akşam', 'artist': 'Duman', 'keywords': ['bu aksam'], 'year': 2004},
      {'id': 'duman_3', 'title': 'Herşeyi Yak', 'artist': 'Duman', 'keywords': ['herseyi yak'], 'year': 2004},
      {'id': 'duman_4', 'title': 'Köprüaltı', 'artist': 'Duman', 'keywords': ['koprualti'], 'year': 1999},
      {'id': 'duman_5', 'title': 'Helal Olsun', 'artist': 'Duman', 'keywords': ['helal olsun'], 'year': 2013},

      // === MOR VE ÖTESİ ===
      {'id': 'mvo_1', 'title': 'Cambaz', 'artist': 'Mor ve Ötesi', 'keywords': ['cambaz'], 'year': 2006},
      {'id': 'mvo_2', 'title': 'Bir Derdim Var', 'artist': 'Mor ve Ötesi', 'keywords': ['bir derdim var'], 'year': 2008},
      {'id': 'mvo_3', 'title': 'Yalnız Şarkı', 'artist': 'Mor ve Ötesi', 'keywords': ['yalniz sarki'], 'year': 2004},
      {'id': 'mvo_4', 'title': 'Yorma Kendini', 'artist': 'Mor ve Ötesi', 'keywords': ['yorma kendini'], 'year': 2011},
      {'id': 'mvo_5', 'title': 'Dünya Yalan Söylüyor', 'artist': 'Mor ve Ötesi', 'keywords': ['dunya yalan'], 'year': 2004},

      // === TEOMAN ===
      {'id': 'teoman_1', 'title': 'İstanbul\'da Sonbahar', 'artist': 'Teoman', 'keywords': ['istanbul sonbahar'], 'year': 1996},
      {'id': 'teoman_2', 'title': 'Paramparça', 'artist': 'Teoman', 'keywords': ['paramparca'], 'year': 2000},
      {'id': 'teoman_3', 'title': 'Aşk Kırıntıları', 'artist': 'Teoman', 'keywords': ['ask kirintilari'], 'year': 1998},
      {'id': 'teoman_4', 'title': 'Renkli Rüyalar Oteli', 'artist': 'Teoman', 'keywords': ['renkli ruyalar'], 'year': 2003},
      {'id': 'teoman_5', 'title': 'O Sen Misin', 'artist': 'Teoman', 'keywords': ['o sen misin'], 'year': 2016},

      // === MANGA ===
      {'id': 'manga_1', 'title': 'We Could Be The Same', 'artist': 'maNga', 'keywords': ['we could be'], 'year': 2010},
      {'id': 'manga_2', 'title': 'Dünyanın Sonuna Doğmuşum', 'artist': 'maNga', 'keywords': ['dunyanin sonuna'], 'year': 2004},
      {'id': 'manga_3', 'title': 'Beni Benimle Bırak', 'artist': 'maNga', 'keywords': ['beni benimle'], 'year': 2009},
      {'id': 'manga_4', 'title': 'Cevapsız Sorular', 'artist': 'maNga', 'keywords': ['cevapsiz sorular'], 'year': 2007},
      {'id': 'manga_5', 'title': 'Fly To Stay Alive', 'artist': 'maNga', 'keywords': ['fly to stay'], 'year': 2009},

      // === TAYLOR SWIFT ===
      {'id': 'taylor_1', 'title': 'Shake It Off', 'artist': 'Taylor Swift', 'keywords': ['shake it off'], 'year': 2014},
      {'id': 'taylor_2', 'title': 'Love Story', 'artist': 'Taylor Swift', 'keywords': ['love story', 'romeo'], 'year': 2008},
      {'id': 'taylor_3', 'title': 'Blank Space', 'artist': 'Taylor Swift', 'keywords': ['blank space'], 'year': 2014},
      {'id': 'taylor_4', 'title': 'Anti-Hero', 'artist': 'Taylor Swift', 'keywords': ['anti hero'], 'year': 2022},
      {'id': 'taylor_5', 'title': 'Bad Blood', 'artist': 'Taylor Swift', 'keywords': ['bad blood'], 'year': 2014},

      // === ED SHEERAN ===
      {'id': 'ed_1', 'title': 'Shape of You', 'artist': 'Ed Sheeran', 'keywords': ['shape of you'], 'year': 2017},
      {'id': 'ed_2', 'title': 'Perfect', 'artist': 'Ed Sheeran', 'keywords': ['perfect'], 'year': 2017},
      {'id': 'ed_3', 'title': 'Thinking Out Loud', 'artist': 'Ed Sheeran', 'keywords': ['thinking out loud'], 'year': 2014},
      {'id': 'ed_4', 'title': 'Photograph', 'artist': 'Ed Sheeran', 'keywords': ['photograph'], 'year': 2014},
      {'id': 'ed_5', 'title': 'Castle on the Hill', 'artist': 'Ed Sheeran', 'keywords': ['castle on the hill'], 'year': 2017},

      // === ADELE ===
      {'id': 'adele_1', 'title': 'Hello', 'artist': 'Adele', 'keywords': ['hello'], 'year': 2015},
      {'id': 'adele_2', 'title': 'Rolling in the Deep', 'artist': 'Adele', 'keywords': ['rolling in the deep'], 'year': 2010},
      {'id': 'adele_3', 'title': 'Someone Like You', 'artist': 'Adele', 'keywords': ['someone like you'], 'year': 2011},
      {'id': 'adele_4', 'title': 'Set Fire to the Rain', 'artist': 'Adele', 'keywords': ['set fire'], 'year': 2011},
      {'id': 'adele_5', 'title': 'Easy On Me', 'artist': 'Adele', 'keywords': ['easy on me'], 'year': 2021},

      // === BRUNO MARS ===
      {'id': 'bruno_1', 'title': 'Uptown Funk', 'artist': 'Bruno Mars', 'keywords': ['uptown funk'], 'year': 2014},
      {'id': 'bruno_2', 'title': 'Just The Way You Are', 'artist': 'Bruno Mars', 'keywords': ['just the way'], 'year': 2010},
      {'id': 'bruno_3', 'title': '24K Magic', 'artist': 'Bruno Mars', 'keywords': ['24k magic'], 'year': 2016},
      {'id': 'bruno_4', 'title': 'Grenade', 'artist': 'Bruno Mars', 'keywords': ['grenade'], 'year': 2010},
      {'id': 'bruno_5', 'title': 'Locked Out of Heaven', 'artist': 'Bruno Mars', 'keywords': ['locked out'], 'year': 2012},
    ];

    for (final song in songs) {
      final id = song['id'] as String;
      await _db.collection('songs').doc(id).set(song);
    }
    print('  ✓ ${songs.length} şarkı eklendi');
  }

  /// Verileri temizle (dikkatli kullan!)
  Future<void> clearAll() async {
    print('🗑️ Veriler siliniyor...');

    // Kategorileri sil
    final categories = await _db.collection('categories').get();
    for (final doc in categories.docs) {
      await doc.reference.delete();
    }

    // Challenge'ları sil
    final challenges = await _db.collection('challenges').get();
    for (final doc in challenges.docs) {
      await doc.reference.delete();
    }

    // Şarkıları sil
    final songs = await _db.collection('songs').get();
    for (final doc in songs.docs) {
      await doc.reference.delete();
    }

    print('✅ Tüm veriler silindi');
  }
}
