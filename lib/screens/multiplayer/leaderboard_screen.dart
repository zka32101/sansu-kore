import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart' show LeaderboardView, leaderboardProvider;

import '../../theme/app_theme.dart';

/// マルチプレイ対戦のランキング（リーダーボード）画面。
class LeaderboardScreen extends ConsumerWidget {
  final String? currentUserId;

  const LeaderboardScreen({super.key, this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        title: const Text('対戦ランキング'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('ランキングの取得に失敗しました: $e')),
        data: (ratings) => LeaderboardView(
          ratings: ratings,
          currentUserId: currentUserId,
          accentColor: kPrimaryColor,
        ),
      ),
    );
  }
}
