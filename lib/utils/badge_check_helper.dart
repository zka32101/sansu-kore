import 'package:shared_core/shared_core.dart' show BadgeModel, BadgeCategory;
import '../data/badge_data.dart';

/// 算数コレ専用のバッジ判定ロジックを集約したHelper
/// 新規追加バッジの獲得条件を管理
class SansuBadgeCheckHelper {
  /// ストリークバッジ判定
  static List<BadgeModel> checkStreakBadges(int currentStreak) {
    final earned = <BadgeModel>[];

    for (final badge in allSansuBadges) {
      if (badge.category == BadgeCategory.streak &&
          currentStreak >= badge.requiredCount) {
        earned.add(badge);
      }
    }

    return earned;
  }

  /// 正解数バッジ判定
  static List<BadgeModel> checkMathBadges(int correctCount) {
    final earned = <BadgeModel>[];

    for (final badge in allSansuBadges) {
      if ((badge.category == BadgeCategory.content1 ||
           badge.category == BadgeCategory.score) &&
          correctCount >= badge.requiredCount) {
        earned.add(badge);
      }
    }

    return earned;
  }

  /// ステージクリアバッジ判定
  static List<BadgeModel> checkStageBadges(int clearedStageCount, List<String> clearedStageIds) {
    final earned = <BadgeModel>[];

    // ステージ数ベースのバッジ
    for (final badge in allSansuBadges) {
      if (badge.category == BadgeCategory.special &&
          badge.id.startsWith('stage_') &&
          clearedStageCount >= badge.requiredCount) {
        earned.add(badge);
      }
    }

    // 学年完了バッジ（grade_complete_1 など）
    final gradeCompleteBadges = allSansuBadges
        .where((b) => b.id.startsWith('grade_complete_'))
        .toList();

    for (final badge in gradeCompleteBadges) {
      // grade_complete_N の学年数を抽出
      final gradeNum = int.tryParse(badge.id.split('_').last);
      if (gradeNum != null) {
        // 例: grade_complete_1は stageIds 1-13（小1の13ステージ）の完了を確認
        final isComplete = _isGradeComplete(gradeNum, clearedStageIds);
        if (isComplete) {
          earned.add(badge);
        }
      }
    }

    return earned;
  }

  /// ランキングバッジ判定
  static List<BadgeModel> checkRankingBadges(int globalRank, bool isWeeklyRankingWin) {
    final earned = <BadgeModel?>[];

    if (globalRank <= 10) {
      earned.add(_findBadge('ranking_top10'));
    } else if (globalRank <= 100) {
      earned.add(_findBadge('ranking_top100'));
    }

    if (isWeeklyRankingWin) {
      earned.add(_findBadge('weekly_ranking_win'));
    }

    return earned.whereType<BadgeModel>().toList();
  }

  /// キャラクター育成バッジ判定
  static List<BadgeModel> checkCharacterBadges(
    List<int> characterLevels,
    int maxLevelCharCount,
  ) {
    final earned = <BadgeModel?>[];

    // キャラの最高レベルが3以上ならLv3バッジ獲得
    if (characterLevels.any((level) => level >= 3)) {
      earned.add(_findBadge('character_levelup_3'));
    }

    // キャラの最高レベルが5ならLv5バッジ獲得
    if (characterLevels.any((level) => level >= 5)) {
      earned.add(_findBadge('character_levelup_5'));
    }

    // 全キャラがLv5なら全MAX育成バッジ（10体全て）
    if (maxLevelCharCount >= 10) {
      earned.add(_findBadge('character_max_all'));
    }

    return earned.whereType<BadgeModel>().toList();
  }

  /// スピード/効率バッジ判定
  static List<BadgeModel> checkPerformanceBadges(
    int fastClearCount,
    int highAccuracyStreakCount,
  ) {
    final earned = <BadgeModel?>[];

    if (fastClearCount >= 1) {
      earned.add(_findBadge('speed_clear'));
    }

    if (highAccuracyStreakCount >= 10) {
      earned.add(_findBadge('accuracy_90'));
    }

    return earned.whereType<BadgeModel>().toList();
  }

  /// バッジコレクションバッジ判定
  static List<BadgeModel> checkCollectorBadges(int totalBadgeCount) {
    final earned = <BadgeModel?>[];

    if (totalBadgeCount >= 30) {
      earned.add(_findBadge('badge_collector_30'));
    } else if (totalBadgeCount >= 20) {
      earned.add(_findBadge('badge_collector_20'));
    } else if (totalBadgeCount >= 10) {
      earned.add(_findBadge('badge_collector_10'));
    }

    return earned.whereType<BadgeModel>().toList();
  }

  /// ソーシャルバッジ判定
  static List<BadgeModel> checkSocialBadges(
    bool hasSharedScore,
    int invitedFriendsCount,
  ) {
    final earned = <BadgeModel?>[];

    if (hasSharedScore) {
      earned.add(_findBadge('social_share'));
    }

    if (invitedFriendsCount >= 3) {
      earned.add(_findBadge('friend_invite'));
    }

    return earned.whereType<BadgeModel>().toList();
  }

  // ─ Private Helper ─

  /// IDからバッジを検索
  static BadgeModel? _findBadge(String id) {
    try {
      return allSansuBadges.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 学年が完了したかチェック
  /// gradeNum: 1-6
  /// stageIdFormat: "grade1_stage1", "grade1_stage2", ... "grade6_stage13"
  static bool _isGradeComplete(int gradeNum, List<String> clearedStageIds) {
    final gradePrefix = 'grade$gradeNum';
    final gradeStages = clearedStageIds
        .where((id) => id.startsWith(gradePrefix))
        .length;

    // 各学年のステージ数（平均13ステージ想定、実際は要確認）
    const stagesPerGrade = 13;

    return gradeStages >= stagesPerGrade;
  }

  /// 全92ステージ満点完了バッジ
  static BadgeModel? checkPerfectAllBadge(
    List<String> perfectClearedStageIds,
  ) {
    if (perfectClearedStageIds.length >= 92) {
      return _findBadge('stage_perfect_all');
    }
    return null;
  }
}
