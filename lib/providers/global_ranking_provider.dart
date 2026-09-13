import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/models/global_ranking_model.dart';

/// グローバルランキング提供者
final globalRankingProvider = FutureProvider<List<GlobalRanking>>((ref) async {
  // Firestore からランキングデータ取得（実装予定）
  return [
    GlobalRanking(
      rank: 1,
      userId: 'user_001',
      userName: 'Tanaka Taro',
      score: 9850,
      badges: 45,
    ),
    GlobalRanking(
      rank: 2,
      userId: 'user_002',
      userName: 'Suzuki Hanako',
      score: 9420,
      badges: 42,
    ),
    GlobalRanking(
      rank: 3,
      userId: 'user_003',
      userName: 'Yamada Jiro',
      score: 9100,
      badges: 40,
    ),
  ];
});

/// ユーザーの現在ランク取得
final userRankProvider = FutureProvider<int>((ref) async {
  // 現在のユーザーランク取得（実装予定）
  return 15;
});
