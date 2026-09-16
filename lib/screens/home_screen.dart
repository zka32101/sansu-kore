import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/stage_data.dart';
import '../providers/progress_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/daily_login_provider.dart';
import '../providers/adaptive_provider.dart';
import '../providers/weekly_challenge_provider.dart';
import '../models/quest_model.dart';
import '../screens/daily_bonus_screen.dart';
import '../screens/math_guide_screen.dart';
import '../widgets/furigana_text.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyBonus();
    });
  }

  void _checkDailyBonus() {
    final daily = ref.read(dailyLoginProvider);
    if (daily.showBonusPopup && !daily.todayClaimed) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DailyBonusScreen(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    final badges = ref.watch(badgeProvider);
    final coins = ref.watch(coinProvider);
    final profileState = ref.watch(profileProvider);
    final currentProfile = profileState.currentProfile;
    final adaptive = ref.watch(adaptiveProvider);
    final daily = ref.watch(dailyLoginProvider);
    ref.watch(weeklyChallengeProvider); // ウィークリーチャレンジ初期化

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: kPrimaryColor,
            forceElevated: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor, kPrimaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              centerTitle: true,
              title: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  const Text(
                    '🔴 算数コレ！',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                  ),
                  if (currentProfile != null)
                    Text(
                      '${currentProfile.name} (${currentProfile.grade}年生)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
                ),
              ),
            ),
            actions: [
              // デイリーボーナスボタン
              if (!daily.todayClaimed)
                IconButton(
                  icon: const Stack(
                    children: [
                      Icon(Icons.card_giftcard, color: Colors.white),
                      Positioned(
                        right: 0, top: 0,
                        child: CircleAvatar(
                          radius: 5,
                          backgroundColor: Colors.yellow,
                        ),
                      ),
                    ],
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const DailyBonusScreen(),
                  ),
                ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('📊 誤答分析'),
                    onTap: () => Navigator.pushNamed(context, '/analysis'),
                  ),
                  PopupMenuItem(
                    child: const Text('プロフィール変更'),
                    onTap: () => Navigator.pushReplacementNamed(context, '/profile-selection'),
                  ),
                ],
              ),
            ],
          ),

          // 統計行
          SliverToBoxAdapter(
            child: _StatsRow(
              progress: progress,
              badgeCount: badges.earnedBadges.length,
              coinCount: coins.totalCoins,
            ),
          ),

          // ウィークリーチャレンジカード
          SliverToBoxAdapter(
            child: _WeeklyChallengeCard(),
          ),

          // 算数ガイドセクション
          SliverToBoxAdapter(
            child: _MathGuideSection(
              onTap: () => Navigator.of(context).pushNamed('/math-guide'),
            ),
          ),

          // スペシャルモード（無限とっくん・ゴーストバトル）
          SliverToBoxAdapter(
            child: _SpecialModeSection(
              weakestTopic: adaptive.weakestTopic,
              onInfinite: (topic) => Navigator.of(context)
                  .pushNamed('/infinite-practice', arguments: topic),
              onGhost: () => Navigator.of(context).pushNamed('/stages'),
            ),
          ),

          // AI推奨（アダプティブラーニング）
          if (adaptive.topicAccuracies.isNotEmpty)
            SliverToBoxAdapter(
              child: _AdaptiveRecommendCard(adaptive: adaptive),
            ),

          // クイックスタートボタン
          SliverToBoxAdapter(
            child: _QuickStartCard(
              progress: progress,
              onStart: () {
                final grade = currentProfile?.grade ?? 1;
                for (final stage in getStagesForGrade(grade)) {
                  if (!progress.isCleared(stage.grade, stage.stageNumber)) {
                    Navigator.of(context).pushNamed('/quest', arguments: stage);
                    return;
                  }
                }
                Navigator.of(context).pushNamed('/stages');
              },
            ),
          ),

          // バッジ一覧
          if (badges.earnedBadges.isNotEmpty)
            SliverToBoxAdapter(
              child: _RecentBadgesSection(badges: badges),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final LearningProgress progress;
  final int badgeCount;
  final int coinCount;

  const _StatsRow({
    required this.progress,
    required this.badgeCount,
    required this.coinCount,
  });

  @override
  Widget build(BuildContext context) {
    final totalStages = getAllStages().length;
    final cleared = progress.clearedStageIds.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _StatCard(label: 'れんぞく', value: '${progress.streakDays}日', emoji: '🔥', color: const Color(0xFFE74C3C)),
          const SizedBox(width: 10),
          _StatCard(label: 'コイン', value: '$coinCount枚', emoji: '🪙', color: const Color(0xFFFFB81C)),
          const SizedBox(width: 10),
          _StatCard(label: 'クリア', value: '$cleared/$totalStages', emoji: '🎯', color: kAccentGreen),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: kTextMuted)),
          ],
        ),
      ),
    );
  }
}

