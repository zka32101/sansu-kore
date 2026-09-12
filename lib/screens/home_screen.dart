import 'package:cross_promo_kit/cross_promo_kit.dart'
    show CrossPromoSection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_core/shared_core.dart'
    show
        equippedItemsProvider,
        kCommonShopItems,
        AppShopItem,
        screenTimeProvider,
        ScreenTimeLimitReachedWidget,
        missionProvider,
        DailyMissionCard,
        DailyMissionPage,
        weeklyBonusProvider,
        coinProvider,
        WeeklyBonusWidget,
        NotificationBadge,
        notificationProvider;

import '../data/math_tips_data.dart';
import '../data/stage_data.dart';
import '../providers/adaptive_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/daily_challenge_provider.dart';
import '../providers/daily_login_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/ranking_provider.dart';
import '../providers/retention_notifications_provider.dart';
import '../providers/weekly_challenge_provider.dart';
// import '../providers/ads_provider.dart';  // TODO: Re-enable once google_mobile_ads conflict is resolved
import '../models/quest_model.dart' as localQuestModel;
import '../models/math_guide_model.dart';
import '../screens/daily_bonus_screen.dart';
import '../screens/math_guide_screen.dart';
import '../screens/math_guide_detail_screen.dart';
import '../screens/ranking_filter_screen.dart';
import '../screens/lesson_screen.dart';
import '../screens/multiplayer/multiplayer_home_screen.dart';
import '../screens/ai_coaching_dashboard_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/daily_challenge_widgets.dart';
import '../widgets/math_guide_widgets.dart';
import '../widgets/ranking_filter_widget.dart';
import 'package:shared_core/shared_core.dart' show FriendsListPage;

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
      _checkRetentionNotifications();
      _initializeDailyChallenge();
      _initializeRanking();
    });
  }

  void _initializeRanking() {
    ref.read(rankingProvider.notifier).fetchGlobalRanking();
  }

  void _initializeDailyChallenge() {
    final profile = ref.read(profileProvider).currentProfile;
    if (profile != null) {
      // Initialize daily challenge
      // ログインボーナス（連続日数・コイン）は dailyLoginProvider が
      // splash_screen.dart の起動時 load() で管理しているため、ここでは
      // デイリーチャレンジの読み込みのみ行う。
      ref.read(dailyChallengeProvider.notifier).loadDailyChallenge();
    }
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

  void _checkRetentionNotifications() {
    final progress = ref.read(progressProvider);
    final profile = ref.read(profileProvider).currentProfile;
    final weeklyChallenge = ref.read(weeklyChallengeProvider);
    final retentionNotif = ref.read(retentionNotificationsProvider.notifier);

    if (profile == null) return;

    // ストリーク維持リマインダー（3日以上のストリーク時）
    if (progress.streakDays >= 3) {
      retentionNotif.checkAndSendStreakReminder(
        currentStreak: progress.streakDays,
        childName: profile.name,
      );
    }

    // ウィークリーチャレンジリマインダー
    retentionNotif.checkAndSendChallengeReminder(
      childName: profile.name,
      challengesCompleted: weeklyChallenge.completed,
      totalChallenges: weeklyChallenge.total,
    );
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

    // 利用時間制限: 1日の上限に達していたら、ホーム画面の代わりに
    // 全画面オーバーレイを表示する（端末・アプリ単位、プロフィール共通）。
    ref.watch(screenTimeProvider); // usedMinutes の変化を監視して再評価
    if (ref.read(screenTimeProvider.notifier).isLimitReached) {
      return const ScreenTimeLimitReachedWidget(primaryColor: kPrimaryColor);
    }

    // ショップで装着中の背景テーマ・プロフィールフレーム（未購入・未装着なら null）
    final equippedIds = ref.watch(equippedItemsProvider).equippedByCategory;
    final equippedTheme = _findShopItem(equippedIds['背景']);
    final equippedFrame = _findShopItem(equippedIds['フレーム']);
    final themeColors = _themeGradientColors(equippedTheme);

    return Scaffold(
      body: Container(
        decoration: themeColors != null
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: themeColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              )
            : null,
        child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (currentProfile != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _ProfileAvatar(
                          initial: currentProfile.name.isNotEmpty
                              ? currentProfile.name.substring(0, 1)
                              : '?',
                          frame: equippedFrame,
                        ),
                      ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      const Text(
                        '🔴 小学コレ！算数',
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
                  ],
                ),
              ),
            ),
            actions: [
              // デイリーミッションボタン（Phase 4.5）
              IconButton(
                icon: const Icon(Icons.assignment, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DailyMissionPage(
                        primaryColor: kPrimaryColor,
                        appTitle: '小学コレ！算数',
                        filterSubject: 'math',
                      ),
                    ),
                  );
                },
                tooltip: 'デイリーミッション',
              ),
              // フレンドボタン（Phase 4.4 フレンド機能）
              IconButton(
                icon: const Icon(Icons.people, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FriendsListPage()),
                  );
                },
                tooltip: 'フレンド',
              ),
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
              // Phase 4.23: ローカル通知・リマインダーシステム
              Builder(
                builder: (context) {
                  final notifications = ref.watch(notificationProvider);
                  return NotificationBadge(
                    notificationCount: notifications.length,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('通知: ${notifications.length}件'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
              ),
              // ランキング・誤答分析・プロフィール変更は「せってい」タブに移動済み
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

          // ログインボーナス表示
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: LoginBonusWidget(),
            ),
          ),

          // Phase 4.20: 週次ボーナスシステム
          SliverToBoxAdapter(
            child: WeeklyBonusWidget(
              onBonusClaimed: (coins) {
                ref.read(coinProvider.notifier).addCoins(coins);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ボーナス $coins コイン獲得しました！🎉'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),

          // デイリーチャレンジカード
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: currentProfile != null
                  ? DailyChallengeCard(userId: currentProfile.id)
                  : const SizedBox.shrink(),
            ),
          ),

          // ウィークリーチャレンジカード
          SliverToBoxAdapter(
            child: _WeeklyChallengeCard(),
          ),

          // デイリーミッション（Phase 4.5 統合）
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: currentProfile != null
                  ? _DailyMissionCardWrapper(userId: currentProfile.id)
                  : const SizedBox.shrink(),
            ),
          ),

          // ランキングセクション
          SliverToBoxAdapter(
            child: _RankingPreviewSection(
              onViewAll: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RankingFilterScreen(),
                  ),
                );
              },
            ),
          ),

          // 算数ガイドセクション
          SliverToBoxAdapter(
            child: _MathGuideSection(
              onGuideSelected: (guide) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MathGuideDetailScreen(guide: guide),
                  ),
                );
              },
            ),
          ),

          // 学ぶ（解説メニュー）への導線
          const SliverToBoxAdapter(
            child: _LessonMenuCard(),
          ),

          // マルチプレイ対戦への導線
          const SliverToBoxAdapter(
            child: _MultiplayerCard(),
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

          // AI コーチング機能
          SliverToBoxAdapter(
            child: _AiCoachingCard(),
          ),

          // クロスプロモーション（他アプリ紹介）
          SliverToBoxAdapter(
            child: CrossPromoSection(
              currentAppId: 'com.example.sansu_kore',
              currentCategory: '小学コレ',
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
          // バナー広告（下部）
          // _BannerAdWidget(),  // TODO: Re-enable once google_mobile_ads conflict is resolved
        ],
        ),
      ),
    );
  }
}

