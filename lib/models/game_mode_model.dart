// Game Mode Model - Challenge Mode System for Sansu Kore
// Defines 5 game modes with unique mechanics and scoring systems

import 'package:uuid/uuid.dart';
enum GameMode { normal, timeAttack, survival, flash, marathon }

enum GameModeStatus { idle, active, paused, completed, failed }

/// Configuration for each game mode
class GameModeConfig {
  final GameMode mode;
  final String displayName;
  final String description;
  final String? emoji;
  final int? timeLimit; // seconds per question
  final int? maxMisses; // max wrong answers allowed
  final int questionsPerRound;
  final int? targetQuestionsCount; // total questions for this mode

  const GameModeConfig({
    required this.mode,
    required this.displayName,
    required this.description,
    this.emoji,
    this.timeLimit,
    this.maxMisses,
    this.questionsPerRound = 5,
    this.targetQuestionsCount,
  });

  /// Get configuration for a specific game mode
  static GameModeConfig? getConfig(GameMode mode) {
    return allModes.firstWhere(
      (config) => config.mode == mode,
      orElse: () => _defaultConfig,
    );
  }

  /// Default configuration
  static const _defaultConfig = GameModeConfig(
    mode: GameMode.normal,
    displayName: 'ノーマル',
    description: '基本的な学習モード',
    emoji: '📚',
  );

  /// All mode configurations
  static const allModes = [
    GameModeConfig(
      mode: GameMode.normal,
      displayName: 'ノーマル',
      description: '基本的な学習モード。ゆっくり解いて力をつけよう！',
      emoji: '📚',
      questionsPerRound: 5,
      targetQuestionsCount: 10,
    ),
    GameModeConfig(
      mode: GameMode.timeAttack,
      displayName: 'タイムアタック',
      description: '時間制限内に正解を目指す。速度と正確性を両立させよう！',
      emoji: '⏱️',
      timeLimit: 10,
      questionsPerRound: 5,
      targetQuestionsCount: 8,
    ),
    GameModeConfig(
      mode: GameMode.survival,
      displayName: 'サバイバル',
      description: 'ミスはNG！連続正解を目指す究極のチャレンジ。',
      emoji: '💪',
      maxMisses: 3,
      questionsPerRound: 5,
      targetQuestionsCount: 20,
    ),
    GameModeConfig(
      mode: GameMode.flash,
      displayName: 'フラッシュ',
      description: '瞬時の判断が勝負。反応速度を鍛える！',
      emoji: '⚡',
      timeLimit: 5,
      questionsPerRound: 5,
      targetQuestionsCount: 15,
    ),
    GameModeConfig(
      mode: GameMode.marathon,
      displayName: 'マラソン',
      description: '最大100問！最強の持久力と集中力を試す。',
      emoji: '🏃',
      questionsPerRound: 10,
      targetQuestionsCount: 100,
    ),
  ];
}

/// Represents a user's answer to a quiz question
class UserAnswer {
  final String questionId;
  final int? selectedIndex;
  final bool isCorrect;
  final int responseTime; // milliseconds
  final DateTime answeredAt;

  UserAnswer({
    required this.questionId,
    required this.selectedIndex,
    required this.isCorrect,
    required this.responseTime,
    required this.answeredAt,
  });
}

/// Represents an active game session
class GameSession {
  final String sessionId;
  final GameMode gameMode;
  final int gradeLevel;
  final String? topicType;
  final DateTime startedAt;

  int correctAnswers = 0;
  int totalQuestions = 0;
  int totalMisses = 0;
  int currentStreak = 0;
  int maxStreak = 0;
  List<UserAnswer> answers = [];
  GameModeStatus status = GameModeStatus.active;
  DateTime? completedAt;

  GameSession({
    required this.sessionId,
    required this.gameMode,
    required this.gradeLevel,
    this.topicType,
    required this.startedAt,
  });

  // Getters
  double get correctRate => totalQuestions == 0 ? 0 : correctAnswers / totalQuestions;

  int get elapsedSeconds {
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt).inSeconds;
  }

  double get averageResponseTime {
    if (answers.isEmpty) return 0;
    final total = answers.fold<int>(0, (sum, a) => sum + a.responseTime);
    return total / answers.length / 1000; // convert to seconds
  }

  /// Complete the session successfully
  void complete() {
    status = GameModeStatus.completed;
    completedAt = DateTime.now();
  }

  /// Fail the session (e.g., survival mode game over)
  void fail() {
    status = GameModeStatus.failed;
    completedAt = DateTime.now();
  }

  /// Pause the session
  void pause() {
    status = GameModeStatus.paused;
  }

  /// Resume the session
  void resume() {
    status = GameModeStatus.active;
  }
}

