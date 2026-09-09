import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/multiplayer_model.dart';

// 小学コレシリーズ共通「対戦中のマッチ状態管理」機能。
//
// 実データアクセス（Firestore/REST等）は各アプリ側から [MatchHandlers] として注入する
// （matchmaking_provider.dart / friend_provider.dart と同じ設計思想）。
//
// 参考実装: social_quiz_app の match_service.dart / match_provider.dart。

typedef CreateMatchHandler = Future<String> Function({
  required List<String> playerIds,
  int totalQuestions,
  Map<String, dynamic> metadata,
});
typedef GetMatchHandler = Future<MatchState?> Function(String matchId);
typedef WatchMatchHandler = Stream<MatchState?> Function(String matchId);
typedef UpdateScoreHandler = Future<void> Function({
  required String matchId,
  required String userId,
  required int score,
});
typedef UpdateMatchStateHandler = Future<void> Function({
  required String matchId,
  required Map<String, int> scores,
  bool shouldComplete,
});
typedef CompleteMatchHandler = Future<void> Function(String matchId);
typedef GetUserMatchesHandler = Future<List<MatchState>> Function(String userId, {int limit});
typedef GetOngoingMatchesHandler = Future<List<MatchState>> Function(String userId);
typedef GetLeaderboardHandler = Future<List<PlayerRating>> Function({int limit});

/// 各アプリが [matchHandlersProvider] を override して注入するハンドラ束。
class MatchHandlers {
  final CreateMatchHandler createMatch;
  final GetMatchHandler getMatch;
  final WatchMatchHandler watchMatch;
  final UpdateScoreHandler updateScore;
  final UpdateMatchStateHandler updateMatchState;
  final CompleteMatchHandler completeMatch;
  final GetUserMatchesHandler getUserMatches;
  final GetOngoingMatchesHandler getOngoingMatches;
  final GetLeaderboardHandler getLeaderboard;

  const MatchHandlers({
    required this.createMatch,
    required this.getMatch,
    required this.watchMatch,
    required this.updateScore,
    required this.updateMatchState,
    required this.completeMatch,
    required this.getUserMatches,
    required this.getOngoingMatches,
    required this.getLeaderboard,
  });
}

/// 各アプリがこの provider を override してハンドラを注入する。
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     matchHandlersProvider.overrideWithValue(
///       MatchHandlers(...), // 例: FirestoreMatchmakingService から生成
///     ),
///   ],
///   child: MyApp(),
/// )
/// ```
final matchHandlersProvider = Provider<MatchHandlers>((ref) {
  throw UnimplementedError(
    'matchHandlersProvider must be overridden in each app\'s ProviderScope',
  );
});

/// 現在進行中のマッチ状態の共通ロジック（抽象基底）。
///
/// デフォルトでは [matchHandlersProvider] から注入されたハンドラを使うだけなので、
/// 多くのアプリはこのクラスをサブクラス化せず
/// `matchHandlersProvider.overrideWithValue(...)` するだけでよい。
abstract class BaseMatchNotifier extends Notifier<MatchState?> {
  MatchHandlers get handlers => ref.watch(matchHandlersProvider);

  @override
  MatchState? build() => null;

  /// マッチ開始。
  Future<String> startMatch({
    required List<String> playerIds,
    int totalQuestions = 10,
    Map<String, dynamic> metadata = const {},
  }) {
    return handlers.createMatch(
      playerIds: playerIds,
      totalQuestions: totalQuestions,
      metadata: metadata,
    );
  }

  /// スコア更新（個別）。
  Future<void> updateScore(String matchId, String userId, int score) async {
    try {
      await handlers.updateScore(matchId: matchId, userId: userId, score: score);
    } catch (e) {
      debugPrint('スコア更新エラー: $e');
    }
  }

  /// スコア更新（バッチ）。
  Future<void> updateMatchState({
    required String matchId,
    required Map<String, int> scores,
    bool shouldComplete = false,
  }) async {
    try {
      await handlers.updateMatchState(
        matchId: matchId,
        scores: scores,
        shouldComplete: shouldComplete,
      );
    } catch (e) {
      debugPrint('マッチ状態更新エラー: $e');
    }
  }

  /// マッチ終了。
  Future<void> finishMatch(String matchId) async {
    try {
      await handlers.completeMatch(matchId);
    } catch (e) {
      debugPrint('マッチ終了エラー: $e');
    }
  }

  /// マッチ状態を読み込み、[state] に反映する。
  Future<void> loadMatch(String matchId) async {
    state = await handlers.getMatch(matchId);
  }
}

class _DefaultMatchNotifier extends BaseMatchNotifier {}

final currentMatchProvider =
    NotifierProvider<BaseMatchNotifier, MatchState?>(_DefaultMatchNotifier.new);

/// リアルタイムマッチ監視。
final watchMatchProvider = StreamProvider.family<MatchState?, String>((ref, matchId) {
  final handlers = ref.watch(matchHandlersProvider);
  return handlers.watchMatch(matchId);
});

/// ユーザーのマッチ履歴。
final userMatchHistoryProvider = FutureProvider.family<List<MatchState>, String>((ref, userId) async {
  final handlers = ref.watch(matchHandlersProvider);
  return handlers.getUserMatches(userId);
});

/// 進行中のマッチ取得。
final ongoingMatchesProvider = FutureProvider.family<List<MatchState>, String>((ref, userId) async {
  final handlers = ref.watch(matchHandlersProvider);
  return handlers.getOngoingMatches(userId);
});

/// ランキング（レーティング順リーダーボード）取得。
final leaderboardProvider = FutureProvider<List<PlayerRating>>((ref) async {
  final handlers = ref.watch(matchHandlersProvider);
  return handlers.getLeaderboard();
});