/// ショップで購入したアイテムを [equippedIds] のカテゴリ→id から解決するヘルパー。
AppShopItem? _findShopItem(String? id) {
  if (id == null) return null;
  for (final item in kCommonShopItems) {
    if (item.id == id) return item;
  }
  return null;
}

/// テーマアイテムの themeData から背景グラデーション色を取り出す。
List<Color>? _themeGradientColors(AppShopItem? theme) {
  final colors = theme?.themeData?['colors'];
  if (colors is! List) return null;
  final parsed = <Color>[];
  for (final c in colors) {
    if (c is String && c.startsWith('#')) {
      final hex = c.substring(1);
      final value = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
      if (value != null) parsed.add(Color(value));
    }
  }
  return parsed.length >= 2 ? parsed : null;
}

/// ホーム画面ヘッダーに表示する小さなプロフィールアバター。
/// 装着中のフレーム（[frame]）があれば、そのSVGを縁取りとして重ねる。
class _ProfileAvatar extends StatelessWidget {
  final String initial;
  final AppShopItem? frame;

  const _ProfileAvatar({required this.initial, this.frame});

  @override
  Widget build(BuildContext context) {
    const size = 36.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: size / 2 - 3,
            backgroundColor: Colors.white,
            child: Text(initial,
                style: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          if (frame?.assetPath != null)
            SvgPicture.asset(frame!.assetPath!, width: size, height: size),
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

class _LessonMenuCard extends StatelessWidget {
  const _LessonMenuCard();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF2980B9);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LessonScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [color, Color(0xFF1B4F72)],
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
        child: const Row(
          children: [
            Text('📖', style: TextStyle(fontSize: 32)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('算数を学ぶ',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: 4),
                  Text('計算・図形・割合などのしくみを読んでふくしゅう',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _MultiplayerCard extends StatelessWidget {
  const _MultiplayerCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MultiplayerHomeScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kPrimaryColor, kPrimaryDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: kPrimaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: const Row(
          children: [
            Text('⚔️', style: TextStyle(fontSize: 32)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('みんなと対戦',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: 4),
                  Text('レートマッチングで算数バトル！',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white),
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
  final localQuestModel.MathTopicType? weakestTopic;
  final void Function(localQuestModel.MathTopicType?) onInfinite;
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
class _MathGuideSection extends ConsumerWidget {
  final Function(MathGuide) onGuideSelected;

  const _MathGuideSection({required this.onGuideSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).currentProfile;

    // 現在のグレードレベルを取得
    final gradeLevel = profile != null
        ? _getGradeLevel(profile.grade)
        : GradeLevel.grade1;

    // 現在のグレード向けガイドを取得
    final guides = MathGuide.getGuidesForGrade(gradeLevel);

    if (guides.isEmpty) {
      return const SizedBox.shrink();
    }

    return MathGuideCarousel(
      guides: guides,
      onGuideSelected: onGuideSelected,
    );
  }

  /// ユーザーグレード（1-6）をGradeLevel列挙型に変換
  GradeLevel _getGradeLevel(int grade) {
    switch (grade) {
      case 1:
        return GradeLevel.grade1;
      case 2:
        return GradeLevel.grade2;
      case 3:
        return GradeLevel.grade3;
      case 4:
        return GradeLevel.grade4;
      case 5:
        return GradeLevel.grade5;
      case 6:
        return GradeLevel.grade6;
      default:
        return GradeLevel.grade1;
    }
  }
}

/// ランキングプレビューセクション
class _RankingPreviewSection extends ConsumerWidget {
  final VoidCallback onViewAll;

  const _RankingPreviewSection({required this.onViewAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranking = ref.watch(rankingProvider);
    final filteredRankings = ref.watch(filteredRankingProvider);

    if (ranking.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final topRankings = filteredRankings.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.blue.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '🏆',
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ランキング',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  // 詳細ボタン
                  TextButton(
                    onPressed: onViewAll,
                    child: Text(
                      '詳細を見る →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // トップ5ランキング表示
            if (topRankings.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'ランキングデータを読み込み中...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topRankings.length,
                itemBuilder: (context, index) {
                  final rankingData = topRankings[index];
                  final position = index + 1;
                  final medal = _getMedalEmoji(position);
                  return _buildCompactRankingTile(
                    position: position,
                    medal: medal,
                    name: rankingData.getDisplayName(),
                    score: rankingData.score,
                    grade: rankingData.gradeLevel,
                  );
                },
              ),

            // フッター
            Padding(
              padding: const EdgeInsets.all(12),
              child: CompactRankingFilter(showGrades: false, showMonths: false),
            ),
          ],
        ),
      ),
    );
  }

  String _getMedalEmoji(int position) {
    switch (position) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '${position}️⃣';
    }
  }

  Widget _buildCompactRankingTile({
    required int position,
    required String medal,
    required String name,
    required int score,
    required int grade,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // メダル
          Text(
            medal,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 10),

          // ランク番号
          SizedBox(
            width: 30,
            child: Text(
              '#$position',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),

          // ユーザー情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$grade年生',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // スコア
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$score点',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AI コーチングダッシュボード ナビゲーションカード（Phase 4.24 統合）
class _AiCoachingCard extends ConsumerWidget {
  const _AiCoachingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(profileProvider).currentProfile;
    final userId = currentUser?.userId;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/ai-coaching'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withAlpha(100),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          children: [
            Text('🤖', style: TextStyle(fontSize: 32)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI コーチング',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'あなたの学習パターンを分析して、\nアドバイスをくれます',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// デイリーミッションカードラッパー（Phase 4.5 統合）
class _DailyMissionCardWrapper extends ConsumerWidget {
  final String userId;

  const _DailyMissionCardWrapper({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionState = ref.watch(missionProvider);

    // ミッション読み込み中またはエラー時は表示しない
    if (missionState.isLoading || missionState.missions.isEmpty) {
      return const SizedBox.shrink();
    }

    // 最初のミッションを表示
    final firstMission = missionState.missions.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade300, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📋 今日のミッション',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${(firstMission.progressPercentage).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            firstMission.mission.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: firstMission.progressPercentage / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withAlpha(100),
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.green.shade300,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '報酬: ${firstMission.mission.rewards.fold<int>(0, (sum, reward) => sum + reward.amount)} コイン',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// バナー広告ウィジェット
// TODO: Re-enable once google_mobile_ads conflict is resolved
/*
class _BannerAdWidget extends ConsumerWidget {
  const _BannerAdWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsState = ref.watch(adsProvider);
    final adsNotifier = ref.read(adsProvider.notifier);

    // 広告が有効でない場合は表示しない
    if (!adsState.isInitialized) {
      return const SizedBox.shrink();
    }

    final bannerAd = adsNotifier.getBannerAd();

    if (bannerAd == null) {
      return const SizedBox.shrink();
    }

    // AdWidget は google_mobile_ads パッケージが有効になるまでコメント化
    // TODO: google_mobile_ads 依存が有効化されたら AdWidget(ad: bannerAd) に変更
    return Container(
      alignment: Alignment.center,
      width: bannerAd.size.width.toDouble(),
      height: bannerAd.size.height.toDouble(),
      color: Colors.grey.shade200,
      child: const Center(
        child: Text(
          '【広告】',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
*/
