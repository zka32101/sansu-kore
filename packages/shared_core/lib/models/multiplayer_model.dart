// 小学コレシリーズ共通「マルチプレイ対戦（レートマッチング）」機能の型。
//
// 参考実装: social_quiz_app（社会科クイズアプリ）の
// lib/services/matchmaking_service.dart / lib/services/match_service.dart /
// lib/models/matchmaking_entry.dart / lib/models/player_stats.dart / lib/models/match.dart。
// 現時点で本実装・稼働しているのは social_quiz_app のみだが、Firestoreを使わない
// アプリ（shinshin = FastAPI REST など）にも将来展開できるよう、shared_core側は
// 特定のバックエンドに依存しない型のみを定義する。実データアクセス
// （Firestore/RTDB/REST等）は providers/matchmaking_provider.dart /
// providers/match_provider.dart のハンドラ注入方式でアプリ側に委ねる
// （friend_provider / ranking_provider と同じ設計思想）。

/// マッチングキュー内でのエントリ状態。
enum MatchmakingEntryStatus { waiting, matched, cancelled }

extension MatchmakingEntryStatusJson on MatchmakingEntryStatus {
  String get value => name;

  static MatchmakingEntryStatus fromValue(String? value) {
    switch (value) {
      case 'matched':
        return MatchmakingEntryStatus.matched;
      case 'cancelled':
        return MatchmakingEntryStatus.cancelled;
      case 'waiting':
      default:
        return MatchmakingEntryStatus.waiting;
    }
  }
}

/// 予約済みキー（[MatchmakingQueueEntry.toJson] のトップレベルに書き出す固定フィールド）。
/// これ以外のキーは [MatchmakingQueueEntry.metadata] との相互変換対象になる。
const _kMatchmakingReservedKeys = {
  'userId',
  'displayName',
  'rating',
  'joinedAt',
  'status',
  'matchId',
};

/// マッチングキューの1エントリ（1プレイヤー分）。
///
/// [metadata] には教科（subject）・学年（grade）など、アプリ固有の絞り込み条件を
/// 自由に詰められる。[toJson] ではトップレベルのフィールドとして展開するため、
/// Firestore等でそのままクエリ条件に使える（例: `.where('subject', isEqualTo: ...)`）。
class MatchmakingQueueEntry {
  final String userId;
  final String displayName;
  final double rating;
  final DateTime joinedAt;
  final MatchmakingEntryStatus status;
  final String? matchId;
  final Map<String, dynamic> metadata;

  const MatchmakingQueueEntry({
    required this.userId,
    required this.displayName,
    required this.rating,
    required this.joinedAt,
    this.status = MatchmakingEntryStatus.waiting,
    this.matchId,
    this.metadata = const {},
  });

  bool get isWaiting => status == MatchmakingEntryStatus.waiting;
  bool get isMatched => status == MatchmakingEntryStatus.matched;

  MatchmakingQueueEntry copyWith({
    String? userId,
    String? displayName,
    double? rating,
    DateTime? joinedAt,
    MatchmakingEntryStatus? status,
    String? matchId,
    bool clearMatchId = false,
    Map<String, dynamic>? metadata,
  }) =>
      MatchmakingQueueEntry(
        userId: userId ?? this.userId,
        displayName: displayName ?? this.displayName,
        rating: rating ?? this.rating,
        joinedAt: joinedAt ?? this.joinedAt,
        status: status ?? this.status,
        matchId: clearMatchId ? null : (matchId ?? this.matchId),
        metadata: metadata ?? this.metadata,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'rating': rating,
        'joinedAt': joinedAt.toIso8601String(),
        'status': status.value,
        if (matchId != null) 'matchId': matchId,
        ...metadata,
      };

  factory MatchmakingQueueEntry.fromJson(Map<String, dynamic> json) {
    final metadata = <String, dynamic>{
      for (final entry in json.entries)
        if (!_kMatchmakingReservedKeys.contains(entry.key)) entry.key: entry.value,
    };
    return MatchmakingQueueEntry(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? 'Player',
      rating: (json['rating'] as num?)?.toDouble() ?? 1500.0,
      joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? '') ?? DateTime.now(),
      status: MatchmakingEntryStatusJson.fromValue(json['status'] as String?),
      matchId: json['matchId'] as String?,
      metadata: metadata,
    );
  }

  @override
  String toString() =>
      'MatchmakingQueueEntry(userId: $userId, rating: $rating, status: $status, matchId: $matchId)';
}

/// 対戦（マッチ）の進行状況。
enum MatchStatus { waiting, inProgress, finished }

extension MatchStatusJson on MatchStatus {
  String get value => name;

  static MatchStatus fromValue(String? value) {
    switch (value) {
      case 'finished':
        return MatchStatus.finished;
      case 'inProgress':
        return MatchStatus.inProgress;
      case 'waiting':
      default:
        return MatchStatus.waiting;
    }
  }
}

/// 対戦中に共通して必要となる最小限の状態。
///
/// 問題文・選択肢など教科固有のコンテンツはアプリ側が別途保持する想定で、
/// ここではスコア同期・進行状況・勝敗判定に必要な部分のみを扱う。
class MatchState {
  final String matchId;
  final List<String> playerIds;
  final Map<String, int> scores; // userId -> score
  final MatchStatus status;
  final int currentQuestionIndex;
  final int totalQuestions;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic> metadata;

