import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/multiplayer_model.dart';
import '../providers/match_provider.dart';
import '../providers/matchmaking_provider.dart';
import '../utils/rating_calculator.dart';

/// Firestore を使うアプリ向けのデフォルト実装。
///
/// social_quiz_app（現時点で唯一マルチプレイを稼働中のアプリ）の
/// matchmaking_service.dart / match_service.dart のロジックを一般化して移植したもの。
/// kokugo-kore / sansu-kore / newrepo / eigo 等の Firestore 系アプリは、これを
/// そのまま [matchmakingHandlers] / [matchHandlers] としてハンドラ注入するだけで
/// マルチプレイを利用できる。
///
/// Firestore を使わないアプリ（shinshin = FastAPI REST 等）は、この実装は使わず
/// 同じ [MatchmakingHandlers] / [MatchHandlers] インターフェースを満たす独自実装を
/// 用意すればよい（shared_core 側のプロバイダー・Notifier・UI はそのまま使い回せる）。
class FirestoreMatchmakingService {
  final FirebaseFirestore firestore;

  /// コレクション名はアプリごとに変更可能（デフォルトは social_quiz_app と同じ）。
  final String matchmakingQueueCollection;
  final String matchesCollection;
  final String playerRatingsCollection;

  static const double _defaultRatingRange = 300.0;

