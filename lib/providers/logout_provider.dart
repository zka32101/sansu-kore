import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_core/shared_core.dart';
import 'package:flutter/foundation.dart';

// Firebase Auth Provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// SharedPreferences Provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// ログアウト処理を実行するProvider
/// 以下を行う:
/// 1. SharedPreferences をクリア
/// 2. Firebase Auth からログアウト
/// 3. 全Provider をリセット
final logoutProvider = FutureProvider<void>((ref) async {
  try {
    // 1. SharedPreferences をクリア
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.clear();

    // 2. Firebase Auth からログアウト
    final auth = ref.read(firebaseAuthProvider);
    await auth.signOut();

    // 3. 全Provider をリセット（重要：これでキャッシュをクリア）
    // 注: shared_core から export されているプロバイダーは
    // 直接参照できないため、パッケージレベルで管理される

  } catch (e) {
    throw Exception('ログアウト失敗: $e');
  }
});

/// ログアウト実行結果
class LogoutResult {
  final bool success;
  final String? errorMessage;

  LogoutResult({
    required this.success,
    this.errorMessage,
  });

  factory LogoutResult.success() => LogoutResult(success: true);
  factory LogoutResult.error(String message) => LogoutResult(
    success: false,
    errorMessage: message,
  );
}

/// ステートフルなログアウト機能（UI統合用）
final logoutWithUIProvider =
    StateNotifierProvider.autoDispose<LogoutNotifier, AsyncValue<void>>(
  (ref) => LogoutNotifier(ref),
);

class LogoutNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  LogoutNotifier(this._ref) : super(const AsyncValue.data(null));

  /// ログアウト処理を実行
  /// 成功時は画面遷移を行う（呼び出し元で処理）
  Future<bool> logout() async {
    state = const AsyncValue.loading();

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. ユーザー固有データのクリア（プロフィール情報は保持）
      // shared_core の clearUserData() を使用
      await _ref.read(profileProvider.notifier).clearUserData();

      // 2. SharedPreferences から全ユーザー固有キーを削除
      // プレフィックスベースで削除（プロフィール情報は保持）
      const userDataPrefixes = [
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
        'sansu_',              // 算数コレ固有
        'selected_grade',      // 学年選択
      ];

      final keysToRemove = <String>[];
      for (final key in prefs.getKeys()) {
        // プロフィール情報キーは保持
        if (key == 'user_profiles' || key == 'current_profile_id') continue;

        // プレフィックスにマッチするキーを削除対象に
        for (final prefix in userDataPrefixes) {
          if (key.startsWith(prefix)) {
            keysToRemove.add(key);
            break;
          }
        }
      }

      // キーを削除
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      // 3. Firebase Auth からログアウト
      final auth = FirebaseAuth.instance;
      await auth.signOut();

      // 4. 全プロバイダーを無効化（メモリキャッシュをクリア）
      // shared_core プロバイダー
      _ref.invalidate(characterStateProvider);
      _ref.invalidate(coinProvider);
      _ref.invalidate(badgeProvider);
      _ref.invalidate(progressProvider);
      _ref.invalidate(equippedItemsProvider);

      if (kDebugMode) print('✅ ログアウト完了（プロフィール情報は保持）');

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      if (kDebugMode) print('❌ ログアウト失敗: $e\n$st');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
