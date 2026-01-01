import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class WordService {
  final _rnd = Random();
  List<String> _words = const [
    "yağmur","kalp","rüya","deniz","güneş","yıldız","gece","ateş","rüzgar","aşk",
  ];

  Future<void> loadWordsFromAssets() async {
    try {
      final text = await rootBundle.loadString('assets/words_tr.txt');
      final lines = text
          .split(RegExp(r'\r?\n'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (lines.isNotEmpty) _words = lines;
    } catch (_) {
      // asset bulunamazsa yedek liste kullanılacak
    }
  }

  String randomWord() => _words[_rnd.nextInt(_words.length)];
}