  FirestoreMatchmakingService({
    FirebaseFirestore? firestore,
    this.matchmakingQueueCollection = 'matchmaking_queue',
    this.matchesCollection = 'matches',
    this.playerRatingsCollection = 'player_ratings',
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _queueRef =>
      firestore.collection(matchmakingQueueCollection);
  CollectionReference<Map<String, dynamic>> get _matchesRef =>
      firestore.collection(matchesCollection);
  CollectionReference<Map<String, dynamic>> get _ratingsRef =>
      firestore.collection(playerRatingsCollection);

  // ── マッチメイキング（キュー操作） ──────────────────────────

  Future<void> joinQueue(MatchmakingQueueEntry entry) async {
    await _queueRef.doc(entry.userId).set(entry.toJson());
  }

  Future<void> leaveQueue(String userId) async {
    await _queueRef.doc(userId).delete();
  }

  /// キュー内で相手を検索（レート ±[ratingRange] の範囲、レートが近い順）。
  /// [metadata] を指定した場合、そのキー・値が一致するエントリのみを対象にする
  /// （例: {'subject': 'social', 'grade': 5}）。
  Future<MatchmakingQueueEntry?> findOpponent({
    required String myUserId,
    required double myRating,
    double ratingRange = _defaultRatingRange,
    Map<String, dynamic> metadata = const {},
  }) async {
    final lower = myRating - ratingRange;
    final upper = myRating + ratingRange;

    Query<Map<String, dynamic>> query = _queueRef
        .where('status', isEqualTo: MatchmakingEntryStatus.waiting.value)
        .where('rating', isGreaterThanOrEqualTo: lower)
        .where('rating', isLessThanOrEqualTo: upper);

    for (final entry in metadata.entries) {
      query = query.where(entry.key, isEqualTo: entry.value);
    }

    final snapshot = await query.orderBy('rating').orderBy('joinedAt').limit(10).get();

    final candidates = snapshot.docs
        .map((d) => MatchmakingQueueEntry.fromJson(d.data()))
        .where((e) => e.userId != myUserId)
        .toList();

    if (candidates.isEmpty) return null;

    candidates.sort(
      (a, b) => (a.rating - myRating).abs().compareTo((b.rating - myRating).abs()),
    );

    return candidates.first;
  }

  /// マッチング確定（Firestoreトランザクションでダブルブッキングを防止）。
  Future<String?> confirmMatch({
    required MatchmakingQueueEntry me,
    required MatchmakingQueueEntry opponent,
  }) async {
    String? matchId;

    await firestore.runTransaction((tx) async {
      final meDoc = await tx.get(_queueRef.doc(me.userId));
      final opponentDoc = await tx.get(_queueRef.doc(opponent.userId));

      if (!meDoc.exists || !opponentDoc.exists) return;

      final meStatus = meDoc.data()?['status'] as String?;
      final opponentStatus = opponentDoc.data()?['status'] as String?;

      if (meStatus != MatchmakingEntryStatus.waiting.value ||
          opponentStatus != MatchmakingEntryStatus.waiting.value) {
        return;
      }

      final matchRef = _matchesRef.doc();
      matchId = matchRef.id;

      final match = MatchState(
        matchId: matchRef.id,
        playerIds: [me.userId, opponent.userId],
        scores: {me.userId: 0, opponent.userId: 0},
        status: MatchStatus.inProgress,
        totalQuestions: 10,
        createdAt: DateTime.now(),
      );

      tx.set(matchRef, match.toJson());

      tx.update(_queueRef.doc(me.userId), {
        'status': MatchmakingEntryStatus.matched.value,
        'matchId': matchRef.id,
      });
      tx.update(_queueRef.doc(opponent.userId), {
        'status': MatchmakingEntryStatus.matched.value,
        'matchId': matchRef.id,
      });
    });

    return matchId;
  }

  /// 自分のキューエントリをリアルタイム監視（マッチング確定を待つ）。
  Stream<MatchmakingQueueEntry?> watchQueueEntry(String userId) {
    return _queueRef
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? MatchmakingQueueEntry.fromJson(doc.data()!) : null);
  }

  // ── プレイヤーレーティング ──────────────────────────────

  Future<PlayerRating> getOrCreatePlayerRating({
    required String userId,
    required String displayName,
  }) async {
    final doc = await _ratingsRef.doc(userId).get();
    if (doc.exists) {
      return PlayerRating.fromJson(doc.data()!);
    }

    final rating = PlayerRating.initial(userId: userId, displayName: displayName);
    await _ratingsRef.doc(userId).set(rating.toJson());
    return rating;
  }

  /// 試合結果でレーティング更新（Elo類似、[RatingCalculator] を使用）。
  Future<void> updateRatingAfterMatch({
    required String winnerId,
    required String loserId,
    bool isDraw = false,
  }) async {
    await firestore.runTransaction((tx) async {
      final winnerDoc = await tx.get(_ratingsRef.doc(winnerId));
      final loserDoc = await tx.get(_ratingsRef.doc(loserId));

      if (!winnerDoc.exists || !loserDoc.exists) return;

      final winnerRating = PlayerRating.fromJson(winnerDoc.data()!);
      final loserRating = PlayerRating.fromJson(loserDoc.data()!);

      final newWinnerRating = RatingCalculator.calcNewRating(
        rating: winnerRating.rating,
        opponentRating: loserRating.rating,
        isWin: true,
        isDraw: isDraw,
      );
      final newLoserRating = RatingCalculator.calcNewRating(
        rating: loserRating.rating,
        opponentRating: winnerRating.rating,
        isWin: false,
        isDraw: isDraw,
      );

      final now = DateTime.now();

      tx.update(_ratingsRef.doc(winnerId), {
        'rating': newWinnerRating,
        'wins': isDraw ? winnerRating.wins : winnerRating.wins + 1,
        'streak': isDraw ? 0 : (winnerRating.streak >= 0 ? winnerRating.streak + 1 : 1),
        'lastMatchAt': now.toIso8601String(),
      });

      tx.update(_ratingsRef.doc(loserId), {
        'rating': newLoserRating,
        'losses': isDraw ? loserRating.losses : loserRating.losses + 1,
        'streak': isDraw ? 0 : (loserRating.streak <= 0 ? loserRating.streak - 1 : -1),
        'lastMatchAt': now.toIso8601String(),
      });
    });
  }

  // ── マッチ状態 ──────────────────────────────────────

  Future<String> createMatch({
    required List<String> playerIds,
    int totalQuestions = 10,
    Map<String, dynamic> metadata = const {},
  }) async {
    final docRef = _matchesRef.doc();
    final match = MatchState(
      matchId: docRef.id,
      playerIds: playerIds,
      scores: {for (final id in playerIds) id: 0},
      status: MatchStatus.inProgress,
      totalQuestions: totalQuestions,
      createdAt: DateTime.now(),
      metadata: metadata,
    );
    await docRef.set(match.toJson());
    return docRef.id;
  }

  Future<MatchState?> getMatch(String matchId) async {
    final doc = await _matchesRef.doc(matchId).get();
    return doc.exists ? MatchState.fromJson(doc.data()!) : null;
  }

  Stream<MatchState?> watchMatch(String matchId) {
    return _matchesRef
        .doc(matchId)
        .snapshots()
        .map((doc) => doc.exists ? MatchState.fromJson(doc.data()!) : null);
  }

  Future<void> updateScore({
    required String matchId,
    required String userId,
    required int score,
  }) async {
    await _matchesRef.doc(matchId).update({'scores.$userId': score});
  }

  Future<void> updateMatchState({
    required String matchId,
    required Map<String, int> scores,
    bool shouldComplete = false,
  }) async {
    final updates = <String, dynamic>{
      'scores': scores,
      if (shouldComplete) ...{
        'status': MatchStatus.finished.value,
        'completedAt': DateTime.now().toIso8601String(),
      },
    };
    await _matchesRef.doc(matchId).update(updates);
  }

  Future<void> completeMatch(String matchId) async {
    await _matchesRef.doc(matchId).update({
      'status': MatchStatus.finished.value,
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<MatchState>> getUserMatches(String userId, {int limit = 20}) async {
    final snapshot = await _matchesRef
        .where('status', isEqualTo: MatchStatus.finished.value)
        .where('playerIds', arrayContains: userId)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => MatchState.fromJson(doc.data())).toList();
  }

  Future<List<MatchState>> getOngoingMatches(String userId) async {
    final snapshot = await _matchesRef
        .where('status', isEqualTo: MatchStatus.inProgress.value)
        .where('playerIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => MatchState.fromJson(doc.data())).toList();
  }

  Future<List<PlayerRating>> getLeaderboard({int limit = 50}) async {
    final snapshot = await _ratingsRef.orderBy('rating', descending: true).limit(limit).get();
    return snapshot.docs.map((doc) => PlayerRating.fromJson(doc.data())).toList();
  }

  // ── ハンドラ束（そのまま ProviderScope の override に渡せる） ─────

  MatchmakingHandlers get matchmakingHandlers => MatchmakingHandlers(
        joinQueue: joinQueue,
        leaveQueue: leaveQueue,
        findOpponent: ({
          required myUserId,
          required myRating,
          required ratingRange,
          metadata = const {},
        }) =>
            findOpponent(
          myUserId: myUserId,
          myRating: myRating,
          ratingRange: ratingRange,
          metadata: metadata,
        ),
        confirmMatch: confirmMatch,
        watchQueueEntry: watchQueueEntry,
        getOrCreatePlayerRating: getOrCreatePlayerRating,
      );

  MatchHandlers get matchHandlers => MatchHandlers(
        createMatch: createMatch,
        getMatch: getMatch,
        watchMatch: watchMatch,
        updateScore: updateScore,
        updateMatchState: updateMatchState,
        completeMatch: completeMatch,
        getUserMatches: getUserMatches,
        getOngoingMatches: getOngoingMatches,
        getLeaderboard: getLeaderboard,
      );
}
