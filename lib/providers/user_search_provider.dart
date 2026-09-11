import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_search_model.dart';

/// ユーザー検索管理ロジック
class UserSearchNotifier extends StateNotifier<UserSearchState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserSearchNotifier(this._firestore, this._auth)
      : super(UserSearchState());

  /// ユーザーをID/名前で検索
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: const [], isSearching: false);
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null, isSearching: true);

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        state = state.copyWith(
          error: 'ユーザーがログインしていません',
          isLoading: false,
        );
        return;
      }

      List<SearchUserData> results = [];

      // 1. ランキングコレクションから検索（スコアが高い順）
      try {
        final rankingSnapshot = await _firestore
            .collection('rankings')
            .doc('global')
            .collection('users')
            .orderBy('score', descending: true)
            .limit(100)
            .get();

        results = rankingSnapshot.docs
            .map((doc) {
              try {
                return SearchUserData.fromRankingDoc(doc);
              } catch (e) {
                if (kDebugMode) print('Error parsing ranking doc: $e');
                return null;
              }
            })
            .whereType<SearchUserData>()
            .toList();
      } catch (e) {
        if (kDebugMode) print('Error querying rankings: $e');
      }

      // 2. users コレクションから検索（名前マッチ）
      if (results.isEmpty || query.length > 2) {
        try {
          final usersSnapshot = await _firestore
              .collection('users')
              .where('profile.name', isGreaterThanOrEqualTo: query)
              .where('profile.name', isLessThan: query + 'z')
              .limit(50)
              .get();

          results.addAll(
            usersSnapshot.docs
                .map((doc) {
                  try {
                    return SearchUserData.fromFirestore(doc);
                  } catch (e) {
                    if (kDebugMode) print('Error parsing user doc: $e');
                    return null;
                  }
                })
                .whereType<SearchUserData>()
                .toList(),
          );
        } catch (e) {
          if (kDebugMode) print('Error querying users: $e');
        }
      }

      // 3. ID で直接検索
      if (query.length > 3) {
        try {
          final userDoc = await _firestore.collection('users').doc(query).get();
          if (userDoc.exists) {
            try {
              final searchUser = SearchUserData.fromFirestore(userDoc);
              // 重複排除
              if (!results.any((u) => u.uid == searchUser.uid)) {
                results.insert(0, searchUser);
              }
            } catch (e) {
              if (kDebugMode) print('Error parsing direct search doc: $e');
            }
          }
        } catch (e) {
          if (kDebugMode) print('Error direct search: $e');
        }
      }

      // 4. 現在のユーザーをフィルタリング
      results.removeWhere((u) => u.uid == currentUser.uid);

      // 5. スコアでソート（スコア高い順）
      results.sort((a, b) {
        final scoreA = a.score ?? 0;
        final scoreB = b.score ?? 0;
        return scoreB.compareTo(scoreA);
      });

      state = state.copyWith(
        searchResults: results,
        lastQuery: query,
        lastSearchedAt: DateTime.now(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'ユーザー検索に失敗しました: $e',
        isLoading: false,
      );
      if (kDebugMode) print('Error searching users: $e');
    }
  }

  /// 検索をクリア
  void clearSearch() {
    state = UserSearchState();
  }

  /// 検索結果をフィルタリング（学年別など）
  List<SearchUserData> filterResults({int? gradeLevel}) {
    if (gradeLevel == null) return state.searchResults;

    return state.searchResults
        .where((user) => user.gradeLevel == gradeLevel)
        .toList();
  }
}

/// ユーザー検索 Provider
final userSearchProvider =
    StateNotifierProvider<UserSearchNotifier, UserSearchState>(
  (ref) {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    return UserSearchNotifier(firestore, auth);
  },
);

/// フィルタリング済み検索結果 Provider
final filteredSearchResultsProvider = Provider.family<
    List<SearchUserData>,
    int?>((ref, gradeLevel) {
  final notifier = ref.watch(userSearchProvider.notifier);
  return notifier.filterResults(gradeLevel: gradeLevel);
});
