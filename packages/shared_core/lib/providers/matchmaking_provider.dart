import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/multiplayer_model.dart';

// 小学コレシリーズ共通「マッチメイキング（対戦相手探し）」機能。
//
// 実データアクセス（Firestore/REST等）は各アプリ側から [MatchmakingHandlers] として
// 注入する。shared_core は特定のバックエンドに依存しないため、queue の読み書き・
// 相手探索・マッチ確定処理はすべてコールバックとして外から与えてもらう
// （friend_provider / ranking_provider と同じ「型・共通ロジックは shared_core、
// 実処理はアプリ側」という設計思想）。
//
// 参考実装: social_quiz_app の matchmaking_service.dart / matchmaking_provider.dart。

typedef JoinQueueHandler = Future<void> Function(MatchmakingQueueEntry entry);
typedef LeaveQueueHandler = Future<void> Function(String userId);

/// レート範囲（[ratingRange]）内で相手を探す。見つからなければ null。
typedef FindOpponentHandler = Future<MatchmakingQueueEntry?> Function({
  required String myUserId,
  required double myRating,
  required double ratingRange,
  Map<String, dynamic> metadata,
});

/// 両者がまだ waiting であることを確認しつつマッチを確定する（Firestoreならトランザクション等）。
/// 成立した matchId を返す。どちらかが既にマッチ済み等で確定できなかった場合は null。
typedef ConfirmMatchHandler = Future<String?> Function({
  required MatchmakingQueueEntry me,
  required MatchmakingQueueEntry opponent,
});

/// 自分のキューエントリをリアルタイム監視し、相手からマッチが確定されるのを待つ。
typedef WatchQueueEntryHandler = Stream<MatchmakingQueueEntry?> Function(String userId);

/// プレイヤーのレーティングを取得（なければ初期値で作成）する。
typedef GetOrCreatePlayerRatingHandler = Future<PlayerRating> Function({
  required String userId,
  required String displayName,
});

/// 各アプリが [matchmakingHandlersProvider] を override して注入するハンドラ束。
class MatchmakingHandlers {
  final JoinQueueHandler joinQueue;
  final LeaveQueueHandler leaveQueue;
  final FindOpponentHandler findOpponent;
  final ConfirmMatchHandler confirmMatch;
  final WatchQueueEntryHandler watchQueueEntry;
  final GetOrCreatePlayerRatingHandler getOrCreatePlayerRating;

  const MatchmakingHandlers({
    required this.joinQueue,
    required this.leaveQueue,
    required this.findOpponent,
    required this.confirmMatch,
    required this.watchQueueEntry,
    required this.getOrCreatePlayerRating,
  });
}

