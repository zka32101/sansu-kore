import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart'
    show FirestoreMatchmakingService, MatchmakingHandlers, MatchHandlers;

import 'firestore_provider.dart';
import 'profile_provider.dart' show profileProvider;

// 算数コレ！のマルチプレイ対戦（レートマッチング）機能。
//
// shared_core の matchmakingProvider / currentMatchProvider は、実データアクセスを
// [matchmakingHandlersProvider] / [matchHandlersProvider] のオーバーライドとして
// アプリ側から注入する設計（friend_provider / ranking_provider と同様）。
//
// ここでは shared_core.FirestoreMatchmakingService をコレクション名だけ
// 「sansu_」プレフィックス付きに変えてそのまま使う。
//
// 注意: 対戦は他プレイヤーとのグローバルなやりとりであり、PR #54/#56 の
// プロフィールベースデータ分離（progress/ranking/friends 等）の対象外。
// マッチメイキングキュー・対戦記録・レーティングは userId（Firebase Auth の uid、
// main.dart で匿名サインイン済み）単位で管理し、プロフィール切り替えでは
// クリアしない。

/// sansu-kore 用の Firestore コレクション名（他アプリと衝突しないようプレフィックス付与）。
final sansuMatchmakingServiceProvider = Provider<FirestoreMatchmakingService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreMatchmakingService(
    firestore: firestore,
    matchmakingQueueCollection: 'sansu_matchmaking_queue',
    matchesCollection: 'sansu_matches',
    playerRatingsCollection: 'sansu_player_ratings',
  );
});

/// main.dart の ProviderScope に注入する override 値。
MatchmakingHandlers buildSansuMatchmakingHandlers(FirebaseFirestore firestore) {
  return FirestoreMatchmakingService(
    firestore: firestore,
    matchmakingQueueCollection: 'sansu_matchmaking_queue',
    matchesCollection: 'sansu_matches',
    playerRatingsCollection: 'sansu_player_ratings',
  ).matchmakingHandlers;
}

MatchHandlers buildSansuMatchHandlers(FirebaseFirestore firestore) {
  return FirestoreMatchmakingService(
    firestore: firestore,
    matchmakingQueueCollection: 'sansu_matchmaking_queue',
    matchesCollection: 'sansu_matches',
    playerRatingsCollection: 'sansu_player_ratings',
  ).matchHandlers;
}

/// 対戦相手探索・対戦成立後のレーティング更新（勝敗反映）に使う。
/// [matchmakingHandlersProvider] / [matchHandlersProvider] は探索・スコア同期用の
/// ハンドラのみを公開しているため、レーティング更新は本サービスから直接呼び出す。
final sansuMatchmakingUpdateRatingProvider = Provider<
    Future<void> Function({
      required String winnerId,
      required String loserId,
      bool isDraw,
    })>((ref) {
  final service = ref.watch(sansuMatchmakingServiceProvider);
  return ({required winnerId, required loserId, bool isDraw = false}) =>
      service.updateRatingAfterMatch(winnerId: winnerId, loserId: loserId, isDraw: isDraw);
});

/// 現在のプロフィールの表示名（対戦相手に表示される名前）。未設定時は「プレイヤー」。
final multiplayerDisplayNameProvider = Provider<String>((ref) {
  final profile = ref.watch(profileProvider).currentProfile;
  final name = profile?.name.trim() ?? '';
  return name.isEmpty ? 'プレイヤー' : name;
});

/// 現在のプロフィールの学年（マッチング時の絞り込みメタデータに使用）。
final multiplayerGradeProvider = Provider<int>((ref) {
  final profile = ref.watch(profileProvider).currentProfile;
  return profile?.grade ?? 1;
});

/// マッチングキューへの参加時に付与する絞り込みメタデータ。
/// 同学年同士のみマッチングさせる（学年が離れすぎると問題の難易度差が大きいため）。
Map<String, dynamic> sansuMatchmakingMetadata(int grade) => {'grade': grade};

/// [MatchmakingQueueEntry.metadata] から学年を取り出す（デフォルト1年）。
int gradeFromMatchmakingMetadata(Map<String, dynamic> metadata) =>
    (metadata['grade'] as num?)?.toInt() ?? 1;
