import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clearedPrefix = 'stage_cleared_';
const _streakKey = 'streak_count';
const _lastStudyKey = 'last_study_date';
const _totalCorrectKey = 'total_correct';
// content1/content2 は各アプリの2大コンテンツ種別 (例: 漢字/読解, 計算/文章題)
const _totalPrimaryKey = 'total_primary_correct';
const _totalSecondaryKey = 'total_secondary_correct';
const _maxClearedKey = 'max_stage_cleared';
const _perfectStageKey = 'perfect_stage_count';

class LearningProgress {
  final Set<String> clearedStageIds;
  final int streakDays;
  final DateTime? lastStudyDate;
  final int totalCorrect;
  final int totalPrimaryCorrect;
  final int totalSecondaryCorrect;
  final int maxStageCleared;
  final int perfectStageCount;

  const LearningProgress({
    required this.clearedStageIds,
    required this.streakDays,
    this.lastStudyDate,
    required this.totalCorrect,
    required this.totalPrimaryCorrect,
    required this.totalSecondaryCorrect,
    required this.maxStageCleared,
    required this.perfectStageCount,
  });

  LearningProgress copyWith({
    Set<String>? clearedStageIds,
    int? streakDays,
    DateTime? lastStudyDate,
    int? totalCorrect,
    int? totalPrimaryCorrect,
    int? totalSecondaryCorrect,
    int? maxStageCleared,
    int? perfectStageCount,
  }) {
    return LearningProgress(
      clearedStageIds: clearedStageIds ?? this.clearedStageIds,
      streakDays: streakDays ?? this.streakDays,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalPrimaryCorrect: totalPrimaryCorrect ?? this.totalPrimaryCorrect,
      totalSecondaryCorrect: totalSecondaryCorrect ?? this.totalSecondaryCorrect,
      maxStageCleared: maxStageCleared ?? this.maxStageCleared,
      perfectStageCount: perfectStageCount ?? this.perfectStageCount,
    );
  }

  bool isCleared(int grade, int stageNumber) {
    return clearedStageIds.contains('g${grade}_s$stageNumber');
  }

  static const empty = LearningProgress(
    clearedStageIds: {},
    streakDays: 0,
    totalCorrect: 0,
    totalPrimaryCorrect: 0,
    totalSecondaryCorrect: 0,
    maxStageCleared: 0,
    perfectStageCount: 0,
  );
}

class ProgressNotifier extends Notifier<LearningProgress> {
  @override
  LearningProgress build() => LearningProgress.empty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_clearedPrefix)).toSet();
    final cleared = keys.map((k) => k.replaceFirst(_clearedPrefix, '')).toSet();

    final lastStudyStr = prefs.getString(_lastStudyKey);
    DateTime? lastStudy;
    if (lastStudyStr != null) {
      lastStudy = DateTime.tryParse(lastStudyStr);
    }

    state = LearningProgress(
      clearedStageIds: cleared,
      streakDays: prefs.getInt(_streakKey) ?? 0,
      lastStudyDate: lastStudy,
      totalCorrect: prefs.getInt(_totalCorrectKey) ?? 0,
      totalPrimaryCorrect: prefs.getInt(_totalPrimaryKey) ?? 0,
      totalSecondaryCorrect: prefs.getInt(_totalSecondaryKey) ?? 0,
      maxStageCleared: prefs.getInt(_maxClearedKey) ?? 0,
      perfectStageCount: prefs.getInt(_perfectStageKey) ?? 0,
    );
  }

  Future<void> recordResult({
    required int grade,
    required int stageNumber,
    required int correct,
    required int total,
    required bool isPrimary, // true=content1(漢字/計算等), false=content2(読解/文章題等)
    required bool isPerfect,
  }) async {
    // 正解率6割未満はクリア扱いにしない（全問不正解でもクリアになるバグの修正）
    final isPassed = total > 0 && correct / total >= 0.6;

    final prefs = await SharedPreferences.getInstance();
    final stageId = 'g${grade}_s$stageNumber';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int streak = state.streakDays;
    final lastStudy = state.lastStudyDate;
    if (lastStudy == null) {
      streak = 1;
    } else {
      final lastDay = DateTime(lastStudy.year, lastStudy.month, lastStudy.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        streak = 1;
      }
    }

    final newCleared = isPassed
        ? {...state.clearedStageIds, stageId}
        : state.clearedStageIds;
    final newTotal = state.totalCorrect + correct;
    final newPrimary = state.totalPrimaryCorrect + (isPrimary ? correct : 0);
    final newSecondary = state.totalSecondaryCorrect + (isPrimary ? 0 : correct);
    final newMax = isPassed && stageNumber > state.maxStageCleared
        ? stageNumber
        : state.maxStageCleared;
    final newPerfect = isPassed && isPerfect ? state.perfectStageCount + 1 : state.perfectStageCount;

    if (isPassed) {
      await prefs.setBool('$_clearedPrefix$stageId', true);
    }
    await prefs.setInt(_streakKey, streak);
    await prefs.setString(_lastStudyKey, today.toIso8601String());
    await prefs.setInt(_totalCorrectKey, newTotal);
    await prefs.setInt(_totalPrimaryKey, newPrimary);
    await prefs.setInt(_totalSecondaryKey, newSecondary);
    await prefs.setInt(_maxClearedKey, newMax);
    await prefs.setInt(_perfectStageKey, newPerfect);

    state = state.copyWith(
      clearedStageIds: newCleared,
      streakDays: streak,
      lastStudyDate: today,
      totalCorrect: newTotal,
      totalPrimaryCorrect: newPrimary,
      totalSecondaryCorrect: newSecondary,
      maxStageCleared: newMax,
      perfectStageCount: newPerfect,
    );
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs.getKeys()
        .where((k) =>
            k.startsWith(_clearedPrefix) ||
            k == _streakKey ||
            k == _lastStudyKey ||
            k == _totalCorrectKey ||
            k == _totalPrimaryKey ||
            k == _totalSecondaryKey ||
            k == _maxClearedKey ||
            k == _perfectStageKey)
        .toList();
    for (final k in keysToRemove) {
      await prefs.remove(k);
    }
    state = LearningProgress.empty;
  }
}

final progressProvider =
    NotifierProvider<ProgressNotifier, LearningProgress>(ProgressNotifier.new);
