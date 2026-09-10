import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ranking_filter_model.dart';
import '../models/ranking_model.dart';
import 'friends_provider.dart';
import 'profile_provider.dart';
class RankingState {
  final List<UserRankingData> globalRanking;
  final List<UserRankingData> weeklyRanking;
  final List<UserRankingData> monthlyRanking;
  final List<UserRankingData> friendsRanking;
  final UserRankingData? currentUserRanking;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdatedAt;

  RankingState({
    this.globalRanking = const [],
    this.weeklyRanking = const [],
    this.monthlyRanking = const [],
    this.friendsRanking = const [],
    this.currentUserRanking,
    this.isLoading = false,
    this.error,
    DateTime? lastUpdatedAt,
  }) : lastUpdatedAt = lastUpdatedAt ?? DateTime.utc(1970, 1, 1);

  RankingState copyWith({
    List<UserRankingData>? globalRanking,
    List<UserRankingData>? weeklyRanking,
    List<UserRankingData>? monthlyRanking,
    List<UserRankingData>? friendsRanking,
    UserRankingData? currentUserRanking,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
  }) {
    return RankingState(
      globalRanking: globalRanking ?? this.globalRanking,
      weeklyRanking: weeklyRanking ?? this.weeklyRanking,
      monthlyRanking: monthlyRanking ?? this.monthlyRanking,
      friendsRanking: friendsRanking ?? this.friendsRanking,
      currentUserRanking: currentUserRanking ?? this.currentUserRanking,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

/// ランキング管理ロジック
class RankingNotifier extends StateNotifier<RankingState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Ref _ref;

  RankingNotifier(this._firestore, this._auth, this._ref)
      : super(RankingState());

  /// グローバルランキングを取得（全ユーザーの上位100位まで）
  Future<void> fetchGlobalRanking() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final snapshot = await _firestore
          .collection('rankings')
          .doc('global')
          .collection('users')
          .orderBy('score', descending: true)
          .limit(100)
          .get();

      final ranking = snapshot.docs
          .asMap()
          .entries
          .map((entry) {
            final doc = entry.value;
            final data = UserRankingData.fromFirestore(doc);
            return data.copyWith(rank: entry.key + 1);
          })
          .toList();

      state = state.copyWith(
        globalRanking: ranking,
        lastUpdatedAt: DateTime.now(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'グローバルランキングの取得に失敗しました: $e',
        isLoading: false,
      );
    }
  }

  /// 週間ランキングを取得
  Future<void> fetchWeeklyRanking() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final snapshot = await _firestore
          .collection('rankings')
          .doc('weekly')
          .collection('users')
          .orderBy('weeklyScore', descending: true)
          .limit(100)
          .get();

      final ranking = snapshot.docs
          .asMap()
          .entries
          .map((entry) {
            final doc = entry.value;
            final data = UserRankingData.fromFirestore(doc);
            return data.copyWith(rank: entry.key + 1);
          })
          .toList();

      state = state.copyWith(
        weeklyRanking: ranking,
        lastUpdatedAt: DateTime.now(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: '週間ランキングの取得に失敗しました: $e',
        isLoading: false,
      );
    }
  }

  /// 月間ランキングを取得
  Future<void> fetchMonthlyRanking() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final snapshot = await _firestore
          .collection('rankings')
          .doc('monthly')
          .collection('users')
          .orderBy('monthlyScore', descending: true)
          .limit(100)
          .get();

      final ranking = snapshot.docs
          .asMap()
          .entries
          .map((entry) {
            final doc = entry.value;
            final data = UserRankingData.fromFirestore(doc);
            return data.copyWith(rank: entry.key + 1);
          })
          .toList();

