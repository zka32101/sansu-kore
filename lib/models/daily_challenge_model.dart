// Daily Challenge Model - Recurring daily challenges and login bonuses
// Features: Daily challenge, login streak, bonus rewards

import 'package:uuid/uuid.dart';
import 'package:sansu_kore/models/quest_model.dart';

/// Daily Challenge Status
enum DailyChallengeStatus { notStarted, inProgress, completed, expired }

/// Represents a single day's challenge
class DailyChallenge {
  final String id;
  final DateTime dateIssued; // Date this challenge was issued
  final List<QuizQuestion> questions; // 5 questions for today
  final DateTime expiresAt; // Midnight of next day

  final int baseCoinsReward; // Base coins for completing
  final int streakBonusCoins; // Bonus based on login streak

  DailyChallenge({
    String? id,
    required this.dateIssued,
    required this.questions,
    required this.expiresAt,
    this.baseCoinsReward = 50,
    this.streakBonusCoins = 10,
  }) : id = id ?? const Uuid().v4();

  /// Check if challenge is still valid (before expiration)
  bool get isValid => DateTime.now().isBefore(expiresAt);

  /// Check if challenge is expired
  bool get isExpired => !isValid;

  /// Get today's challenge (creates new if none exists or previous expired)
  static DateTime getTodayDateOnly() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Check if challenge is for today
  bool get isToday {
    final today = getTodayDateOnly();
    final issueDate = DateTime(dateIssued.year, dateIssued.month, dateIssued.day);
    return issueDate.isAtSameMomentAs(today);
  }
}

/// Result of completing a daily challenge
class DailyChallengeResult {
  final String challengeId;
  final String userId;
  final DateTime completedAt;

  final int correctAnswers;
  final int totalQuestions;
  final double correctRate;

  final int coinsEarned;
  final List<String> badgesUnlocked;
  final bool isPerfect; // All 5 correct

  DailyChallengeResult({
    required this.challengeId,
    required this.userId,
    required this.completedAt,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.coinsEarned,
    required this.badgesUnlocked,
    this.isPerfect = false,
  }) : correctRate = totalQuestions == 0 ? 0 : correctAnswers / totalQuestions;

  /// Calculate coins earned based on performance
  static int calculateCoins(int correctAnswers, int totalQuestions, int baseReward) {
    final correctRate = totalQuestions == 0 ? 0 : correctAnswers / totalQuestions;

    // Base reward
    int coins = baseReward;

    // Performance bonus
    if (correctRate >= 1.0) {
      coins = (coins * 1.5).toInt(); // Perfect: 1.5x
    } else if (correctRate >= 0.8) {
      coins = (coins * 1.2).toInt(); // Good: 1.2x
    } else if (correctRate >= 0.6) {
      coins = (coins * 1.0).toInt(); // Pass: 1x
    }

    return coins;
  }
}

// 注: 旧 LoginBonus モデル（連続ログイン管理）はここに定義されていたが、
// SharedPreferences に永続化されず、実際のコイン付与にも接続されていない
// 重複実装だったため削除した。連続ログイン・コイン付与は
// lib/providers/daily_login_provider.dart の DailyLoginState /
// dailyLoginProvider（永続化され、DailyBonusScreen の「受け取る」操作で
// 実際にコインが加算される）に一本化されている。

/// Daily challenge state
class DailyChallengeState {
  final DailyChallenge? currentChallenge;
  final DailyChallengeResult? todayResult;
  final bool isLoading;
  final String? error;

  DailyChallengeState({
    this.currentChallenge,
    this.todayResult,
    this.isLoading = false,
    this.error,
  });

  DailyChallengeState copyWith({
    DailyChallenge? currentChallenge,
    DailyChallengeResult? todayResult,
    bool? isLoading,
    String? error,
  }) {
    return DailyChallengeState(
      currentChallenge: currentChallenge ?? this.currentChallenge,
      todayResult: todayResult ?? this.todayResult,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Check if challenge is available today
  bool get isChallengeAvailable {
    if (currentChallenge == null) return false;
    if (!currentChallenge!.isValid) return false;
    if (todayResult != null) return false; // Already completed
    return true;
  }

  /// Check if challenge is completed
  bool get isChallengeCompleted => todayResult != null;

  /// Days until next daily challenge reset
  int get hoursUntilReset {
    if (currentChallenge == null) return 0;
    final now = DateTime.now();
    return currentChallenge!.expiresAt.difference(now).inHours;
  }
}
