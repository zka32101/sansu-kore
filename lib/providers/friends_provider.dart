import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// フレンドデータモデル
class FriendData {
  final String uid;
  final String name;
  final String? avatarUrl;
  final DateTime addedDate;
  final bool isNamePublic;

  FriendData({
    required this.uid,
    required this.name,
    this.avatarUrl,
    required this.addedDate,
    this.isNamePublic = false,
  });

  factory FriendData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendData(
      uid: doc.id,
      name: data['name'] as String? ?? 'ユーザー',
      avatarUrl: data['avatarUrl'] as String?,
      addedDate: (data['addedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isNamePublic: data['isNamePublic'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'avatarUrl': avatarUrl,
      'addedDate': Timestamp.fromDate(addedDate),
      'isNamePublic': isNamePublic,
    };
  }

  FriendData copyWith({
    String? uid,
    String? name,
    String? avatarUrl,
    DateTime? addedDate,
    bool? isNamePublic,
  }) {
    return FriendData(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      addedDate: addedDate ?? this.addedDate,
      isNamePublic: isNamePublic ?? this.isNamePublic,
    );
  }
}

/// フレンドシステムの状態
class FriendsState {
  final List<FriendData> friends;
  final List<String> pendingRequests; // 受信待ちリクエスト
  final List<String> sentRequests;    // 送信済みリクエスト
  final bool isLoading;
  final String? error;
  final DateTime lastUpdatedAt;

  FriendsState({
    this.friends = const [],
    this.pendingRequests = const [],
    this.sentRequests = const [],
    this.isLoading = false,
    this.error,
    DateTime? lastUpdatedAt,
  }) : lastUpdatedAt = lastUpdatedAt ?? DateTime.utc(1970, 1, 1);

  FriendsState copyWith({
    List<FriendData>? friends,
    List<String>? pendingRequests,
    List<String>? sentRequests,
    bool? isLoading,
    String? error,
    DateTime? lastUpdatedAt,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

/// フレンド管理ロジック
class FriendsNotifier extends StateNotifier<FriendsState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FriendsNotifier(this._firestore, this._auth) : super(FriendsState());

  /// フレンドリストを取得
  Future<void> fetchFriends() async {
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

      // Firestore からフレンドリストを取得
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .orderBy('addedDate', descending: true)
          .get();

      final friends = snapshot.docs
          .map((doc) => FriendData.fromFirestore(doc))
          .toList();

      state = state.copyWith(
        friends: friends,
        lastUpdatedAt: DateTime.now(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'フレンドリスト取得失敗: $e',
        isLoading: false,
      );
      if (kDebugMode) print('Error fetching friends: $e');
    }
  }

  /// フレンドリクエストを送信
  Future<bool> sendFriendRequest(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // 既に友達か確認
      if (state.friends.any((f) => f.uid == targetUserId)) {
        state = state.copyWith(error: '既にフレンドです');
        return false;
      }

      // 既にリクエスト送信済みか確認
      if (state.sentRequests.contains(targetUserId)) {
        state = state.copyWith(error: 'リクエスト送信済みです');
        return false;
      }

      // リクエストを送信（相手のpendingRequestsに追加）
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('friendRequests')
          .doc(currentUser.uid)
          .set({
        'senderId': currentUser.uid,
        'senderName': 'ユーザー',
        'requestDate': FieldValue.serverTimestamp(),
      });

      // 送信済みリストを更新
      state = state.copyWith(
        sentRequests: [...state.sentRequests, targetUserId],
        error: 'リクエストを送信しました',
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: 'リクエスト送信失敗: $e');
      if (kDebugMode) print('Error sending friend request: $e');
      return false;
    }
  }

  /// フレンドリクエストを受け入れ
  Future<bool> acceptFriendRequest(String fromUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final batch = _firestore.batch();

      // 相手をフレンドリストに追加
      batch.set(
        _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('friends')
            .doc(fromUserId),
        {
          'name': 'ユーザー',
          'avatarUrl': null,
          'addedDate': FieldValue.serverTimestamp(),
          'isNamePublic': false,
        },
      );

      // 自分を相手のフレンドリストに追加
      batch.set(
        _firestore
            .collection('users')
            .doc(fromUserId)
            .collection('friends')
            .doc(currentUser.uid),
        {
          'name': 'ユーザー',
          'avatarUrl': null,
          'addedDate': FieldValue.serverTimestamp(),
          'isNamePublic': false,
        },
      );

      // リクエストを削除
      batch.delete(
        _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('friendRequests')
            .doc(fromUserId),
      );

      await batch.commit();

      // ローカル状態を更新
      await fetchFriends();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'リクエスト承認失敗: $e');
      if (kDebugMode) print('Error accepting friend request: $e');
      return false;
    }
  }

  /// フレンドリクエストを拒否
  Future<bool> rejectFriendRequest(String fromUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // リクエストを削除
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friendRequests')
          .doc(fromUserId)
          .delete();

      return true;
    } catch (e) {
      state = state.copyWith(error: 'リクエスト拒否失敗: $e');
      if (kDebugMode) print('Error rejecting friend request: $e');
      return false;
    }
  }

  /// フレンドを削除
  Future<bool> removeFriend(String friendUid) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final batch = _firestore.batch();

      // 自分のフレンドリストから削除
      batch.delete(
        _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('friends')
            .doc(friendUid),
      );

      // 相手のフレンドリストからも削除
      batch.delete(
        _firestore
            .collection('users')
            .doc(friendUid)
            .collection('friends')
            .doc(currentUser.uid),
      );

      await batch.commit();

      // ローカル状態を更新
      state = state.copyWith(
        friends: state.friends.where((f) => f.uid != friendUid).toList(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: 'フレンド削除失敗: $e');
      if (kDebugMode) print('Error removing friend: $e');
      return false;
    }
  }

  /// フレンドIDのリストを取得（ランキング用）
  List<String> getFriendIds() {
    return state.friends.map((f) => f.uid).toList();
  }

  /// フレンド数を取得
  int getFriendCount() {
    return state.friends.length;
  }
}

/// フレンド Provider
final friendsProvider = StateNotifierProvider<FriendsNotifier, FriendsState>(
  (ref) {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    return FriendsNotifier(firestore, auth);
  },
);

/// フレンド ID リスト用 Provider（ランキングで利用）
final friendIdsProvider = Provider<List<String>>((ref) {
  final friends = ref.watch(friendsProvider);
  return friends.friends.map((f) => f.uid).toList();
});

/// フレンド数用 Provider
final friendCountProvider = Provider<int>((ref) {
  final friends = ref.watch(friendsProvider);
  return friends.friends.length;
});
