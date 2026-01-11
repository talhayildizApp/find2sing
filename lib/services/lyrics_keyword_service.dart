// lib/services/lyrics_keyword_service.dart
//
// Multilingual lyric -> keyword extraction for Find2Sing admin tooling.
// - Preserves native characters (Turkish, German, Spanish accents).
// - No chorus removal / repetition filtering (by design).
// - Removes stopwords (optional) and punctuation, keeps letters/numbers.
// - Produces:
//   - keywords: unique sorted list
//   - topKeywords: ranked list by frequency (good for game pool)

class LyricsKeywordService {
  // Basic stopwords. Keep this conservative; you can expand later.
  static const Set<String> trStopwords = {
    've',
    'bir',
    'bu',
    'şu',
    'o',
    'da',
    'de',
    'mi',
    'mu',
    'mü',
    'için',
    'ile',
    'gibi',
    'ama',
    'fakat',
    'çünkü',
    'ben',
    'sen',
    'biz',
    'siz',
    'bana',
    'sana',
    'beni',
    'seni',
    'bizi',
    'sizi',
    'onu',
    'ona',
    'çok',
    'daha',
    'en',
    'az',
    'ya',
    'ki',
    'ne',
    'niye',
    'neden',
    'nasıl',
    'mı',
  };

  static const Set<String> enStopwords = {
    'the',
    'a',
    'an',
    'and',
    'or',
    'but',
    'if',
    'then',
    'so',
    'because',
    'to',
    'of',
    'in',
    'on',
    'with',
    'for',
    'at',
    'from',
    'by',
    'i',
    'you',
    'me',
    'my',
    'your',
    'we',
    'they',
    'he',
    'she',
    'it',
    'us',
    'them',
    'is',
    'are',
    'was',
    'were',
    'be',
    'been',
    'being',
    'do',
    'does',
    'did',
    'not',
    'no',
    'yes',
    'this',
    'that',
    'these',
    'those',
    'there',
    'here',
  };

  static const Set<String> deStopwords = {
    'der',
    'die',
    'das',
    'ein',
    'eine',
    'und',
    'oder',
    'aber',
    'wenn',
    'dann',
    'weil',
    'zu',
    'von',
    'im',
    'in',
    'am',
    'auf',
    'mit',
    'für',
    'bei',
    'aus',
    'ich',
    'du',
    'er',
    'sie',
    'es',
    'wir',
    'ihr',
    'mich',
    'dich',
    'uns',
    'euch',
    'mein',
    'dein',
    'sein',
    'unser',
    'euer',
    'ist',
    'sind',
    'war',
    'waren',
    'nicht',
    'ja',
    'nein',
    'dies',
    'diese',
    'jenes',
    'hier',
    'da',
  };

  static const Set<String> esStopwords = {
    'el',
    'la',
    'los',
    'las',
    'un',
    'una',
    'y',
    'o',
    'pero',
    'si',
    'entonces',
    'porque',
    'para',
    'de',
    'del',
    'en',
    'con',
    'por',
    'a',
    'al',
    'desde',
    'yo',
    'tu',
    'tú',
    'él',
    'ella',
    'nosotros',
    'vosotros',
    'ellos',
    'ellas',
    'me',
    'te',
    'mi',
    'mis',
    'tus',
    'su',
    'sus',
    'nos',
    'os',
    'es',
    'son',
    'era',
    'eran',
    'ser',
    'no',
    'sí',
    'este',
    'esta',
    'estos',
    'estas',
    'aquí',
    'ahi',
    'ahí',
    'allí',
  };

  // Türkçe ve diğer dillerde geçerli harf karakterleri
  static const String _turkishLetters = 'abcçdefgğhıijklmnoöprsştuüvyzABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ';
  static const String _germanLetters = 'äöüßÄÖÜ';
  static const String _spanishLetters = 'áéíóúüñÁÉÍÓÚÜÑ';
  static const String _allValidLetters = _turkishLetters + _germanLetters + _spanishLetters + '0123456789';