  const MatchState({
    required this.matchId,
    required this.playerIds,
    this.scores = const {},
    this.status = MatchStatus.waiting,
    this.currentQuestionIndex = 0,
    this.totalQuestions = 10,
    required this.createdAt,
    this.completedAt,
    this.metadata = const {},
  });

  bool get isFinished => status == MatchStatus.finished;
  bool get isInProgress => status == MatchStatus.inProgress;

  int scoreFor(String userId) => scores[userId] ?? 0;

  /// 勝者の userId。引き分けなら 'draw'、まだ終了していない／2人揃っていない場合は null。
  String? get winnerUserId {
    if (!isFinished || playerIds.length < 2) return null;
    final sorted = [...playerIds]..sort((a, b) => scoreFor(b).compareTo(scoreFor(a)));
    final top = sorted.first;
    final second = sorted[1];
    if (scoreFor(top) == scoreFor(second)) return 'draw';
    return top;
  }

  /// [userId] から見た対戦結果。'win' / 'lose' / 'draw' / null（未終了）。
  String? resultFor(String userId) {
    final winner = winnerUserId;
    if (winner == null) return null;
    if (winner == 'draw') return 'draw';
    return winner == userId ? 'win' : 'lose';
  }

  /// 2人対戦を前提に、[userId] から見た相手の userId を返す。見つからなければ null。
  String? opponentOf(String userId) {
    for (final id in playerIds) {
      if (id != userId) return id;
    }
    return null;
  }

  MatchState copyWith({
    String? matchId,
    List<String>? playerIds,
    Map<String, int>? scores,
    MatchStatus? status,
    int? currentQuestionIndex,
    int? totalQuestions,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) =>
      MatchState(
        matchId: matchId ?? this.matchId,
        playerIds: playerIds ?? this.playerIds,
        scores: scores ?? this.scores,
        status: status ?? this.status,
        currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
        totalQuestions: totalQuestions ?? this.totalQuestions,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt ?? this.completedAt,
        metadata: metadata ?? this.metadata,
      );

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'playerIds': playerIds,
        'scores': scores,
        'status': status.value,
        'currentQuestionIndex': currentQuestionIndex,
        'totalQuestions': totalQuestions,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'metadata': metadata,
      };

  factory MatchState.fromJson(Map<String, dynamic> json) => MatchState(
        matchId: json['matchId'] as String,
        playerIds: (json['playerIds'] as List?)?.map((e) => e as String).toList() ?? const [],
        scores: (json['scores'] as Map?)?.map((k, v) => MapEntry(k as String, (v as num).toInt())) ?? const {},
        status: MatchStatusJson.fromValue(json['status'] as String?),
        currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
        totalQuestions: json['totalQuestions'] as int? ?? 10,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'] as String) : null,
        metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

  @override
  String toString() =>
      'MatchState(matchId: $matchId, players: $playerIds, scores: $scores, status: $status)';
}

/// プレイヤー1人分のレーティング・対戦成績。
class PlayerRating {
  final String userId;
  final String displayName;
  final double rating;
  final int wins;
  final int losses;
  final int streak; // 正: 連勝数、負: 連敗数、0: 直近が引き分け／未対戦
  final DateTime? lastMatchAt;

  const PlayerRating({
    required this.userId,
    required this.displayName,
    this.rating = 1500.0,
    this.wins = 0,
    this.losses = 0,
    this.streak = 0,
    this.lastMatchAt,
  });

  int get matchCount => wins + losses;
  double get winRate => matchCount == 0 ? 0 : wins / matchCount;

  PlayerRating copyWith({
    String? userId,
    String? displayName,
    double? rating,
    int? wins,
    int? losses,
    int? streak,
    DateTime? lastMatchAt,
  }) =>
      PlayerRating(
        userId: userId ?? this.userId,
        displayName: displayName ?? this.displayName,
        rating: rating ?? this.rating,
        wins: wins ?? this.wins,
        losses: losses ?? this.losses,
        streak: streak ?? this.streak,
        lastMatchAt: lastMatchAt ?? this.lastMatchAt,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'rating': rating,
        'wins': wins,
        'losses': losses,
        'streak': streak,
        'lastMatchAt': lastMatchAt?.toIso8601String(),
      };

  factory PlayerRating.fromJson(Map<String, dynamic> json) => PlayerRating(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String? ?? 'Player',
        rating: (json['rating'] as num?)?.toDouble() ?? 1500.0,
        wins: json['wins'] as int? ?? 0,
        losses: json['losses'] as int? ?? 0,
        streak: json['streak'] as int? ?? 0,
        lastMatchAt:
            json['lastMatchAt'] != null ? DateTime.tryParse(json['lastMatchAt'] as String) : null,
      );

  factory PlayerRating.initial({required String userId, required String displayName}) =>
      PlayerRating(userId: userId, displayName: displayName);

  @override
  String toString() =>
      'PlayerRating(userId: $userId, rating: $rating, wins: $wins, losses: $losses)';
}
