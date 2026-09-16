import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_core/shared_core.dart' show characterStateProvider;
import 'package:flutter/foundation.dart';
import 'profile_provider.dart';
import 'progress_provider.dart';
import 'coin_provider.dart';
import 'badge_provider.dart';
import 'ghost_provider.dart';
import 'daily_login_provider.dart';

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
      // 1. SharedPreferences をクリア
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 2. Firebase Auth からログアウト
      final auth = FirebaseAuth.instance;
      await auth.signOut();

      // 3. 全Provider をリセット（data 関連プロバイダーをクリア）
      _ref.invalidate(profileProvider);
      _ref.invalidate(progressProvider);
      _ref.invalidate(coinProvider);
      _ref.invalidate(badgeProvider);
      _ref.invalidate(ghostProvider);
      _ref.invalidate(dailyLoginProvider);
      // shared_core プロバイダーも invalidate
      try {
        _ref.invalidate(characterStateProvider);
      } catch (e) {
        if (kDebugMode) print('characterStateProvider invalidate: $e');
      }

      if (kDebugMode) print('✅ ログアウト完了');

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      if (kDebugMode) print('❌ ログアウト失敗: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
