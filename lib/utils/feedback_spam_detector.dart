/// Intelligent Spam & Gibberish Detection for Feedback System
/// Detects scrambled words, random characters, and unreadable messages
class FeedbackSpamDetector {
  // ============= CONFIGURATION =============
  static const double SPAM_THRESHOLD = 0.6; // 60% confidence = spam
  static const int MIN_WORD_LENGTH = 3;
  static const int MAX_SPECIAL_CHAR_RATIO = 30; // 30% special chars
  static const int MAX_CONSONANT_STREAK = 7;
  static const int MAX_REPETITION_RATIO = 40; // 40% repeated chars

  // Common spam patterns
  static final List<RegExp> _spamPatterns = [
    RegExp(r'(.)\1{5,}', caseSensitive: false), // Same char 6+ times
    RegExp(r'[^a-zA-Z0-9\s]{10,}'), // 10+ special chars in a row
    RegExp(r'[qwrtypsdfghjklzxcvbnm]{8,}', caseSensitive: false), // Keyboard mashing
    RegExp(r'^[aeiou]{15,}$', caseSensitive: false), // Only vowels (spam)
    RegExp(r'^[^aeiou\s]{15,}$', caseSensitive: false), // Only consonants
  ];

  // Common words whitelist (expandable)
  static final Set<String> _commonWords = {
    'the', 'and', 'for', 'with', 'this', 'that', 'have', 'from',
    'they', 'will', 'would', 'about', 'when', 'what', 'where',
    'appointment', 'clinic', 'doctor', 'pet', 'service', 'help',
    'please', 'thank', 'sorry', 'issue', 'problem', 'bug', 'error',
    // Add more as needed
  };

  /// Main spam detection method
  /// Returns true if message is spam/gibberish
  static bool isSpamOrGibberish(String message) {
    if (message.trim().isEmpty) return true;

    final spamScore = _calculateSpamScore(message);
    
    print('>>> SPAM DETECTOR: "${message.substring(0, message.length > 50 ? 50 : message.length)}..."');
    print('>>> Spam Score: ${(spamScore * 100).toStringAsFixed(1)}%');
    print('>>> Is Spam: ${spamScore >= SPAM_THRESHOLD}');

    return spamScore >= SPAM_THRESHOLD;
  }

  /// Calculate spam probability (0.0 - 1.0)
  static double _calculateSpamScore(String message) {
    double totalScore = 0.0;
    int checks = 0;

    // Check 1: Special character ratio
    final specialCharScore = _checkSpecialCharacterRatio(message);
    totalScore += specialCharScore;
    checks++;

    // Check 2: Consonant streaks (gibberish detection)
    final consonantScore = _checkConsonantStreaks(message);
    totalScore += consonantScore;
    checks++;

    // Check 3: Repetitive patterns
    final repetitionScore = _checkRepetitivePatterns(message);
    totalScore += repetitionScore;
    checks++;

    // Check 4: Recognizable words
    final wordScore = _checkRecognizableWords(message);
    totalScore += wordScore;
    checks++;

    // Check 5: Spam pattern matching
    final patternScore = _checkSpamPatterns(message);
    totalScore += patternScore;
    checks++;

    // Check 6: Random case mixing (LiKe ThIs)
    final caseScore = _checkRandomCaseMixing(message);
    totalScore += caseScore;
    checks++;

    return totalScore / checks;
  }

  /// Check 1: Too many special characters
  static double _checkSpecialCharacterRatio(String message) {
    final specialChars = message.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '');
    final ratio = (specialChars.length / message.length) * 100;

