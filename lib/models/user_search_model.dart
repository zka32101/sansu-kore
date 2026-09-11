import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ユーザー検索結果のデータモデル
@immutable
class SearchUserData {
  final String uid;
  final String name;
  final String? avatarUrl;
  final int gradeLevel;
  final bool isNamePublic;
  final DateTime registeredDate;
  final int? score; // ランキングスコア（オプション）
  final double? correctRate; // 正答率（オプション）

  const SearchUserData({
    required this.uid,
    required this.name,
    this.avatarUrl,
    required this.gradeLevel,
    required this.isNamePublic,
    required this.registeredDate,
    this.score,
    this.correctRate,
  });

  /// Firestore ドキュメントからインスタンスを作成
  factory SearchUserData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('ユーザーデータが見つかりません');
    }

    return SearchUserData(
      uid: doc.id,
      name: data['profile']?['name'] as String? ?? 'ユーザー',
      avatarUrl: data['profile']?['avatarUrl'] as String?,
      gradeLevel: data['profile']?['gradeLevel'] as int? ?? 1,
      isNamePublic: data['profile']?['isNamePublic'] as bool? ?? false,
      registeredDate: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      score: data['score'] as int?,
      correctRate: (data['correctRate'] as num?)?.toDouble(),
    );
  }

  /// ランキングドキュメントからインスタンスを作成
  factory SearchUserData.fromRankingDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('ランキングデータが見つかりません');
    }

    return SearchUserData(
      uid: doc.id,
      name: data['userName'] as String? ?? 'ユーザー',
      avatarUrl: data['avatarUrl'] as String?,
      gradeLevel: data['gradeLevel'] as int? ?? 1,
      isNamePublic: data['isNamePublic'] as bool? ?? false,
      registeredDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      score: data['score'] as int?,
      correctRate: (data['correctRate'] as num?)?.toDouble(),
    );
  }

  /// 表示用の名前を取得（プライバシー設定対応）
  String getDisplayName() {
    return isNamePublic ? name : 'ユーザー';
  }

  @override
  String toString() =>
      'SearchUserData(uid: $uid, name: $name, gradeLevel: $gradeLevel)';
}

/// ユーザー検索の状態
@immutable
class UserSearchState {
  final List<SearchUserData> searchResults;
  final bool isLoading;
  final bool isSearching;
  final String? error;
  final String? lastQuery;
  final DateTime lastSearchedAt;

  UserSearchState({
    this.searchResults = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.error,
    this.lastQuery,
    DateTime? lastSearchedAt,
  }) : lastSearchedAt = lastSearchedAt ?? DateTime.utc(1970, 1, 1);

  UserSearchState copyWith({
    List<SearchUserData>? searchResults,
    bool? isLoading,
    bool? isSearching,
    String? error,
    String? lastQuery,
    DateTime? lastSearchedAt,
  }) {
    return UserSearchState(
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      error: error,
      lastQuery: lastQuery ?? this.lastQuery,
      lastSearchedAt: lastSearchedAt ?? this.lastSearchedAt,
    );
  }
}
