import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_core/shared_core.dart' show characterStateProvider;
import '../models/quest_model.dart';
import '../models/ranking_model.dart';
import 'package:shared_core/models/badge_model.dart';
import '../providers/progress_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/adaptive_provider.dart';
import '../providers/ghost_provider.dart';
import '../providers/ranking_provider.dart';
import '../providers/retention_notifications_provider.dart';
// Disabled features (see lib/utils/constants.dart DisabledFeatures):
// - Ads: Requires google_mobile_ads integration
// - Premium: Awaiting monetization strategy
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final QuestResult result;
  final Stage stage;

  const ResultScreen({super.key, required this.result, required this.stage});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late ConfettiController _confetti;
  List<BadgeModel> _newBadges = [];
  UserRankingData? _userRanking;
  bool _saving = true;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _saveResult().then((_) {
      if (mounted) {
        setState(() => _saving = false);
        _confetti.play();
      }
    }).catchError((e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存エラー: $e')),
        );
      }
    });
  }

  Future<void> _saveResult() async {
    final r = widget.result;
    final s = widget.stage;

    // 学習進捗を保存
    await ref.read(progressProvider.notifier).recordResult(
      grade: s.grade,
      stageNumber: s.stageNumber,
      correct: r.correctCount,
      total: r.totalCount,
      isPrimary: true,
      isPerfect: r.isPerfect,
    );

    // アダプティブラーニング更新（教育工学機能）
    await ref.read(adaptiveProvider.notifier).recordAnswers(
      topic: s.topicType,
      correct: r.correctCount,
      total: r.totalCount,
    );

    // ランキングスコアを更新
    // 各問題のスコア計算（平均応答時間を使用）
    final avgResponseTime = r.elapsed.inMilliseconds / r.totalCount / 1000;
    final scoreData = QuestionScoreData.calculate(
      questionId: '${s.grade}-${s.stageNumber}',
      isCorrect: r.correctCount > 0,
      responseTimeSeconds: avgResponseTime,
    );
    await ref.read(rankingProvider.notifier).updateScoreAfterQuestion(scoreData);

    final progress = ref.read(progressProvider);

    // キャラクター育成状況（キャラ育成バッジ判定用）
    final characterStates = ref.read(characterStateProvider).values;
    final maxCharacterLevel = characterStates.isEmpty
        ? 0
        : characterStates.map((c) => c.level).reduce((a, b) => a > b ? a : b);
    final charactersAtMaxLevel =
        characterStates.where((c) => c.isMaxLevel).length;

    // バッジチェック
    final newBadges = await ref.read(badgeProvider.notifier).checkAndAward(
      BadgeCheckParams(
        streakDays: progress.streakDays,
        totalPrimaryCorrect: progress.totalPrimaryCorrect,
        totalSecondaryCorrect: progress.totalSecondaryCorrect,
        maxStageCleared: progress.maxStageCleared,
        perfectStageCount: progress.perfectStageCount,
        justPerfect: r.isPerfect,
        maxCharacterLevel: maxCharacterLevel,
        charactersAtMaxLevel: charactersAtMaxLevel,
      ),
    );

    // コイン付与
    if (r.isPassed) {
      final pct = r.correctCount / r.totalCount;
      final coins = pct >= 1.0 ? 30 : pct >= 0.8 ? 20 : 10;
      await ref.read(coinProvider.notifier).addCoins(coins);
    }

    // 親のほめ導線（S-rank機能）
    if (r.isPassed) {
      final profile = ref.read(profileProvider).currentProfile;
      final childName = profile?.name ?? 'お子さん';
      await NotificationService.triggerParentPraise(
        childName: childName,
        achievement: 'ステージ${s.stageNumber}をクリアしました！',
      );
    }

    // セーフティネット：つまずき検出
    final adaptiveState = ref.read(adaptiveProvider);
    if (adaptiveState.parentAlertNeeded) {
      final profile = ref.read(profileProvider).currentProfile;
      final childName = profile?.name ?? 'お子さん';
      final topicName = _topicName(s.topicType);
      await NotificationService.triggerStrugglingAlert(
        childName: childName,
        topicName: topicName,
      );
      ref.read(adaptiveProvider.notifier).clearParentAlert();
    }

    // キャラクター解放チェック（shared_core）
    final totalStages = ref.read(progressProvider).clearedStageIds.length;
    await ref
        .read(characterStateProvider.notifier)
        .checkUnlocks(totalStages);

    // リテンション通知：クエスト完了カウント増加
    if (r.isPassed) {
      await ref.read(retentionNotificationsProvider.notifier)
          .incrementQuestsCompletedSinceReview();
    }

    // ランキングバッジのチェック
    // 更新後に最新ランキング情報を再取得してバッジ判定
    await ref.read(rankingProvider.notifier).fetchCurrentUserRanking();
    final rankingBadges = ref.read(rankingProvider.notifier).checkRankingBadges();
    final currentUserRanking = ref.read(rankingProvider).currentUserRanking;

    // ランキングマイルストーン達成時に通知
    final profile = ref.read(profileProvider).currentProfile;
    if (currentUserRanking != null && profile != null) {
      if (rankingBadges['ranking_top10'] == true) {
        if (kDebugMode) print('🏆 ランキングトップ10達成！');
        await NotificationService.triggerRankingMilestone(
          childName: profile.name,
          rank: currentUserRanking.rank,
          milestone: 'top10',
        );
      } else if (rankingBadges['ranking_top100'] == true) {
        if (kDebugMode) print('🏆 ランキングトップ100達成！');
        await NotificationService.triggerRankingMilestone(
          childName: profile.name,
          rank: currentUserRanking.rank,
          milestone: 'top100',
        );
      }
      if (rankingBadges['weekly_ranking_win'] == true) {
        if (kDebugMode) print('👑 週間チャンピオン達成！');
        await NotificationService.triggerRankingMilestone(
          childName: profile.name,
          rank: 1,
          milestone: 'weekly_win',
        );
      }
    }

    if (mounted) {
      setState(() {
        _newBadges = newBadges;
        _userRanking = currentUserRanking;
        _saving = false;
      });
      if (r.isPassed) _confetti.play();
    }
  }

  String _topicName(MathTopicType t) {
    switch (t) {
      case MathTopicType.addition: return 'たし算';
      case MathTopicType.subtraction: return 'ひき算';
      case MathTopicType.multiplication: return 'かけ算';
      case MathTopicType.division: return 'わり算';
      case MathTopicType.fraction: return '分数';
      case MathTopicType.decimal: return '小数';
      case MathTopicType.geometry: return '図形';
      case MathTopicType.word: return '文章問題';
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final pct = r.correctCount / r.totalCount;
    final color = pct >= 0.8 ? kAccentGreen : pct >= 0.6 ? kAccentOrange : kPrimaryColor;
    final emoji = r.isPerfect ? '🏆' : pct >= 0.8 ? '⭐' : pct >= 0.6 ? '👍' : '📝';
    final message = r.isPerfect
        ? '完璧！天才算数マスター！'
        : pct >= 0.8
            ? 'すばらしい！'
            : pct >= 0.6
                ? 'よくできました！'
                : 'もう一度やってみよう！';

    return Scaffold(
      appBar: AppBar(
        title: const Text('結果'),
        automaticallyImplyLeading: false,
        backgroundColor: kPrimaryColor,
      ),
      body: Stack(
        children: [
          if (!_saving)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 30,
                colors: const [kPrimaryColor, kAccentGreen, kAccentBlue, Colors.orange],
              ),
            ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _saving
                    ? const CircularProgressIndicator(color: kPrimaryColor)
                    : _ScoreDisplay(emoji: emoji, message: message, r: r, color: color),
                const SizedBox(height: 20),
                _StageInfo(stage: widget.stage, elapsed: r.elapsed),
                const SizedBox(height: 16),
                // ゴーストバトル比較セクション
                _GhostComparisonSection(
                  stageId: widget.stage.grade * 100 + widget.stage.stageNumber,
                  currentElapsed: r.elapsed,
                ),
                // ランキング更新情報セクション
                if (_userRanking != null && r.isPassed) ...[
                  const SizedBox(height: 20),
                  _RankingUpdateSection(userRanking: _userRanking!),
                ],
                if (_newBadges.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _NewBadgesSection(badges: _newBadges),
                ],
                // 親のほめ導線メッセージ（UI表示）
                if (!_saving && r.isPassed) ...[
                  const SizedBox(height: 16),
                  _ParentPraiseHint(isPerfect: r.isPerfect),
                  const SizedBox(height: 12),
                  _ShareAchievementButton(result: r, stage: widget.stage),
                  if (_userRanking != null) ...[
                    const SizedBox(height: 12),
                    _ShareRankingButton(userRanking: _userRanking!),
                  ],
                ],
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                          '/stages',
                          (route) => route.settings.name == '/home',
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kPrimaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('ステージ選択'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home',
                          (route) => false,
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('ホームへ'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  final String emoji;
  final String message;
  final QuestResult r;
  final Color color;

  const _ScoreDisplay({required this.emoji, required this.message, required this.r, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ScoreStat(label: 'せいかい', value: '${r.correctCount}', suffix: '/ ${r.totalCount}問', color: color),
              _ScoreStat(label: 'スコア', value: '${r.score}', suffix: '点', color: color),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: r.correctCount / r.totalCount,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreStat extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final Color color;

  const _ScoreStat({required this.label, required this.value, required this.suffix, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: kTextMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(width: 4),
            Text(suffix, style: const TextStyle(fontSize: 14, color: kTextMuted)),
          ],
        ),
      ],
    );
  }
}

class _StageInfo extends StatelessWidget {
  final Stage stage;
  final Duration elapsed;
  const _StageInfo({required this.stage, required this.elapsed});

  @override
  Widget build(BuildContext context) {
    final mins = elapsed.inMinutes;
    final secs = elapsed.inSeconds % 60;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kBgLight, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _InfoItem(label: 'ステージ', value: '${stage.stageNumber}'),
          _InfoItem(label: '学年', value: '小${stage.grade}'),
          _InfoItem(label: 'タイム', value: mins > 0 ? '${mins}分${secs}秒' : '${secs}秒'),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: kTextMuted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

class _NewBadgesSection extends StatelessWidget {
  final List<BadgeModel> badges;
  const _NewBadgesSection({required this.badges});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE082), Color(0xFFFFF9C4)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCC02)),
      ),
      child: Column(
        children: [
          const Text('🎉 新しいバッジをゲット！', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: badges.map((b) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(b.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 4),
                Text(b.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// SNSシェアボタン（設計書A-rank: ほめカードSNSシェア）
class _ShareAchievementButton extends ConsumerWidget {
  final QuestResult result;
  final Stage stage;

  const _ShareAchievementButton({required this.result, required this.stage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _share(context, ref),
      icon: const Icon(Icons.share, size: 18),
      label: const Text('成果をシェア！'),
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimaryColor,
        side: const BorderSide(color: kPrimaryColor),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final profile =
        ref.read(profileProvider).currentProfile;
    final name = profile?.name ?? '小学生';
    final grade = profile?.grade ?? 1;
    final emoji = result.isPerfect ? '🏆' : result.score >= 80 ? '⭐' : '✅';
    final text = '$emoji $name（小${grade}年生）が算数コレ！で\n'
        '「${stage.title}」をクリア！\n'
        '${result.correctCount}/${result.totalCount}問正解 (${result.score}点)\n\n'
        '#算数コレ #小学算数 #算数好きな子と繋がりたい';
    try {
      await Share.share(text);
    } catch (_) {}
  }
}

/// ランキングシェアボタン
class _ShareRankingButton extends ConsumerWidget {
  final UserRankingData userRanking;

  const _ShareRankingButton({required this.userRanking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _shareRanking(context, ref),
      icon: const Icon(Icons.emoji_events, size: 18),
      label: const Text('ランキングをシェア！'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue.shade600,
        side: BorderSide(color: Colors.blue.shade600),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  Future<void> _shareRanking(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider).currentProfile;
    final name = profile?.name ?? '小学生';
    final grade = profile?.grade ?? 1;

    // ランク別のメッセージを生成
    String rankMessage;
    String rankEmoji;
    if (userRanking.rank <= 10) {
      rankMessage = 'トップ10に入賞！スーパースター🌟';
      rankEmoji = '👑';
    } else if (userRanking.rank <= 100) {
      rankMessage = 'トップ100にランクイン！';
      rankEmoji = '🏆';
    } else {
      rankMessage = 'ランキング参加中';
      rankEmoji = '⭐';
    }

    final correctRatePercent = (userRanking.correctRate * 100).toStringAsFixed(1);
    final text = '$rankEmoji $name（小${grade}年生）のランキング成績\n\n'
        '🏅 順位: ${userRanking.rank}位\n'
        '💯 正答率: $correctRatePercent%\n'
        '⚡ 平均速度: ${userRanking.averageSpeed.toStringAsFixed(1)}秒\n'
        '🎯 スコア: ${userRanking.score}点\n\n'
        '$rankMessage\n\n'
        '#算数コレ #ランキング #小学算数 #頑張ってます';

    try {
      await Share.share(text);
    } catch (_) {}
  }
}

// ─── ゴーストバトル比較セクション ───────────────────────────────────────
class _GhostComparisonSection extends ConsumerWidget {
  final int stageId;
  final Duration currentElapsed;

  const _GhostComparisonSection({
    required this.stageId,
    required this.currentElapsed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ghostState = ref.watch(ghostProvider);
    final ghostRecord = ghostState.records[stageId];

    if (ghostRecord == null) {
      // 初回プレイ: ゴーストレコード未存在
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            Text('👻', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ゴーストレコード保存中...',
                    style: TextStyle(
                      fontSize: 13,
                      color: kTextMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '次回プレイで前回の自分と対戦！',
                    style: TextStyle(fontSize: 12, color: kTextMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ゴースト比較表示
    final currentMs = currentElapsed.inMilliseconds;
    final ghostMs = ghostRecord.totalMs;
    final diffMs = ghostMs - currentMs;
    final diffSec = (diffMs.abs() / 1000).toStringAsFixed(1);
    final isNewRecord = diffMs > 0; // 今回が速い

    final currentSec = (currentMs / 1000).toStringAsFixed(1);
    final ghostSec = (ghostMs / 1000).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNewRecord
              ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
              : [const Color(0xFFE3F2FD), const Color(0xFFC5CAE9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNewRecord ? kAccentGreen : kPrimaryColor,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('👻', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ゴースト対戦',
                      style: TextStyle(
                        fontSize: 12,
                        color: kTextMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '前回: ${ghostSec}秒',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: kTextDark,
                          ),
                        ),
                        Text(
                          '今回: ${currentSec}秒',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isNewRecord ? kAccentGreen : kTextDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isNewRecord
                      ? '🔥 ${diffSec}秒高速化！新記録！'
                      : '💨 ${diffSec}秒遅れ（次回の目標）',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isNewRecord ? const Color(0xFF2E7D32) : kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ランキング更新情報セクション
class _RankingUpdateSection extends StatelessWidget {
  final UserRankingData userRanking;

  const _RankingUpdateSection({required this.userRanking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade600.withAlpha(100),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🏆 ランキング更新',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${userRanking.rank}位',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Text(
                    'スコア',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${userRanking.score}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    '正答率',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(userRanking.correctRate * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    '平均速度',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${userRanking.averageSpeed.toStringAsFixed(1)}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 親のほめ導線UIヒント（設計書S-rank）
class _ParentPraiseHint extends StatelessWidget {
  final bool isPerfect;
  const _ParentPraiseHint({required this.isPerfect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAccentGreen.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Text('👨‍👩‍👧', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '保護者の方へ',
                  style: TextStyle(fontSize: 12, color: kTextMuted),
                ),
                Text(
                  isPerfect
                      ? '今すぐ「満点だね！すごい！」と褒めてあげましょう 🎉'
                      : '「よく頑張ったね！」と声をかけてあげましょう',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
