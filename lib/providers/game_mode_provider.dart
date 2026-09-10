// Game Mode Provider - Riverpod State Management
// Manages game sessions, results, and statistics

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sansu_kore/models/game_mode_model.dart';
import 'package:uuid/uuid.dart';

/// 現在のゲームセッション状態
class GameSessionState {
  final GameSession? currentSession;
  final bool isLoading;
  final String? error;

  GameSessionState({
    this.currentSession,
    this.isLoading = false,
    this.error,
  });

  GameSessionState copyWith({
    GameSession? currentSession,
    bool? isLoading,
    String? error,
  }) {
    return GameSessionState(
      currentSession: currentSession ?? this.currentSession,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// ゲームモード結果の一覧
class GameResultsState {
  final List<GameResult> results;
  final bool isLoading;
  final String? error;

  GameResultsState({
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  GameResultsState copyWith({
    List<GameResult>? results,
    bool? isLoading,
    String? error,
  }) {
    return GameResultsState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 現在のゲームセッションを管理するNotifier
class GameSessionNotifier extends StateNotifier<GameSessionState> {
  GameSessionNotifier() : super(GameSessionState());

  /// 新しいゲームセッションを開始
  void startSession({
    required GameMode gameMode,
    required int gradeLevel,
    String? topicType,
  }) {
    final sessionId = const Uuid().v4();
    final session = GameSession(
      sessionId: sessionId,
      gameMode: gameMode,
      gradeLevel: gradeLevel,
      topicType: topicType,
      startedAt: DateTime.now(),
    );
    state = state.copyWith(currentSession: session);
  }

  /// 回答を記録
  void recordAnswer({
    required String questionId,
    required int? selectedIndex,
    required bool isCorrect,
    required int responseTimeMs,
  }) {
    final session = state.currentSession;
    if (session == null) return;

    final answer = UserAnswer(
      questionId: questionId,
      selectedIndex: selectedIndex,
      isCorrect: isCorrect,
      responseTime: responseTimeMs,
      answeredAt: DateTime.now(),
    );

    session.answers.add(answer);
    session.totalQuestions++;

    if (isCorrect) {
      session.correctAnswers++;
      session.currentStreak++;
      if (session.currentStreak > session.maxStreak) {
        session.maxStreak = session.currentStreak;
      }
    } else {
      session.currentStreak = 0;
      if (session.gameMode == GameMode.survival) {
        session.totalMisses++;
      }
    }

    state = state.copyWith(currentSession: session);
  }

  /// ゲーム終了
  void completeSession() {
    final session = state.currentSession;
    if (session == null) return;

    session.complete();
    state = state.copyWith(currentSession: session);
  }

  /// ゲーム失敗（サバイバルモード用）
  void failSession() {
    final session = state.currentSession;
    if (session == null) return;

    session.fail();
    state = state.copyWith(currentSession: session);
  }

  /// セッションをリセット
  void resetSession() {
    state = GameSessionState();
  }

  /// 一時停止
  void pauseSession() {
    final session = state.currentSession;
    if (session == null) return;

    session.pause();
    state = state.copyWith(currentSession: session);
  }

  /// 再開
  void resumeSession() {
    final session = state.currentSession;
    if (session == null) return;

    session.resume();
    state = state.copyWith(currentSession: session);
  }
}

/// ゲーム結果を管理するNotifier
class GameResultsNotifier extends StateNotifier<GameResultsState> {
  GameResultsNotifier() : super(GameResultsState());

  /// 結果を追加
  void addResult(GameResult result) {
    final newResults = [...state.results, result];
    state = state.copyWith(results: newResults);
  }

  /// モード別の結果を取得
  List<GameResult> getResultsByMode(GameMode mode) {
    return state.results.where((r) => r.gameMode == mode).toList();
  }

  /// 最高スコアを取得
  int? getHighScore(GameMode mode) {
    final modeResults = getResultsByMode(mode);
    if (modeResults.isEmpty) return null;
    return modeResults.map((r) => r.totalScore).reduce((a, b) => a > b ? a : b);
  }

  /// 平均スコアを計算
  double getAverageScore(GameMode mode) {
    final modeResults = getResultsByMode(mode);
    if (modeResults.isEmpty) return 0.0;
    final total = modeResults.fold<int>(0, (sum, r) => sum + r.totalScore);
    return total / modeResults.length;
  }

  /// 結果をクリア
  void clearResults() {
    state = GameResultsState();
  }
}

/// Providers

/// 現在のゲームセッション
final gameSessionProvider = StateNotifierProvider<GameSessionNotifier, GameSessionState>((ref) {
  return GameSessionNotifier();
});

/// ゲーム結果の履歴
final gameResultsProvider = StateNotifierProvider<GameResultsNotifier, GameResultsState>((ref) {
  return GameResultsNotifier();
});

/// 特定のゲームモード統計
final gameModeStatsProvider = Provider.family<GameModeStats?, GameMode>((ref, gameMode) {
  final resultsState = ref.watch(gameResultsProvider);
  final results = resultsState.results.where((r) => r.gameMode == gameMode).toList();

  if (results.isEmpty) {
    return null;
  }

  final totalScore = results.fold<int>(0, (sum, r) => sum + r.totalScore);
  final averageScore = totalScore / results.length;
  final bestScore = results.map((r) => r.totalScore).reduce((a, b) => a > b ? a : b);
  final averageCorrectRate = results.fold<double>(0, (sum, r) => sum + r.correctRate) / results.length;

  return GameModeStats(
    gameMode: gameMode,
    timesPlayed: results.length,
    totalScore: totalScore,
    averageScore: averageScore,
    bestScore: bestScore.toDouble(),
    averageCorrectRate: averageCorrectRate,
    lastPlayed: results.last.completedAt,
  );
});

/// 全ゲームモード統計
final allGameModeStatsProvider = Provider<Map<GameMode, GameModeStats?>>((ref) {
  final stats = <GameMode, GameModeStats?>{};
  for (final mode in GameMode.values) {
    stats[mode] = ref.watch(gameModeStatsProvider(mode));
  }
  return stats;
});

/// 総プレイ時間（分）
final totalPlayTimeProvider = Provider<int>((ref) {
  final results = ref.watch(gameResultsProvider).results;
  return results.fold<int>(0, (sum, r) => sum + r.elapsedSeconds) ~/ 60;
});

/// 総獲得コイン
final totalCoinsEarnedProvider = Provider<int>((ref) {
  final results = ref.watch(gameResultsProvider).results;
  return results.fold<int>(0, (sum, r) => sum + r.coinsEarned);
});

/// ゲームセッションの情報パネル用 - 進行状況表示
final gameSessionProgressProvider = Provider<({
  int correctAnswers,
  int totalQuestions,
  double correctRate,
  int currentStreak,
  int maxStreak,
  int totalMisses,
})?>((ref) {
  final session = ref.watch(gameSessionProvider).currentSession;
  if (session == null) return null;

  return (
    correctAnswers: session.correctAnswers,
    totalQuestions: session.totalQuestions,
    correctRate: session.correctRate,
    currentStreak: session.currentStreak,
    maxStreak: session.maxStreak,
    totalMisses: session.totalMisses,
  );
});

/// モード別の高スコア（リーダーボード向け）
final highScoresByModeProvider = Provider<Map<GameMode, int?>>((ref) {
  final stats = ref.watch(allGameModeStatsProvider);
  final highScores = <GameMode, int?>{};

  for (final mode in GameMode.values) {
    final modeStats = stats[mode];
    highScores[mode] = modeStats != null ? modeStats.bestScore.toInt() : null;
  }

  return highScores;
});
