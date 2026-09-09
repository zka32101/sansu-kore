import 'dart:math' as math;

/// マルチプレイ対戦のレーティング計算（Elo類似）。
///
/// Firestore/REST等バックエンドを問わない純粋関数として提供する。
/// 参考実装: social_quiz_app の `PlayerStats.calcNewRating`。
class RatingCalculator {
  const RatingCalculator._();

  static const double defaultK = 32.0;
  static const double minRating = 100.0;
  static const double maxRating = 3000.0;

  /// [rating] のプレイヤーが [opponentRating] の相手に勝つ期待勝率（0.0〜1.0）。
  static double expectedScore({
    required double rating,
    required double opponentRating,
  }) {
    return 1.0 / (1.0 + math.pow(10, (opponentRating - rating) / 400));
  }

  /// 対戦結果を反映した新しいレーティングを計算する。
  ///
  /// [isDraw] が true の場合は [isWin] を無視し、期待勝率0.5を実際の結果として扱う。
  static double calcNewRating({
    required double rating,
    required double opponentRating,
    required bool isWin,
    bool isDraw = false,
    double k = defaultK,
  }) {
    final expected = expectedScore(rating: rating, opponentRating: opponentRating);
    final actual = isDraw ? 0.5 : (isWin ? 1.0 : 0.0);
    return (rating + k * (actual - expected)).clamp(minRating, maxRating);
  }

  /// 2人分のレーティングをまとめて計算するヘルパー。
  /// 戻り値は (player1の新レーティング, player2の新レーティング)。
  static (double, double) calcNewRatingsForMatch({
    required double player1Rating,
    required double player2Rating,
    required bool player1Wins,
    bool isDraw = false,
    double k = defaultK,
  }) {
    final newP1 = calcNewRating(
      rating: player1Rating,
      opponentRating: player2Rating,
      isWin: player1Wins,
      isDraw: isDraw,
      k: k,
    );
    final newP2 = calcNewRating(
      rating: player2Rating,
      opponentRating: player1Rating,
      isWin: !player1Wins,
      isDraw: isDraw,
      k: k,
    );
    return (newP1, newP2);
  }
}
