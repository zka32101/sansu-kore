import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart'
    show PlayerRatingCard, MatchHistoryTile, playerRatingProvider, userMatchHistoryProvider;

import '../../providers/multiplayer_provider.dart';
import '../../theme/app_theme.dart';
import 'leaderboard_screen.dart';
import 'matchmaking_waiting_screen.dart';
class MultiplayerHomeScreen extends ConsumerWidget {
  const MultiplayerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('対戦')),
        body: const Center(child: Text('ログイン処理中です。しばらくしてからもう一度お試しください。')),
      );
    }

    final displayName = ref.watch(multiplayerDisplayNameProvider);
    final grade = ref.watch(multiplayerGradeProvider);
    final ratingAsync = ref.watch(
      playerRatingProvider((userId: userId, displayName: displayName)),
    );

    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        title: const Text('対戦'),
        elevation: 0,
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'ランキング',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => LeaderboardScreen(currentUserId: userId)),
            ),
          ),
        ],
      ),
      body: ratingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラーが発生しました: $e')),
        data: (rating) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlayerRatingCard(
                rating: rating,
                avatar: const Text('🧮', style: TextStyle(fontSize: 32)),
                gradientStart: kPrimaryColor,
                gradientEnd: kPrimaryDeep,
              ),
              const SizedBox(height: 24),
              _buildMatchHistory(ref, userId),
              const SizedBox(height: 24),
              _buildQuickMatchButton(context, userId, displayName, rating.rating, grade),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchHistory(WidgetRef ref, String userId) {
    final historyAsync = ref.watch(userMatchHistoryProvider(userId));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Text('対戦履歴の取得に失敗しました: $e', style: const TextStyle(color: Colors.grey)),
      data: (matches) {
        if (matches.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.sports_score, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('まだ対戦がありません', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('最近の対戦', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${matches.length}戦', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            ...matches.take(5).map((m) => MatchHistoryTile(match: m, userId: userId)),
          ],
        );
      },
    );
  }

  Widget _buildQuickMatchButton(
    BuildContext context,
    String userId,
    String displayName,
    double rating,
    int grade,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.search),
        label: const Text('クイックマッチ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MatchmakingWaitingScreen(
              userId: userId,
              displayName: displayName,
              rating: rating,
              grade: grade,
            ),
          ),
        ),
      ),
    );
  }
}
