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

  /// Tokenize keeping letters & numbers across languages.
  /// Uses Unicode-aware character classes (unicode: true), so Turkish/German/Spanish
  /// letters are preserved without relying on \p{...} (which Dart RegExp may not support).
  List<String> tokenize(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const [];

    // Keep Unicode "word" chars via \w under unicode: true.
    // Note: \w includes underscore. We treat underscores as separators.
    final cleaned = text
        .replaceAll(RegExp(r'[_]+', unicode: true), ' ')
        .replaceAll(RegExp(r'[^\w]+', unicode: true), ' ')
        .trim();

    if (cleaned.isEmpty) return const [];

    // Split on whitespace
    return cleaned
        .split(RegExp(r'\s+', unicode: true))
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

  /// Extracts keywords from lyrics.
  ///
  /// - Preserves diacritics (no folding).
  /// - Lowercases tokens for consistency (note: Turkish dotted-i edge cases can produce combining marks;
  ///   we preserve the result as-is to keep fidelity).
  ({
    List<String> keywords,
    List<String> topKeywords,
    Map<String, int> freq
  }) extract({
    required String lyricsRaw,
    required String languageCode, // tr/en/de/es
    bool removeStopwords = true,
    int minTokenLength = 2,
    int maxTopKeywords = 160,
  }) {
    final tokens = tokenize(lyricsRaw);
    if (tokens.isEmpty) {
      return (keywords: const [], topKeywords: const [], freq: const {});
    }

    final stop = _stopFor(languageCode);

    final freq = <String, int>{};
    for (final t in tokens) {
      final token = t.toLowerCase();
      if (token.length < minTokenLength) continue;
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
