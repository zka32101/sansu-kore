// Guide Progress Provider - Track math guide viewing history and completion
// Features: Progress persistence, completion tracking, guide recommendations

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sansu_kore/models/math_guide_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ガイド進捗状態
class GuideProgressState {
  final Map<String, GuideProgress> progressMap;

  const GuideProgressState({required this.progressMap});

  /// 特定のガイドの進捗を取得
  GuideProgress? getProgress(String guideId) => progressMap[guideId];

  /// ガイドが完了したかを確認
  bool isGuideCompleted(String guideId) {
    final progress = progressMap[guideId];
    return progress?.isCompleted ?? false;
  }

  /// 視聴済みガイドの数
  int get viewedGuidesCount => progressMap.length;

  /// 完了済みガイドの数
  int get completedGuidesCount =>
      progressMap.values.where((p) => p.isCompleted).length;

  GuideProgressState copyWith({
    Map<String, GuideProgress>? progressMap,
  }) {
    return GuideProgressState(
      progressMap: progressMap ?? this.progressMap,
    );
  }
}

/// ガイド進捗管理
class GuideProgressNotifier extends StateNotifier<GuideProgressState> {
  GuideProgressNotifier()
      : super(const GuideProgressState(progressMap: {})) {
    _initialize();
  }

  /// 初期化 - SharedPreferencesから読み込む
  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressData = prefs.getStringList('guide_progress_keys') ?? [];

      final Map<String, GuideProgress> progressMap = {};
      for (final key in progressData) {
        final guideName = prefs.getString('guide_progress_${key}_guideName');
        final gradeStr =
            prefs.getString('guide_progress_${key}_gradeLevel');
        final viewedAtStr =
            prefs.getString('guide_progress_${key}_viewedAt');
        final lastStep =
            prefs.getInt('guide_progress_${key}_lastStep') ?? 0;
        final isCompleted =
            prefs.getBool('guide_progress_${key}_isCompleted') ?? false;

        if (guideName != null && gradeStr != null && viewedAtStr != null) {
          try {
            final gradeLevel = GradeLevel.values
                .firstWhere((g) => g.name == gradeStr);
            final viewedAt = DateTime.parse(viewedAtStr);
            progressMap[key] = GuideProgress(
              guideId: key,
              gradeLevel: gradeLevel,
              viewedAt: viewedAt,
              lastStepViewed: lastStep,
              isCompleted: isCompleted,
            );
          } catch (e) {
            if (kDebugMode) print('Error loading guide progress for $key: $e');
          }
        }
      }

