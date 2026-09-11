import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart' show profileProvider, ProfileDataMigration;
import 'package:shared_preferences/shared_preferences.dart';

import 'firestore_provider.dart';
const _favoriteItemBaseKey = 'sansu_favorite_item';

/// 算数コレ独自のプロフィール拡張（主人公文章題で使用）
class SansuProfileState {
  /// 文章題に登場する好きなもの（例: りんご、ケーキ、チョコ）
  final String favoriteItem;

  const SansuProfileState({
    this.favoriteItem = 'りんご',
  });

  SansuProfileState copyWith({
    String? favoriteItem,
  }) =>
      SansuProfileState(
        favoriteItem: favoriteItem ?? this.favoriteItem,
      );
}

class SansuProfileNotifier extends Notifier<SansuProfileState> {
  @override
  SansuProfileState build() {
    _load();
    return const SansuProfileState();
  }

  String _getFavoriteItemKey(String profileId) {
    return ProfileDataMigration.profileScopedKey(profileId, _favoriteItemBaseKey);
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileState = ref.watch(profileProvider);
      final profileId = profileState.currentProfileId;

      if (profileId == null) {
        state = const SansuProfileState();
        return;
      }

      final key = _getFavoriteItemKey(profileId);
      final item = prefs.getString(key) ?? 'りんご';

      state = SansuProfileState(favoriteItem: item);
    } catch (e) {
      if (kDebugMode) print('Error loading sansu profile: $e');
    }
  }

  Future<void> setFavoriteItem(String item) async {
    if (item.trim().isEmpty) return;
    final trimmed = item.trim();
    state = state.copyWith(favoriteItem: trimmed);

    // 1. SharedPreferences保存（ローカル）
    final prefs = await SharedPreferences.getInstance();
    final profileState = ref.watch(profileProvider);
    final profileId = profileState.currentProfileId;

    if (profileId == null) return;

    final key = _getFavoriteItemKey(profileId);
    await prefs.setString(key, trimmed);

    // 2. Firestore保存（クラウド）
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await UserProfileSync.updateProfile(userId, {
        'favoriteItem': trimmed,
      });
    }
  }
}

final sansuProfileProvider =
    NotifierProvider<SansuProfileNotifier, SansuProfileState>(
        SansuProfileNotifier.new);

/// 文章題の好きなもの候補リスト（設定画面で選択）
const kFavoriteItemOptions = [
  'りんご', 'ケーキ', 'チョコ', 'おかし', 'アイス',
  'ドーナツ', 'クッキー', 'キャンディ', 'カード', 'シール',
];
