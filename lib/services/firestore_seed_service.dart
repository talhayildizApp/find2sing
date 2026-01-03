import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore'a başlangıç verilerini ekleyen servis
class FirestoreSeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Tüm seed verilerini ekle
  Future<void> seedAll() async {
    print('🌱 Seed işlemi başlıyor...');
    
    await seedCategories();
    await seedChallenges();
    
    print('✅ Seed işlemi tamamlandı!');
  }

  /// Kategorileri ekle
  Future<void> seedCategories() async {
    print('📁 Kategoriler ekleniyor...');

    final categories = [
      // === SANATÇI DİSKOGRAFİ ===
      {
        'id': 'artist_discography',
        'title': 'Sanatçı Diskografi',
        'description': 'Favori sanatçılarının tüm şarkılarını bil',
        'iconEmoji': '🎤',
        'language': 'tr',
        'type': 'artist',
        'challengeCount': 9,
        'priceUsd': 2.99,
        'isActive': true,
        'sortOrder': 1,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // === EN İYİ ALBÜMLER ===
      {
        'id': 'best_albums',
        'title': 'En İyi Albümler',
        'description': 'Efsane albümlerin şarkılarını tahmin et',
        'iconEmoji': '💿',
        'language': 'tr',
        'type': 'album',
        'challengeCount': 4,
        'priceUsd': 1.99,
        'isActive': true,
        'sortOrder': 2,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // === LİSTELER (SPOTIFY) ===
      {
        'id': 'playlists',
        'title': 'Listeler',
        'description': 'Popüler playlist\'lerdeki şarkıları bil',
        'iconEmoji': '📋',
        'language': 'tr',
        'type': 'playlist',
        'challengeCount': 4,
        'priceUsd': 1.99,
        'isActive': true,
        'sortOrder': 3,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // === DÖNEMLER ===
      {
        'id': 'eras',
        'title': 'Dönemler',
        'description': 'Farklı dönemlerin hit şarkılarını hatırla',
        'iconEmoji': '📅',
        'language': 'tr',
        'type': 'era',
        'challengeCount': 4,
        'priceUsd': 1.99,
        'isActive': true,
        'sortOrder': 4,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = _db.batch();

    for (final category in categories) {
      final docRef = _db.collection('categories').doc(category['id'] as String);
      batch.set(docRef, category);
    }

    await batch.commit();
    print('  ✓ ${categories.length} kategori eklendi');
  }

  /// Challenge'ları ekle
  Future<void> seedChallenges() async {
    print('🎮 Challenge\'lar ekleniyor...');

    final challenges = [
      // ═══════════════════════════════════════════════════════════
      // SANATÇI DİSKOGRAFİ
      // ═══════════════════════════════════════════════════════════
      
      // Duman
      {
        'id': 'duman',
        'categoryId': 'artist_discography',
        'title': 'Duman',
        'subtitle': 'Türk Rock\'unun efsanesi',
        'description': 'Duman\'ın en sevilen şarkılarını bil',
        'type': 'artist',
        'difficulty': 'medium',
        'language': 'tr',
        'artistName': 'Duman',
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 15,
        'priceUsd': 0.99,
        'isFree': true, // İlk challenge ücretsiz
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Athena
      {
        'id': 'athena',
        'categoryId': 'artist_discography',
        'title': 'Athena',
        'subtitle': 'Ska-punk\'ın Türk temsilcisi',
        'description': 'Athena\'nın enerjik şarkılarını tahmin et',
        'type': 'artist',
        'difficulty': 'medium',
        'language': 'tr',
        'artistName': 'Athena',
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 12,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Sertab Erener
      {
        'id': 'sertab_erener',
        'categoryId': 'artist_discography',
        'title': 'Sertab Erener',
        'subtitle': 'Eurovision şampiyonu',
        'description': 'Sertab Erener\'in unutulmaz şarkıları',
        'type': 'artist',
        'difficulty': 'easy',
        'language': 'tr',
        'artistName': 'Sertab Erener',
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 12,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Sezen Aksu
      {
        'id': 'sezen_aksu',
        'categoryId': 'artist_discography',
        'title': 'Sezen Aksu',
        'subtitle': 'Minik Serçe',
        'description': 'Türk pop müziğinin divası',
        'type': 'artist',
        'difficulty': 'medium',
        'language': 'tr',
        'artistName': 'Sezen Aksu',
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 15,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Müslüm Gürses
      {
        'id': 'muslum_gurses',
        'categoryId': 'artist_discography',
        'title': 'Müslüm Gürses',
        'subtitle': 'Müslüm Baba',
        'description': 'Arabesk\'in efsanevi sesi',
        'type': 'artist',
        'difficulty': 'hard',
        'language': 'tr',
        'artistName': 'Müslüm Gürses',
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 15,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Ceza
      {
        'id': 'ceza',
        'categoryId': 'artist_discography',
        'title': 'Ceza',
        'subtitle': 'Türk Rap\'inin öncüsü',
        'description': 'Ceza\'nın efsane parçaları',
        'type': 'artist',
        'difficulty': 'medium',
        'language': 'tr',
        'artistName': 'Ceza',
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 12,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Sagopa Kajmer
      {
        'id': 'sagopa_kajmer',
        'categoryId': 'artist_discography',
        'title': 'Sagopa Kajmer',
        'subtitle': 'Lirik rap ustası',
        'description': 'Sagopa\'nın derin şarkıları',
        'type': 'artist',
        'difficulty': 'hard',
        'language': 'tr',
        'artistName': 'Sagopa Kajmer',
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 12,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Tarkan
      {
        'id': 'tarkan',
        'categoryId': 'artist_discography',
        'title': 'Tarkan',
        'subtitle': 'Megastar',
        'description': 'Tarkan\'ın dünyaca ünlü hitleri',
        'type': 'artist',
        'difficulty': 'easy',
        'language': 'tr',
        'artistName': 'Tarkan',
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 15,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // ═══════════════════════════════════════════════════════════
      // EN İYİ ALBÜMLER
      // ═══════════════════════════════════════════════════════════

      // Popçular Dışarı - Athena
      {
        'id': 'album_popcular_disari',
        'categoryId': 'best_albums',
        'title': 'Popçular Dışarı',
        'subtitle': 'Athena (2002)',
        'description': 'Athena\'nın efsane albümü',
        'type': 'album',
        'difficulty': 'medium',
        'language': 'tr',
        'artistName': 'Athena',
        'albumName': 'Popçular Dışarı',
        'albumYear': 2002,
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 10,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Aacayipsin - Duman
      {
        'id': 'album_aacayipsin',
        'categoryId': 'best_albums',
        'title': 'Aacayipsin',
        'subtitle': 'Duman (1999)',
        'description': 'Duman\'ın ilk albümü',
        'type': 'album',
        'difficulty': 'medium',
        'language': 'tr',
        'artistName': 'Duman',
        'albumName': 'Aacayipsin',
        'albumYear': 1999,
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 10,
        'priceUsd': 0.99,
        'isFree': true, // Ücretsiz
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Medcezir - Teoman
      {
        'id': 'album_medcezir',
        'categoryId': 'best_albums',
        'title': 'Medcezir',
        'subtitle': 'Teoman (2004)',
        'description': 'Teoman\'ın başyapıtı',
        'type': 'album',
        'difficulty': 'medium',
        'language': 'tr',
        'artistName': 'Teoman',
        'albumName': 'Medcezir',
        'albumYear': 2004,
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 10,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Dünya Yalan Söylüyor - Duman
      {
        'id': 'album_dunya_yalan',
        'categoryId': 'best_albums',
        'title': 'Dünya Yalan Söylüyor',
        'subtitle': 'Duman (2004)',
        'description': 'Duman\'ın ikonik albümü',
        'type': 'album',
        'difficulty': 'easy',
        'language': 'tr',
        'artistName': 'Duman',
        'albumName': 'Dünya Yalan Söylüyor',
        'albumYear': 2004,
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 10,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // ═══════════════════════════════════════════════════════════
      // LİSTELER (SPOTIFY)
      // ═══════════════════════════════════════════════════════════

      // Top 50 – Turkey
      {
        'id': 'playlist_top50_turkey',
        'categoryId': 'playlists',
        'title': 'Top 50 – Turkey',
        'subtitle': 'Türkiye\'nin en çok dinlenenleri',
        'description': 'Spotify Türkiye Top 50 listesi',
        'type': 'playlist',
        'difficulty': 'easy',
        'language': 'tr',
        'playlistSource': 'Spotify',
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 20,
        'priceUsd': 0.99,
        'isFree': true, // Ücretsiz
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // New Music Friday
      {
        'id': 'playlist_new_music_friday',
        'categoryId': 'playlists',
        'title': 'New Music Friday',
        'subtitle': 'Haftanın yeni çıkanları',
        'description': 'En yeni Türkçe şarkılar',
        'type': 'playlist',
        'difficulty': 'hard',
        'language': 'tr',
        'playlistSource': 'Spotify',
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 15,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // Top 50 – Global
      {
        'id': 'playlist_top50_global',
        'categoryId': 'playlists',
        'title': 'Top 50 – Global',
        'subtitle': 'Dünya genelinde en popülerler',
        'description': 'Spotify Global Top 50',
        'type': 'playlist',
        'difficulty': 'medium',
        'language': 'en',
        'playlistSource': 'Spotify',
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 20,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // RapCaviar
      {
        'id': 'playlist_rapcaviar',
        'categoryId': 'playlists',
        'title': 'RapCaviar',
        'subtitle': 'En iyi rap şarkıları',
        'description': 'Hip-hop ve rap hitleri',
        'type': 'playlist',
        'difficulty': 'medium',
        'language': 'en',
        'playlistSource': 'Spotify',
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 15,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // ═══════════════════════════════════════════════════════════
      // DÖNEMLER
      // ═══════════════════════════════════════════════════════════

      // 90'lar Pop
      {
        'id': 'era_90s_pop',
        'categoryId': 'eras',
        'title': '90\'lar Pop',
        'subtitle': '1990-1999 Türk Pop',
        'description': '90\'ların unutulmaz pop şarkıları',
        'type': 'era',
        'difficulty': 'medium',
        'language': 'tr',
        'eraStart': 1990,
        'eraEnd': 1999,
        'genre': 'pop',
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 20,
        'priceUsd': 0.99,
        'isFree': true, // Ücretsiz
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // 2000'ler Rock
      {
        'id': 'era_2000s_rock',
        'categoryId': 'eras',
        'title': '2000\'ler Rock',
        'subtitle': '2000-2009 Türk Rock',
        'description': '2000\'lerin rock klasikleri',
        'type': 'era',
        'difficulty': 'medium',
        'language': 'tr',
        'eraStart': 2000,
        'eraEnd': 2009,
        'genre': 'rock',
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 20,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // 2000'ler R&B
      {
        'id': 'era_2000s_rnb',
        'categoryId': 'eras',
        'title': '2000\'ler R&B',
        'subtitle': '2000-2009 R&B hitleri',
        'description': 'R&B\'nin altın çağı',
        'type': 'era',
        'difficulty': 'hard',
        'language': 'en',
        'eraStart': 2000,
        'eraEnd': 2009,
        'genre': 'rnb',
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 15,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },

      // 2010'lar Indie / Alternative
      {
        'id': 'era_2010s_indie',
        'categoryId': 'eras',
        'title': '2010\'lar Indie',
        'subtitle': '2010-2019 Indie & Alternative',
        'description': 'Indie ve alternatif müzik',
        'type': 'era',
        'difficulty': 'hard',
        'language': 'tr',
        'eraStart': 2010,
        'eraEnd': 2019,
        'genre': 'indie',
        'coverImageUrl': null,
        'songIds': [],
        'totalSongs': 15,
        'priceUsd': 0.99,
        'isFree': false,
        'isActive': true,
        'playCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = _db.batch();

    for (final challenge in challenges) {
      final docRef = _db.collection('challenges').doc(challenge['id'] as String);
      batch.set(docRef, challenge);
    }

    await batch.commit();
    print('  ✓ ${challenges.length} challenge eklendi');
  }

  /// Örnek şarkıları ekle (Duman için)
  Future<void> seedSampleSongs() async {
    print('🎵 Örnek şarkılar ekleniyor...');

    final songs = [
      // === DUMAN ===
      {'id': 'duman_1', 'challengeId': 'duman', 'title': 'Senden Daha Güzel', 'artist': 'Duman', 'keywords': ['senden', 'güzel', 'daha'], 'year': 2002},
      {'id': 'duman_2', 'challengeId': 'duman', 'title': 'Bu Akşam', 'artist': 'Duman', 'keywords': ['akşam', 'bu'], 'year': 1999},
      {'id': 'duman_3', 'challengeId': 'duman', 'title': 'Herşeyi Yak', 'artist': 'Duman', 'keywords': ['yak', 'herşeyi', 'her şeyi'], 'year': 2002},
      {'id': 'duman_4', 'challengeId': 'duman', 'title': 'Köprüaltı', 'artist': 'Duman', 'keywords': ['köprü', 'altı', 'köprüaltı'], 'year': 2006},
      {'id': 'duman_5', 'challengeId': 'duman', 'title': 'Melankoli', 'artist': 'Duman', 'keywords': ['melankoli'], 'year': 2006},
      {'id': 'duman_6', 'challengeId': 'duman', 'title': 'Aman Aman', 'artist': 'Duman', 'keywords': ['aman'], 'year': 2013},
      {'id': 'duman_7', 'challengeId': 'duman', 'title': 'Haberin Yok Ölüyorum', 'artist': 'Duman', 'keywords': ['haber', 'ölüyorum', 'yok'], 'year': 2004},
      {'id': 'duman_8', 'challengeId': 'duman', 'title': 'Dibine Kadar', 'artist': 'Duman', 'keywords': ['dip', 'dibine', 'kadar'], 'year': 2004},
      {'id': 'duman_9', 'challengeId': 'duman', 'title': 'Eyvallah', 'artist': 'Duman', 'keywords': ['eyvallah'], 'year': 2009},
      {'id': 'duman_10', 'challengeId': 'duman', 'title': 'Yürek', 'artist': 'Duman', 'keywords': ['yürek'], 'year': 2002},

      // === TARKAN ===
      {'id': 'tarkan_1', 'challengeId': 'tarkan', 'title': 'Şımarık', 'artist': 'Tarkan', 'keywords': ['şımarık', 'simarik', 'kiss kiss'], 'year': 1997},
      {'id': 'tarkan_2', 'challengeId': 'tarkan', 'title': 'Dudu', 'artist': 'Tarkan', 'keywords': ['dudu'], 'year': 2003},
      {'id': 'tarkan_3', 'challengeId': 'tarkan', 'title': 'Kuzu Kuzu', 'artist': 'Tarkan', 'keywords': ['kuzu'], 'year': 2001},
      {'id': 'tarkan_4', 'challengeId': 'tarkan', 'title': 'Hüp', 'artist': 'Tarkan', 'keywords': ['hüp', 'hup'], 'year': 2006},
      {'id': 'tarkan_5', 'challengeId': 'tarkan', 'title': 'Dön Bebeğim', 'artist': 'Tarkan', 'keywords': ['dön', 'bebek', 'bebeğim'], 'year': 2017},
      {'id': 'tarkan_6', 'challengeId': 'tarkan', 'title': 'Verme', 'artist': 'Tarkan', 'keywords': ['verme'], 'year': 2010},
      {'id': 'tarkan_7', 'challengeId': 'tarkan', 'title': 'Adımı Kalbine Yaz', 'artist': 'Tarkan', 'keywords': ['adımı', 'kalp', 'kalbine', 'yaz'], 'year': 2010},
      {'id': 'tarkan_8', 'challengeId': 'tarkan', 'title': 'Hatasız Kul Olmaz', 'artist': 'Tarkan', 'keywords': ['hatasız', 'kul', 'olmaz'], 'year': 1994},

      // === SEZEN AKSU ===
      {'id': 'sezen_1', 'challengeId': 'sezen_aksu', 'title': 'Gülümse', 'artist': 'Sezen Aksu', 'keywords': ['gülümse', 'gulum'], 'year': 1991},
      {'id': 'sezen_2', 'challengeId': 'sezen_aksu', 'title': 'Hadi Bakalım', 'artist': 'Sezen Aksu', 'keywords': ['hadi', 'bakalım'], 'year': 2017},
      {'id': 'sezen_3', 'challengeId': 'sezen_aksu', 'title': 'Firuze', 'artist': 'Sezen Aksu', 'keywords': ['firuze'], 'year': 1982},
      {'id': 'sezen_4', 'challengeId': 'sezen_aksu', 'title': 'Şarkı Söylemek Lazım', 'artist': 'Sezen Aksu', 'keywords': ['şarkı', 'söylemek', 'lazım'], 'year': 2006},
      {'id': 'sezen_5', 'challengeId': 'sezen_aksu', 'title': 'Keskin Bıçak', 'artist': 'Sezen Aksu', 'keywords': ['keskin', 'bıçak'], 'year': 2011},

      // === CEZA ===
      {'id': 'ceza_1', 'challengeId': 'ceza', 'title': 'Holocaust', 'artist': 'Ceza', 'keywords': ['holocaust'], 'year': 2004},
      {'id': 'ceza_2', 'challengeId': 'ceza', 'title': 'Suspus', 'artist': 'Ceza', 'keywords': ['suspus', 'sus'], 'year': 2015},
      {'id': 'ceza_3', 'challengeId': 'ceza', 'title': 'Neyim Var Ki', 'artist': 'Ceza', 'keywords': ['neyim', 'var'], 'year': 2009},
      {'id': 'ceza_4', 'challengeId': 'ceza', 'title': 'Yerli Plaka', 'artist': 'Ceza', 'keywords': ['yerli', 'plaka'], 'year': 2009},
      {'id': 'ceza_5', 'challengeId': 'ceza', 'title': 'Türk Marşı', 'artist': 'Ceza', 'keywords': ['türk', 'marşı', 'marş'], 'year': 2015},
    ];

    final batch = _db.batch();

    for (final song in songs) {
      final docRef = _db.collection('songs').doc(song['id'] as String);
      batch.set(docRef, {
        ...song,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    print('  ✓ ${songs.length} şarkı eklendi');

    // Challenge'ların songIds'lerini güncelle
    await _updateChallengeSongIds();
  }

  /// Challenge'ların songIds alanlarını güncelle
  Future<void> _updateChallengeSongIds() async {
    final songsSnapshot = await _db.collection('songs').get();
    
    // ChallengeId'ye göre grupla
    final Map<String, List<String>> challengeSongs = {};
    
    for (final doc in songsSnapshot.docs) {
      final challengeId = doc.data()['challengeId'] as String?;
      if (challengeId != null) {
        challengeSongs.putIfAbsent(challengeId, () => []);
        challengeSongs[challengeId]!.add(doc.id);
      }
    }

    // Her challenge'ı güncelle
    final batch = _db.batch();
    
    for (final entry in challengeSongs.entries) {
      final docRef = _db.collection('challenges').doc(entry.key);
      batch.update(docRef, {
        'songIds': entry.value,
        'totalSongs': entry.value.length,
      });
    }

    await batch.commit();
    print('  ✓ Challenge songIds güncellendi');
  }

  /// Tüm verileri sil (test için)
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

    print('  ✓ Tüm veriler silindi');
  }
}