class _WeeklyChallengeCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wc = ref.watch(weeklyChallengeProvider);
    final color = const Color(0xFF8E44AD);

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/weekly-challenge'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, const Color(0xFF6C3483)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ウィークリーチャレンジ',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    wc.isAllDone
                        ? '今週のチャレンジ完了！🎉'
                        : '今週の問題 ${wc.completed}/${wc.total} 正解',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: wc.progress,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _AdaptiveRecommendCard extends StatelessWidget {
  final AdaptiveState adaptive;
  const _AdaptiveRecommendCard({required this.adaptive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCC02)),
      ),
      child: Row(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AIおすすめ', style: TextStyle(fontSize: 12, color: kTextMuted)),
                Text(
                  adaptive.weeklyRecommendation,
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

class _QuickStartCard extends StatelessWidget {
  final LearningProgress progress;
  final VoidCallback onStart;

  const _QuickStartCard({required this.progress, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onStart,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimaryColor, kPrimaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withAlpha(80),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('➕', style: TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '今日の算数をはじめよう！',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'クリア済み: ${progress.clearedStageIds.length}ステージ',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentBadgesSection extends StatelessWidget {
  final BadgeState badges;
  const _RecentBadgesSection({required this.badges});

  @override
  Widget build(BuildContext context) {
    final recent = badges.earnedBadges.take(4).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('バッジ', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/badge-collection'),
                child: const Text('すべて見る'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: recent.map((e) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimaryColor.withAlpha(60)),
                  ),
                  child: Column(
                    children: [
                      Text(e.badge.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        e.badge.title,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── スペシャルモードセクション（無限とっくん + ゴーストバトル）─────
class _SpecialModeSection extends StatelessWidget {
  final MathTopicType? weakestTopic;
  final void Function(MathTopicType?) onInfinite;
  final VoidCallback onGhost;

  const _SpecialModeSection({
    required this.weakestTopic,
    required this.onInfinite,
    required this.onGhost,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              '🎮 スペシャル練習',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kTextDark),
            ),
          ),
          Row(
            children: [
              // 無限とっくん
              Expanded(
                child: GestureDetector(
                  onTap: () => onInfinite(weakestTopic),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF43B89C), Color(0xFF2980B9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color:
                                const Color(0xFF43B89C).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('∞', style: TextStyle(fontSize: 28, color: Colors.white)),
                        const SizedBox(height: 6),
                        const Text(
                          '無限とっくん',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          weakestTopic != null
                              ? '苦手を集中練習！'
                              : '問題を無限生成',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ゴーストバトル
              Expanded(
                child: GestureDetector(
                  onTap: onGhost,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8E44AD), Color(0xFFE74C3C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color:
                                const Color(0xFF8E44AD).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('👻', style: TextStyle(fontSize: 28)),
                        SizedBox(height: 6),
                        Text(
                          'ゴーストバトル',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '前回の自分に挑め！',
                          style: TextStyle(
                              fontSize: 10, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 算数ガイドセクション
class _MathGuideSection extends StatelessWidget {
  final VoidCallback onTap;

  const _MathGuideSection({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF667EEA).withValues(alpha: 0.1),
              const Color(0xFF764BA2).withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF667EEA).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // アイコン
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('?', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            // テキスト
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '算数ガイド',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const FuriganaText(
                    '{足|た}し{算|ざん}のやり{方|かた}、かけ{算|ざん}の{仕組|しくみ}みなど',
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            // 矢印
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF667EEA),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