/// Represents the result of a completed game session
class GameResult {
  final String resultId;
  final GameMode gameMode;
  final int gradeLevel;
  final String topicType;
  final DateTime completedAt;

  final int correctAnswers;
  final int totalQuestions;
  final int correctRate_x100; // stored as 0-100 for consistency

  final int baseScore;
  final int speedBonus;
  final int streakBonus;
  final int totalScore;

  final int coinsEarned;
  final List<String> badgesUnlocked;

  final int maxStreak;
  final double averageResponseTime;
  final int elapsedSeconds;

  GameResult({
    String? resultId,
    required this.gameMode,
    required this.gradeLevel,
    required this.topicType,
    required this.completedAt,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.correctRate_x100,
    required this.baseScore,
    required this.speedBonus,
    required this.streakBonus,
    required this.totalScore,
    required this.coinsEarned,
    required this.badgesUnlocked,
    required this.maxStreak,
    required this.averageResponseTime,
    required this.elapsedSeconds,
  }) : resultId = resultId ?? const Uuid().v4();

  double get correctRate => correctRate_x100 / 100.0;

  /// Calculate final result from a completed session
  static GameResult calculateResult({
    required GameSession session,
    required int elapsedSeconds,
    required int gradeLevel,
    required String topicType,
  }) {
    // Base score: correct answers × 100
    final baseScore = session.correctAnswers * 100;

    // Speed bonus
    final avgResponseTime = session.averageResponseTime;
    int speedBonus = 0;
    if (avgResponseTime < 1) {
      speedBonus = 100;
    } else if (avgResponseTime < 2) {
      speedBonus = 50;
    }

    // Streak bonus
    int streakBonus = 0;
    if (session.maxStreak > 5) {
      streakBonus = (session.maxStreak - 5) * 10;
    }

    // Difficulty multiplier (based on correct rate)
    double difficultyMultiplier = 1.0;
    if (session.correctRate >= 0.9) {
      difficultyMultiplier = 2.0;
    } else if (session.correctRate >= 0.8) {
      difficultyMultiplier = 1.5;
    } else if (session.correctRate >= 0.7) {
      difficultyMultiplier = 1.2;
    }

    // Apply mode-specific bonuses
    int modifiedSpeedBonus = speedBonus;
    int modifiedStreakBonus = streakBonus;

    if (session.gameMode == GameMode.marathon) {
      modifiedSpeedBonus = (speedBonus * 1.5).toInt();
      modifiedStreakBonus = (streakBonus * 2).toInt();
    } else if (session.gameMode == GameMode.timeAttack) {
      modifiedSpeedBonus = (speedBonus * 2).toInt();
    }

    // Calculate total score
    final totalScore = (
          (baseScore + modifiedSpeedBonus + modifiedStreakBonus) *
          difficultyMultiplier
        ).toInt();

    // Calculate coins earned
    int coinsEarned = (session.correctAnswers * 10).toInt();
    if (session.correctRate >= 0.9) {
      coinsEarned = (coinsEarned * 1.5).toInt();
    } else if (session.correctRate >= 0.8) {
      coinsEarned = (coinsEarned * 1.2).toInt();
    }

    // Determine badges unlocked
    final badgesUnlocked = <String>[];
    if (session.correctRate >= 1.0) {
      badgesUnlocked.add('パーフェクト');
    }
    if (session.correctRate >= 0.9) {
      badgesUnlocked.add('スーパースター');
    }
    if (session.maxStreak >= 10) {
      badgesUnlocked.add('連続マスター');
    }
    if (session.gameMode == GameMode.survival && session.totalMisses == 0) {
      badgesUnlocked.add('サバイバルチャンピオン');
    }

    return GameResult(
      gameMode: session.gameMode,
      gradeLevel: gradeLevel,
      topicType: topicType,
      completedAt: DateTime.now(),
      correctAnswers: session.correctAnswers,
      totalQuestions: session.totalQuestions,
      correctRate_x100: (session.correctRate * 100).toInt(),
      baseScore: baseScore,
      speedBonus: modifiedSpeedBonus,
      streakBonus: modifiedStreakBonus,
      totalScore: totalScore,
      coinsEarned: coinsEarned,
      badgesUnlocked: badgesUnlocked,
      maxStreak: session.maxStreak,
      averageResponseTime: session.averageResponseTime,
      elapsedSeconds: elapsedSeconds,
    );
  }
}

/// Statistics for a specific game mode
class GameModeStats {
  final GameMode gameMode;
  final int timesPlayed;
  final int totalScore;
  final double averageScore;
  final double bestScore;
  final double averageCorrectRate;
  final DateTime? lastPlayed;

  GameModeStats({
    required this.gameMode,
    required this.timesPlayed,
    required this.totalScore,
    required this.averageScore,
    required this.bestScore,
    required this.averageCorrectRate,
    this.lastPlayed,
  });
}