  /// Tokenize keeping letters & numbers across languages.
  /// Improved algorithm for Turkish/German/Spanish character support.
  List<String> tokenize(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const [];

    // Önce bazı temizlikler yapalım
    var cleaned = text
        // Parantez içindeki tekrarları kaldır: (Nakarat), (x2), (2x) vb.
        .replaceAll(RegExp(r'\([^)]*\)', caseSensitive: false), ' ')
        // Köşeli parantez içindekileri kaldır: [Nakarat], [Verse 1]
        .replaceAll(RegExp(r'\[[^\]]*\]', caseSensitive: false), ' ')
        // Satır başı işaretlerini kaldır (1., 2., I., II. vb.)
        .replaceAll(RegExp(r'^\d+\.\s*', multiLine: true), ' ')
        .replaceAll(RegExp(r'^[IVX]+\.\s*', multiLine: true), ' ')
        // Tire ile ayrılmış kelimeleri ayır: "gel-di" -> "gel di"
        .replaceAll(RegExp(r'(?<=[a-zA-ZçğıöşüÇĞİÖŞÜ])-(?=[a-zA-ZçğıöşüÇĞİÖŞÜ])'), ' ')
        // Apostrophe ile birleşik kelimeleri ayır: "gel'dim" -> "gel dim"
        .replaceAll(RegExp(r"'"), ' ')
        // Birden fazla boşluğu teke indir
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) return const [];

    // Sadece geçerli harfleri ve sayıları tut, diğer her şeyi boşluk yap
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      final char = cleaned[i];
      if (_allValidLetters.contains(char) || char == ' ') {
        buffer.write(char);
      } else {
        buffer.write(' ');
      }
    }

    final finalCleaned = buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (finalCleaned.isEmpty) return const [];

    // Split on whitespace
    return finalCleaned
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toList();
  }

  Set<String> _stopFor(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return trStopwords;
      case 'en':
        return enStopwords;
      case 'de':
        return deStopwords;
      case 'es':
        return esStopwords;
      default:
        return const <String>{};
    }
  }

  /// Türkçe lowercase dönüşümü - İ->i, I->ı özel durumları
  String _turkishLowerCase(String text) {
    return text
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase();
  }

  /// Sadece harf içeren kelime mi? (sayı içermemeli)
  bool _isValidWord(String token) {
    // Sadece sayılardan oluşuyorsa geçersiz
    if (RegExp(r'^[0-9]+$').hasMatch(token)) return false;
    // En az bir harf içermeli
    return RegExp(r'[a-zA-ZçğıöşüÇĞİÖŞÜäöüßÄÖÜáéíóúüñÁÉÍÓÚÜÑ]').hasMatch(token);
  }

  /// Extracts keywords from lyrics.
  ///
  /// - Preserves diacritics (no folding).
  /// - Turkish-aware lowercase (İ->i, I->ı).
  /// - Filters out meaningless short tokens and numbers.
  ({
    List<String> keywords,
    List<String> topKeywords,
    Map<String, int> freq
  }) extract({
    required String lyricsRaw,
    required String languageCode, // tr/en/de/es
    bool removeStopwords = true,
    int minTokenLength = 3, // Minimum 3 karakter - "zd" gibi şeyleri önler
    int maxTopKeywords = 100, // Daha az ama daha kaliteli
  }) {
    final tokens = tokenize(lyricsRaw);
    if (tokens.isEmpty) {
      return (keywords: const [], topKeywords: const [], freq: const {});
    }

    final stop = _stopFor(languageCode);

    final freq = <String, int>{};
    for (final t in tokens) {
      // Türkçe için özel lowercase
      final token = languageCode == 'tr' ? _turkishLowerCase(t) : t.toLowerCase();

      // Minimum uzunluk kontrolü
      if (token.length < minTokenLength) continue;

      // Geçerli kelime kontrolü (sadece sayı değil, en az bir harf içermeli)
      if (!_isValidWord(token)) continue;

      // Stopword kontrolü
      if (removeStopwords && stop.contains(token)) continue;

      freq[token] = (freq[token] ?? 0) + 1;
    }

    final unique = freq.keys.toList()..sort();

    // Rank by frequency desc, then alphabetical
    final ranked = freq.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        if (c != 0) return c;
        return a.key.compareTo(b.key);
      });

    final top = ranked.map((e) => e.key).take(maxTopKeywords).toList();

    return (keywords: unique, topKeywords: top, freq: freq);
  }

  /// Apply manual edits from a free-form input:
  /// - split by comma/space/newline
  /// - keep diacritics
  List<String> parseManualTokens(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[,\\n\\r\\t]+', unicode: true), ' ');
    return cleaned
        .split(RegExp(r'\s+', unicode: true))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