      state = state.copyWith(
        monthlyRanking: ranking,
        lastUpdatedAt: DateTime.now(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: '月間ランキングの取得に失敗しました: $e',
        isLoading: false,
      );
    }
  }

  /// フレンドランキングを取得
  Future<void> fetchFriendsRanking() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        state = state.copyWith(
          error: 'ユーザーがログインしていません',
          isLoading: false,
        );
        return;
      }

      // フレンドリストを取得（friendsProvider と連携）
      final friendIds = _ref.read(friendIdsProvider);

      if (friendIds.isEmpty) {
        state = state.copyWith(
          friendsRanking: const [],
          isLoading: false,
        );
        return;
      }

      final snapshot = await _firestore
          .collection('rankings')
          .doc('global')
          .collection('users')
          .where('userId', whereIn: friendIds)
          .orderBy('score', descending: true)
          .get();

      final ranking = snapshot.docs
          .asMap()
          .entries
          .map((entry) {
            final doc = entry.value;
            final data = UserRankingData.fromFirestore(doc);
            return data.copyWith(rank: entry.key + 1);
          })
          .toList();

      state = state.copyWith(
        friendsRanking: ranking,
        lastUpdatedAt: DateTime.now(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'フレンドランキングの取得に失敗しました: $e',
        isLoading: false,
      );
    }
  }

  /// 現在のユーザーのランキング情報を取得
  Future<void> fetchCurrentUserRanking() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // グローバルランキングから現在のユーザーを検索
      final globalDoc = await _firestore
          .collection('rankings')
          .doc('global')
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (globalDoc.exists) {
        final data = UserRankingData.fromFirestore(globalDoc);
        state = state.copyWith(currentUserRanking: data);
      }
    } catch (e) {
      // ユーザーがまだランキングにない可能性がある
      if (kDebugMode) print('Error fetching current user ranking: $e');
    }
  }

  /// 問題回答後にスコアを更新
  Future<void> updateScoreAfterQuestion(QuestionScoreData scoreData) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final profile = _ref.read(profileProvider);
      if (profile == null) return;

      // グローバルランキングを更新
      await _updateUserScore(
        category: 'global',
        userId: currentUser.uid,
        scorePoints: scoreData.totalScore,
      );

      // 週間・月間ランキングも更新
      await _updateUserScore(
        category: 'weekly',
        userId: currentUser.uid,
        scorePoints: scoreData.totalScore,
      );

      await _updateUserScore(
        category: 'monthly',
        userId: currentUser.uid,
        scorePoints: scoreData.totalScore,
      );

      // 現在のユーザー情報を再取得
      await fetchCurrentUserRanking();
    } catch (e) {
      if (kDebugMode) print('Error updating score: $e');
    }
  }

  /// Firestore のスコア更新処理（内部関数）
  Future<void> _updateUserScore({
    required String category,
    required String userId,
    required int scorePoints,
  }) async {
    final batch = _firestore.batch();

    final userDocRef = _firestore
        .collection('rankings')
        .doc(category)
        .collection('users')
        .doc(userId);

    batch.update(
      userDocRef,
      {
        'score': FieldValue.increment(scorePoints),
        if (category == 'weekly') 'weeklyScore': FieldValue.increment(scorePoints),
        if (category == 'monthly')
          'monthlyScore': FieldValue.increment(scorePoints),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  /// ランキングバッジの取得状況をチェック
  /// ユーザーのランク情報からバッジ受取可能かを判定
  Map<String, bool> checkRankingBadges() {
    final userRanking = state.currentUserRanking;
    if (userRanking == null) {
      return {
        'ranking_top100': false,
        'ranking_top10': false,
        'weekly_ranking_win': false,
      };
    }

    return {
      'ranking_top100': userRanking.rank <= 100,
      'ranking_top10': userRanking.rank <= 10,
      'weekly_ranking_win': userRanking.rank == 1,
    };
  }

  /// 初回ランキングデータを初期化（新規ユーザー用）
  Future<void> initializeUserRanking({
    required String userId,
    required String userName,
    String? avatarUrl,
    int gradeLevel = 1,
  }) async {
    try {
      final now = DateTime.now();
      final data = {
        'userName': 'ユーザー',
        'avatarUrl': '',
        'score': 0,
        'rank': 0,
        'totalQuestionsAnswered': 0,
        'correctRate': 0.0,
        'averageSpeed': 0.0,
        'weeklyScore': 0,
        'monthlyScore': 0,
        'isNamePublic': false, // デフォルトはプライベート
        'gradeLevel': gradeLevel,
        'startDate': FieldValue.serverTimestamp(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };

      final batch = _firestore.batch();

      // グローバル
      batch.set(
        _firestore
            .collection('rankings')
            .doc('global')
            .collection('users')
            .doc(userId),
        data,
        SetOptions(merge: true),
      );

      // 週間
      batch.set(
        _firestore
            .collection('rankings')
            .doc('weekly')
            .collection('users')
            .doc(userId),
        data,
        SetOptions(merge: true),
      );

      // 月間
      batch.set(
        _firestore
            .collection('rankings')
            .doc('monthly')
            .collection('users')
            .doc(userId),
        data,
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      if (kDebugMode) print('Error initializing user ranking: $e');
    }
  }

  /// ユーザーのランキング公開設定を更新
  /// isNamePublic: true = 名前を公開、false = 匿名
  Future<void> updateNamePublicSetting(bool isPublic) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // ユーザープロフィールを更新
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'profile.isNamePublic': isPublic,
          });

      // ランキング各種を更新
      final batch = _firestore.batch();

      for (final category in ['global', 'weekly', 'monthly']) {
        batch.update(
          _firestore
              .collection('rankings')
              .doc(category)
              .collection('users')
              .doc(currentUser.uid),
          {'isNamePublic': isPublic},
        );
      }

      await batch.commit();

      // ローカル状態を更新
      if (state.currentUserRanking != null) {
        state = state.copyWith(
          currentUserRanking: state.currentUserRanking!.copyWith(isNamePublic: isPublic),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error updating name public setting: $e');
    }
  }

  /// 全ランキングをリアルタイムで監視
  Stream<RankingState> streamAllRankings() {
    return Stream.fromFutures([
      Future(() async {
        await fetchGlobalRanking();
        await fetchWeeklyRanking();
        await fetchMonthlyRanking();
        await fetchCurrentUserRanking();
        return state;
      }),
    ]);
  }

  /// フィルタ条件に基づいてランキングをフィルタリング
  List<UserRankingData> getFilteredRanking(RankingFilter filter) {
    final rankings = state.globalRanking;
    return RankingFilterService.filterRankings(rankings, filter);
  }

  /// 利用可能な学年リストを取得
  List<int> getAvailableGrades() {
    return RankingFilterService.getAvailableGrades(state.globalRanking);
  }

  /// 利用可能な開始月リストを取得
  List<DateTime> getAvailableStartMonths() {
    return RankingFilterService.getAvailableStartMonths(state.globalRanking);
  }
}

/// ランキング Provider（Riverpod）
final rankingProvider = StateNotifierProvider<RankingNotifier, RankingState>(
  (ref) {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    return RankingNotifier(firestore, auth, ref);
  },
);

/// ランキングフィルタの状態管理
class RankingFilterNotifier extends StateNotifier<RankingFilter> {
  RankingFilterNotifier()
      : super(const RankingFilter(groupOption: RankingGroupOption.global));

  /// フィルタを更新
  void updateFilter(RankingFilter filter) {
    state = filter;
  }

  /// グループ化オプションを変更
  void setGroupOption(RankingGroupOption option) {
    state = RankingFilter(
      groupOption: option,
      selectedGrade: option == RankingGroupOption.grade ||
              option == RankingGroupOption.combined
          ? state.selectedGrade
          : null,
      selectedMonth: option == RankingGroupOption.startMonth ||
              option == RankingGroupOption.combined
          ? state.selectedMonth
          : null,
    );
  }

  /// 学年を選択
  void selectGrade(int grade) {
    state = state.copyWith(selectedGrade: grade);
  }

  /// 開始月を選択
  void selectStartMonth(DateTime month) {
    state = state.copyWith(selectedMonth: month);
  }

  /// フィルタをリセット
  void resetFilter() {
    state = const RankingFilter(groupOption: RankingGroupOption.global);
  }
}

/// ランキングフィルタ Provider
final rankingFilterProvider =
    StateNotifierProvider<RankingFilterNotifier, RankingFilter>(
  (ref) => RankingFilterNotifier(),
);

/// フィルタされたランキングを取得するプロバイダ
final filteredRankingProvider =
    Provider<List<UserRankingData>>((ref) {
  final ranking = ref.watch(rankingProvider);
  final filter = ref.watch(rankingFilterProvider);
  final notifier = ref.read(rankingProvider.notifier);
  return notifier.getFilteredRanking(filter);
});

/// 利用可能な学年リストを取得するプロバイダ
final availableGradesProvider = Provider<List<int>>((ref) {
  final ranking = ref.watch(rankingProvider);
  final notifier = ref.read(rankingProvider.notifier);
  return notifier.getAvailableGrades();
});

/// 利用可能な開始月リストを取得するプロバイダ
final availableStartMonthsProvider = Provider<List<DateTime>>((ref) {
  final ranking = ref.watch(rankingProvider);
  final notifier = ref.read(rankingProvider.notifier);
  return notifier.getAvailableStartMonths();
});