      state = state.copyWith(progressMap: progressMap);
    } catch (e) {
      if (kDebugMode) print('Error initializing guide progress: $e');
    }
  }

  /// ガイドを視聴開始
  Future<void> startGuide(MathGuide guide) async {
    try {
      final progress = GuideProgress(
        guideId: guide.id,
        gradeLevel: guide.gradeLevel,
        viewedAt: DateTime.now(),
        lastStepViewed: 0,
        isCompleted: false,
      );

      state = state.copyWith(
        progressMap: {
          ...state.progressMap,
          guide.id: progress,
        },
      );

      await _saveProgress(guide.id, progress);
    } catch (e) {
      if (kDebugMode) print('Error starting guide: $e');
    }
  }

  /// ガイドのステップを更新
  Future<void> updateGuideStep(
    String guideId,
    int stepNumber,
    bool isCompleted,
  ) async {
    try {
      final currentProgress = state.progressMap[guideId];
      if (currentProgress == null) return;

      final updatedProgress = currentProgress.copyWith(
        lastStepViewed: stepNumber,
        isCompleted: isCompleted,
      );

      state = state.copyWith(
        progressMap: {
          ...state.progressMap,
          guideId: updatedProgress,
        },
      );

      await _saveProgress(guideId, updatedProgress);
    } catch (e) {
      if (kDebugMode) print('Error updating guide step: $e');
    }
  }

  /// ガイドを完了
  Future<void> completeGuide(String guideId) async {
    try {
      final currentProgress = state.progressMap[guideId];
      if (currentProgress == null) return;

      final completedProgress = currentProgress.copyWith(
        isCompleted: true,
      );

      state = state.copyWith(
        progressMap: {
          ...state.progressMap,
          guideId: completedProgress,
        },
      );

      await _saveProgress(guideId, completedProgress);
    } catch (e) {
      if (kDebugMode) print('Error completing guide: $e');
    }
  }

  /// 進捗をSavedPreferencesに保存
  Future<void> _saveProgress(
      String guideId, GuideProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ガイドIDをリストに追加
      final keys = prefs.getStringList('guide_progress_keys') ?? [];
      if (!keys.contains(guideId)) {
        keys.add(guideId);
        await prefs.setStringList('guide_progress_keys', keys);
      }

      // 進捗データを保存
      await prefs.setString(
          'guide_progress_${guideId}_guideName', progress.guideId);
      await prefs.setString(
          'guide_progress_${guideId}_gradeLevel', progress.gradeLevel.name);
      await prefs.setString('guide_progress_${guideId}_viewedAt',
          progress.viewedAt.toIso8601String());
      await prefs.setInt(
          'guide_progress_${guideId}_lastStep', progress.lastStepViewed);
      await prefs.setBool('guide_progress_${guideId}_isCompleted',
          progress.isCompleted);
    } catch (e) {
      if (kDebugMode) print('Error saving guide progress: $e');
    }
  }

  /// すべての進捗をリセット
  Future<void> resetProgress() async {
    try {
      state = const GuideProgressState(progressMap: {});

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getStringList('guide_progress_keys') ?? [];
      for (final key in keys) {
        await prefs.remove('guide_progress_${key}_guideName');
        await prefs.remove('guide_progress_${key}_gradeLevel');
        await prefs.remove('guide_progress_${key}_viewedAt');
        await prefs.remove('guide_progress_${key}_lastStep');
        await prefs.remove('guide_progress_${key}_isCompleted');
      }
      await prefs.remove('guide_progress_keys');
    } catch (e) {
      if (kDebugMode) print('Error resetting guide progress: $e');
    }
  }
}

/// ガイド進捗プロバイダ
final guideProgressProvider =
    StateNotifierProvider<GuideProgressNotifier, GuideProgressState>(
  (ref) => GuideProgressNotifier(),
);

/// ガイド完了率プロバイダ
final guideCompletionRateProvider =
    FutureProvider<double>((ref) async {
  final progress = ref.watch(guideProgressProvider);
  if (progress.viewedGuidesCount == 0) {
    return 0.0;
  }
  return progress.completedGuidesCount / progress.viewedGuidesCount;
});

/// 次に推奨するガイドプロバイダ
final recommendedGuideProvider =
    FutureProvider<MathGuide?>((ref) async {
  final progress = ref.watch(guideProgressProvider);

  // ユーザーがまだ視聴していないガイドを探す
  final allGuides = [
    MathGuide.getGuide(MathConcept.addition, GradeLevel.grade1),
    MathGuide.getGuide(MathConcept.subtraction, GradeLevel.grade2),
    MathGuide.getGuide(MathConcept.multiplication, GradeLevel.grade3),
    MathGuide.getGuide(MathConcept.division, GradeLevel.grade4),
    MathGuide.getGuide(MathConcept.fractions, GradeLevel.grade5),
    MathGuide.getGuide(MathConcept.decimals, GradeLevel.grade5),
    MathGuide.getGuide(MathConcept.geometry, GradeLevel.grade6),
    MathGuide.getGuide(MathConcept.wordProblems, GradeLevel.grade6),
  ];

  for (final guide in allGuides) {
    if (guide != null && !progress.isGuideCompleted(guide.id)) {
      return guide;
    }
  }

  return null;
});
