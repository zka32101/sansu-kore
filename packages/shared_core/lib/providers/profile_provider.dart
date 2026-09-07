import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';

const _profilesKey = 'user_profiles';
const _currentProfileKey = 'current_profile_id';

class ProfileState {
  final List<UserProfile> profiles;
  final String? currentProfileId;

  const ProfileState({
    required this.profiles,
    this.currentProfileId,
  });

  UserProfile? get currentProfile {
    if (currentProfileId == null) return null;
    try {
      return profiles.firstWhere((p) => p.id == currentProfileId);
    } catch (e) {
      return null;
    }
  }

  ProfileState copyWith({
    List<UserProfile>? profiles,
    String? currentProfileId,
    bool clearCurrentProfile = false,
  }) {
    return ProfileState(
      profiles: profiles ?? this.profiles,
      currentProfileId:
          clearCurrentProfile ? null : (currentProfileId ?? this.currentProfileId),
    );
  }

  static const empty = ProfileState(profiles: [], currentProfileId: null);
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() => ProfileState.empty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = prefs.getString(_profilesKey);
    final currentId = prefs.getString(_currentProfileKey);

    if (profilesJson != null) {
      final List<dynamic> decoded = jsonDecode(profilesJson);
      final profiles = decoded.map((p) => UserProfile.fromJson(p)).toList();
      state = ProfileState(profiles: profiles, currentProfileId: currentId);
    }
  }

  Future<void> addProfile(String name, int grade) async {
    final prefs = await SharedPreferences.getInstance();
    const uuid = Uuid();
    final profile = UserProfile(
      id: uuid.v4(),
      name: name,
      grade: grade,
      createdAt: DateTime.now(),
    );

    final newProfiles = [...state.profiles, profile];
    final currentId = state.currentProfileId ?? profile.id;

    await prefs.setString(
        _profilesKey, jsonEncode(newProfiles.map((p) => p.toJson()).toList()));
    await prefs.setString(_currentProfileKey, currentId);

    state = ProfileState(profiles: newProfiles, currentProfileId: currentId);
  }

  Future<void> updateProfile(String profileId, String name, int grade) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = state.profiles.map((p) {
      if (p.id == profileId) return p.copyWith(name: name, grade: grade);
      return p;
    }).toList();

    await prefs.setString(
        _profilesKey, jsonEncode(updated.map((p) => p.toJson()).toList()));
    state = state.copyWith(profiles: updated);
  }

  Future<void> deleteProfile(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final remaining = state.profiles.where((p) => p.id != profileId).toList();
    if (remaining.isEmpty) return;

    final newCurrentId = state.currentProfileId == profileId
        ? remaining.first.id
        : state.currentProfileId;

    await prefs.setString(
        _profilesKey, jsonEncode(remaining.map((p) => p.toJson()).toList()));
    if (newCurrentId != null) {
      await prefs.setString(_currentProfileKey, newCurrentId);
    }

    state = ProfileState(profiles: remaining, currentProfileId: newCurrentId);
  }

  Future<void> setCurrentProfile(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentProfileKey, profileId);
    state = ProfileState(profiles: state.profiles, currentProfileId: profileId);
  }

  /// プロフィール切り替え時のクリーンアップ: ユーザー固有データをすべてクリア
  /// ユーザープロフィール一覧は保持する
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // 削除対象キーのプレフィックス（ユーザー固有データ）
    const prefixesToRemove = [
      'stage_cleared_',      // 進捗
      'badge_earned_',       // バッジ
      'character_',          // キャラクター
      'growth_',             // 成長データ
      'avatar_',             // アバター
      'inventory_',          // インベントリ
      'learning_timer_',     // タイマー
      'daily_bonus_',        // デイリーボーナス
      'streak_count',        // ストリーク
      'last_study_date',     // 最後の学習日
      'total_correct',       // 正解数
      'total_primary_correct',
      'total_secondary_correct',
      'max_stage_cleared',
      'perfect_stage_count',
      'total_coins',         // コイン
      'sansu_my_referral_codes',    // 紹介コード関連
      'sansu_redeemed_referral_codes',
    ];

    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      // プロフィール情報は保持
      if (key == _profilesKey || key == _currentProfileKey) continue;

      // 対象プレフィックスを持つキーを削除
      bool shouldRemove = false;
      for (final prefix in prefixesToRemove) {
        if (key.startsWith(prefix)) {
          shouldRemove = true;
          break;
        }
      }

      if (shouldRemove) {
        await prefs.remove(key);
      }
    }
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