    if (ratio > MAX_SPECIAL_CHAR_RATIO) {
      return 1.0; // Definitely spam
    } else if (ratio > MAX_SPECIAL_CHAR_RATIO * 0.7) {
      return 0.7; // Probably spam
    } else if (ratio > MAX_SPECIAL_CHAR_RATIO * 0.4) {
      return 0.4; // Suspicious
    }
    return 0.0;
  }

  /// Check 2: Unrealistic consonant streaks (gibberish)
  static double _checkConsonantStreaks(String message) {
    final words = message.toLowerCase().split(RegExp(r'\s+'));
    int violationCount = 0;

    for (var word in words) {
      if (word.length < MIN_WORD_LENGTH) continue;

      int consonantStreak = 0;
      for (var char in word.split('')) {
        if ('bcdfghjklmnpqrstvwxyz'.contains(char)) {
          consonantStreak++;
          if (consonantStreak > MAX_CONSONANT_STREAK) {
            violationCount++;
            break;
          }
        } else {
          consonantStreak = 0;
        }
      }
    }

    final ratio = words.isEmpty ? 0.0 : violationCount / words.length;
    return ratio > 0.3 ? 1.0 : ratio * 2;
  }

  /// Check 3: Repetitive character patterns
  static double _checkRepetitivePatterns(String message) {
    final cleaned = message.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return 0.0;

    final charCounts = <String, int>{};
    for (var char in cleaned.split('')) {
      charCounts[char] = (charCounts[char] ?? 0) + 1;
    }

    final maxRepeat = charCounts.values.fold(0, (max, count) => count > max ? count : max);
    final repeatRatio = (maxRepeat / cleaned.length) * 100;

    if (repeatRatio > MAX_REPETITION_RATIO) {
      return 1.0;
    } else if (repeatRatio > MAX_REPETITION_RATIO * 0.7) {
      return 0.7;
    } else if (repeatRatio > MAX_REPETITION_RATIO * 0.4) {
      return 0.4;
    }
    return 0.0;
  }

  /// Check 4: Recognizable words ratio
  static double _checkRecognizableWords(String message) {
    final words = message.toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= MIN_WORD_LENGTH)
        .toList();

    if (words.isEmpty) return 1.0; // No words = spam

    int recognizedCount = 0;
    for (var word in words) {
      if (_commonWords.contains(word)) {
        recognizedCount++;
      }
    }

    final recognizedRatio = recognizedCount / words.length;

    // Inverse score: less recognized words = higher spam score
    if (recognizedRatio < 0.1) {
      return 1.0; // Almost no recognized words
    } else if (recognizedRatio < 0.3) {
      return 0.7; // Few recognized words
    } else if (recognizedRatio < 0.5) {
      return 0.3; // Some recognized words
    }
    return 0.0; // Mostly recognized words
  }

  /// Check 5: Known spam patterns
  static double _checkSpamPatterns(String message) {
    for (var pattern in _spamPatterns) {
      if (pattern.hasMatch(message)) {
        return 1.0; // Matched known spam pattern
      }
    }
    return 0.0;
  }

  /// Check 6: Random case mixing (common in spam)
  static double _checkRandomCaseMixing(String message) {
    final letters = message.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (letters.length < 10) return 0.0;

    int caseChanges = 0;
    bool lastWasUpper = letters[0] == letters[0].toUpperCase();

    for (int i = 1; i < letters.length; i++) {
      bool currentIsUpper = letters[i] == letters[i].toUpperCase();
      if (currentIsUpper != lastWasUpper) {
        caseChanges++;
      }
      lastWasUpper = currentIsUpper;
    }

    final changeRatio = caseChanges / letters.length;

    // Excessive case changes = spam
    if (changeRatio > 0.4) return 1.0;
    if (changeRatio > 0.25) return 0.6;
    if (changeRatio > 0.15) return 0.3;
    return 0.0;
  }

  /// Get detailed spam analysis (for admin review)
  static Map<String, dynamic> analyzeMessage(String message) {
    return {
      'message': message,
      'isSpam': isSpamOrGibberish(message),
      'spamScore': _calculateSpamScore(message),
      'specialCharRatio': _checkSpecialCharacterRatio(message),
      'consonantStreakScore': _checkConsonantStreaks(message),
      'repetitionScore': _checkRepetitivePatterns(message),
      'wordRecognitionScore': _checkRecognizableWords(message),
      'patternMatchScore': _checkSpamPatterns(message),
      'caseMixingScore': _checkRandomCaseMixing(message),
    };
  }
}