import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badge_model.dart';

const _earnedPrefix = 'badge_earned_';

// バッジ判定に使うパラメータ（各アプリが recordResult 後に渡す）
class BadgeCheckParams {
  final int streakDays;
  final int totalPrimaryCorrect;   // content1（漢字/計算 etc）
  final int totalSecondaryCorrect; // content2（読解/文章題 etc）
  final int maxStageCleared;
  final int perfectStageCount;
  final bool justPerfect;
  // キャラクター育成バッジ（BadgeCategory.character）判定用。
  // 未指定のアプリ（キャラ育成機能がない）は既定値0のままでよい。
  final int maxCharacterLevel;   // 全キャラ中の最高レベル
  final int charactersAtMaxLevel; // MAXレベルに到達したキャラ数
  // 学年別クリア済みステージ数と、学年別の全ステージ数。
  // 'grade_complete_N' バッジ判定に使用（学年をまたいだ誤判定を防ぐ）。
  // 未指定のアプリ（学年概念がない）は既定値の空Mapのままでよい。
  final Map<int, int> clearedStagesPerGrade;
  final Map<int, int> totalStagesPerGrade;

  const BadgeCheckParams({
    required this.streakDays,
    required this.totalPrimaryCorrect,
    required this.totalSecondaryCorrect,
    required this.maxStageCleared,
    required this.perfectStageCount,
    required this.justPerfect,
    this.maxCharacterLevel = 0,
    this.charactersAtMaxLevel = 0,
    this.clearedStagesPerGrade = const {},
    this.totalStagesPerGrade = const {},
  });
}

class BadgeState {
  final List<EarnedBadge> earnedBadges;
  final List<BadgeModel> newlyEarned;

  const BadgeState({required this.earnedBadges, required this.newlyEarned});
  static const empty = BadgeState(earnedBadges: [], newlyEarned: []);

  BadgeState copyWith({
    List<EarnedBadge>? earnedBadges,
    List<BadgeModel>? newlyEarned,
  }) =>
      BadgeState(
        earnedBadges: earnedBadges ?? this.earnedBadges,
        newlyEarned: newlyEarned ?? this.newlyEarned,
      );
}

class BadgeNotifier extends Notifier<BadgeState> {
  // 各アプリが定義したバッジ一覧をセット
  List<BadgeModel> _appBadges = [];

  void setBadgeDefinitions(List<BadgeModel> badges) {
    _appBadges = badges;
  }

  @override
  BadgeState build() => BadgeState.empty;

  Future<void> load(List<BadgeModel> badges) async {
    _appBadges = badges;
    final prefs = await SharedPreferences.getInstance();
    final earned = <EarnedBadge>[];
    for (final badge in _appBadges) {
      final dateStr = prefs.getString('$_earnedPrefix${badge.id}');
      if (dateStr != null) {
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          earned.add(EarnedBadge(badge: badge, earnedAt: date));
        }
      }
    }
    state = BadgeState(earnedBadges: earned, newlyEarned: []);
  }

  // BadgeCategory ベースのデータ駆動判定
  Future<List<BadgeModel>> checkAndAward(BadgeCheckParams p) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyEarned = state.earnedBadges.map((e) => e.badge.id).toSet();
    final newBadges = <BadgeModel>[];

    for (final badge in _appBadges) {
      if (alreadyEarned.contains(badge.id)) continue;

      // grade_complete_N は学年ごとの全ステージクリアで判定（学年をまたいだ誤判定防止）
      final gradeCompleteMatch = RegExp(r'^grade_complete_(\d+)$').firstMatch(badge.id);

      final earned = switch (badge.category) {
        BadgeCategory.streak   => p.streakDays >= badge.requiredCount,
        BadgeCategory.score    => p.justPerfect && badge.requiredCount <= 1,
        BadgeCategory.content1 => p.totalPrimaryCorrect >= badge.requiredCount,
        BadgeCategory.content2 => p.totalSecondaryCorrect >= badge.requiredCount,
        BadgeCategory.special when gradeCompleteMatch != null => (() {
            final grade = int.parse(gradeCompleteMatch.group(1)!);
            final total = p.totalStagesPerGrade[grade] ?? 0;
            final cleared = p.clearedStagesPerGrade[grade] ?? 0;
            return total > 0 && cleared >= total;
          })(),
        BadgeCategory.special  => p.maxStageCleared >= badge.requiredCount,
        // 国語コレ専用カテゴリ
        BadgeCategory.kanji    => p.totalPrimaryCorrect >= badge.requiredCount,
        BadgeCategory.reading  => p.totalSecondaryCorrect >= badge.requiredCount,
        BadgeCategory.writing  => p.totalPrimaryCorrect >= badge.requiredCount,
        BadgeCategory.grammar  => p.totalSecondaryCorrect >= badge.requiredCount,
        BadgeCategory.vocab    => p.totalPrimaryCorrect >= badge.requiredCount,
        BadgeCategory.character => badge.id == 'character_max_all'
            ? p.charactersAtMaxLevel >= badge.requiredCount
            : p.maxCharacterLevel >= badge.requiredCount,
      };

      if (earned) {
        final now = DateTime.now();
        await prefs.setString('$_earnedPrefix${badge.id}', now.toIso8601String());
        newBadges.add(badge);
      }
    }

    if (newBadges.isNotEmpty) {
      final nowEarned = [
        ...state.earnedBadges,
        ...newBadges.map((b) => EarnedBadge(badge: b, earnedAt: DateTime.now())),
      ];
      state = state.copyWith(earnedBadges: nowEarned, newlyEarned: newBadges);
    }
    return newBadges;
  }

  void clearNewlyEarned() {
    state = state.copyWith(newlyEarned: []);
  }
}

final badgeProvider = NotifierProvider<BadgeNotifier, BadgeState>(BadgeNotifier.new);
