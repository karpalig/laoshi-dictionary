class PinyinHelper {
  // Tone marks mapping
  static const Map<String, List<String>> toneMarks = {
    'a': ['ā', 'á', 'ǎ', 'à', 'a'],
    'e': ['ē', 'é', 'ě', 'è', 'e'],
    'i': ['ī', 'í', 'ǐ', 'ì', 'i'],
    'o': ['ō', 'ó', 'ǒ', 'ò', 'o'],
    'u': ['ū', 'ú', 'ǔ', 'ù', 'u'],
    'ü': ['ǖ', 'ǘ', 'ǚ', 'ǜ', 'ü'],
  };

  /// Converts numbered pinyin (ni3 hao3) to tone marks (nǐ hǎo)
  static String numberedToToneMarks(String pinyin) {
    String result = pinyin;
    
    // Pattern to match pinyin syllables with tone numbers (1-4)
    final regex = RegExp(r'([a-züA-ZÜ]+)([1-4])');
    final matches = regex.allMatches(result).toList();
    
    // Process matches in reverse to maintain string indices
    for (int i = matches.length - 1; i >= 0; i--) {
      final match = matches[i];
      final syllable = match.group(1)!;
      final toneNumber = int.parse(match.group(2)!);
      
      final markedSyllable = _addToneMark(syllable, toneNumber);
      result = result.replaceRange(match.start, match.end, markedSyllable);
    }
    
    return result;
  }

  /// Adds tone mark to a pinyin syllable
  static String _addToneMark(String syllable, int tone) {
    if (tone < 1 || tone > 4) return syllable;
    
    String result = syllable.toLowerCase();
    final toneIndex = tone - 1;
    
    // Rules for tone mark placement:
    // 1. If there's an 'a' or 'e', it takes the tone mark
    // 2. If there's an 'ou', 'o' takes the tone mark
    // 3. Otherwise, the last vowel takes the tone mark
    
    if (result.contains('a')) {
      final index = result.indexOf('a');
      result = result.replaceRange(index, index + 1, toneMarks['a']![toneIndex]);
    } else if (result.contains('e')) {
      final index = result.indexOf('e');
      result = result.replaceRange(index, index + 1, toneMarks['e']![toneIndex]);
    } else if (result.contains('ou')) {
      final index = result.indexOf('o');
      result = result.replaceRange(index, index + 1, toneMarks['o']![toneIndex]);
    } else {
      // Find last vowel
      const vowels = ['i', 'o', 'u', 'ü'];
      for (final vowel in vowels.reversed) {
        final index = result.lastIndexOf(vowel);
        if (index != -1) {
          result = result.replaceRange(index, index + 1, toneMarks[vowel]![toneIndex]);
          break;
        }
      }
    }
    
    return result;
  }

  /// Normalizes text for search (removes tones, converts to lowercase)
  static String normalizeForSearch(String text) {
    String normalized = text.toLowerCase();
    
    // Remove tone marks
    toneMarks.forEach((base, variants) {
      for (final variant in variants) {
        normalized = normalized.replaceAll(variant, base);
      }
    });
    
    return normalized.trim();
  }

  /// Checks if string contains Chinese characters
  static bool containsChinese(String text) {
    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      if (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) {
        return true;
      }
    }
    return false;
  }

  /// Counts Chinese characters in string
  static int chineseCharacterCount(String text) {
    int count = 0;
    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      if (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) {
        count++;
      }
    }
    return count;
  }

  /// Returns color for HSK level
  static String colorForHSKLevel(int level) {
    switch (level) {
      case 1:
        return 'green';
      case 2:
        return 'cyan';
      case 3:
        return 'blue';
      case 4:
        return 'purple';
      case 5:
        return 'orange';
      case 6:
        return 'pink';
      default:
        return 'gray';
    }
  }
}