/// 各アプリがこの provider を override してハンドラを注入する。
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     matchmakingHandlersProvider.overrideWithValue(
///       MatchmakingHandlers(...), // 例: FirestoreMatchmakingService から生成
///     ),
///   ],
///   child: MyApp(),
/// )
/// ```
final matchmakingHandlersProvider = Provider<MatchmakingHandlers>((ref) {
  throw UnimplementedError(
    'matchmakingHandlersProvider must be overridden in each app\'s ProviderScope',
  );
});

enum MatchmakingStatus { idle, searching, matched, error }

class MatchmakingState {
  final MatchmakingStatus status;
  final String? matchId;
  final MatchmakingQueueEntry? opponentEntry;
  final String? errorMessage;

  const MatchmakingState({
    this.status = MatchmakingStatus.idle,
    this.matchId,
    this.opponentEntry,
    this.errorMessage,
  });

  MatchmakingState copyWith({
    MatchmakingStatus? status,
    String? matchId,
    MatchmakingQueueEntry? opponentEntry,
    String? errorMessage,
    bool clearError = false,
  }) =>
      MatchmakingState(
        status: status ?? this.status,
        matchId: matchId ?? this.matchId,
        opponentEntry: opponentEntry ?? this.opponentEntry,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

/// マッチメイキングの共通ロジック（抽象基底）。
///
/// デフォルトでは [matchmakingHandlersProvider] から注入されたハンドラを使う
/// だけなので、多くのアプリはこのクラスをサブクラス化せず
/// `matchmakingHandlersProvider.overrideWithValue(...)` するだけでよい。
/// レート範囲やタイムアウトを変えたい、あるいは検索ロジック自体をカスタマイズしたい
/// 場合のみサブクラス化して [matchmakingProvider] を override する
/// （character_state_provider の BaseCharacterNotifier と同じ設計哲学）。
abstract class BaseMatchmakingNotifier extends Notifier<MatchmakingState> {
  /// 実データアクセス処理。デフォルトは [matchmakingHandlersProvider] から取得する。
  MatchmakingHandlers get handlers => ref.watch(matchmakingHandlersProvider);

  /// マッチング対象とするレート差の範囲（デフォルト ±300、social_quiz_app と同じ）。
  double get ratingRange => 300.0;

  /// 相手が見つからない場合に再検索を試みるまでのタイムアウト（デフォルト30秒）。
  Duration get searchTimeout => const Duration(seconds: 30);

  StreamSubscription<MatchmakingQueueEntry?>? _queueSub;
  Timer? _searchTimer;

  @override
  MatchmakingState build() {
    ref.onDispose(() {
      _searchTimer?.cancel();
      _queueSub?.cancel();
    });
    return const MatchmakingState();
  }

  /// マッチング開始。
  Future<void> startSearching({
    required String userId,
    required String displayName,
    required double rating,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (state.status == MatchmakingStatus.searching) return;

    state = state.copyWith(status: MatchmakingStatus.searching, clearError: true);

    try {
      await handlers.joinQueue(MatchmakingQueueEntry(
        userId: userId,
        displayName: displayName,
        rating: rating,
        joinedAt: DateTime.now(),
        metadata: metadata,
      ));

      final opponent = await handlers.findOpponent(
        myUserId: userId,
        myRating: rating,
        ratingRange: ratingRange,
        metadata: metadata,
      );

      if (opponent != null) {
        final matched = await _tryConfirmMatch(
          userId: userId,
          displayName: displayName,
          rating: rating,
          metadata: metadata,
          opponent: opponent,
        );
        if (matched) return;
      }

      // 相手が見つからなければ、相手からのマッチング確定を待つ
      _listenForMatch(userId);

      // タイムアウトで再検索、それでも見つからなければエラーにする
      _searchTimer = Timer(searchTimeout, () async {
        if (state.status != MatchmakingStatus.searching) return;

        final widerOpponent = await handlers.findOpponent(
          myUserId: userId,
          myRating: rating,
          ratingRange: ratingRange,
          metadata: metadata,
        );

        if (widerOpponent != null) {
          final matched = await _tryConfirmMatch(
            userId: userId,
            displayName: displayName,
            rating: rating,
            metadata: metadata,
            opponent: widerOpponent,
          );
          if (matched) return;
        }

        state = state.copyWith(
          status: MatchmakingStatus.error,
          errorMessage: '対戦相手が見つかりませんでした。もう一度お試しください。',
        );
        await handlers.leaveQueue(userId);
      });
    } catch (e) {
      state = state.copyWith(
        status: MatchmakingStatus.error,
        errorMessage: 'マッチング中にエラーが発生しました: $e',
      );
    }
  }

  Future<bool> _tryConfirmMatch({
    required String userId,
    required String displayName,
    required double rating,
    required Map<String, dynamic> metadata,
    required MatchmakingQueueEntry opponent,
  }) async {
    final myEntry = MatchmakingQueueEntry(
      userId: userId,
      displayName: displayName,
      rating: rating,
      joinedAt: DateTime.now(),
      metadata: metadata,
    );

    final matchId = await handlers.confirmMatch(me: myEntry, opponent: opponent);
    if (matchId == null) return false;

    _searchTimer?.cancel();
    state = state.copyWith(
      status: MatchmakingStatus.matched,
      matchId: matchId,
      opponentEntry: opponent,
    );
    return true;
  }

  /// 自分のキューエントリを監視して、相手から確定されたマッチを検知する。
  void _listenForMatch(String userId) {
    _queueSub?.cancel();
    _queueSub = handlers.watchQueueEntry(userId).listen((entry) {
      if (entry == null) return;
      if (entry.isMatched && entry.matchId != null) {
        _searchTimer?.cancel();
        state = state.copyWith(status: MatchmakingStatus.matched, matchId: entry.matchId);
      }
    });
  }

  /// マッチングキャンセル。
  Future<void> cancelSearch(String userId) async {
    _searchTimer?.cancel();
    _queueSub?.cancel();
    await handlers.leaveQueue(userId);
    state = const MatchmakingState();
  }

  /// 状態をリセット（Firestore等のキューには触らない）。
  void reset() {
    _searchTimer?.cancel();
    _queueSub?.cancel();
    state = const MatchmakingState();
  }
}

class _DefaultMatchmakingNotifier extends BaseMatchmakingNotifier {}

final matchmakingProvider =
    NotifierProvider<BaseMatchmakingNotifier, MatchmakingState>(_DefaultMatchmakingNotifier.new);

/// プレイヤーのレーティングを取得（なければ初期値で作成）する。
final playerRatingProvider =
    FutureProvider.family<PlayerRating, ({String userId, String displayName})>((ref, args) async {
  final handlers = ref.watch(matchmakingHandlersProvider);
  return handlers.getOrCreatePlayerRating(userId: args.userId, displayName: args.displayName);
});
