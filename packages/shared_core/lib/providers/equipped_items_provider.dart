import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// カテゴリ（'背景' / 'フレーム' 等）→ 装着中の AppShopItem.id
class EquippedItemsState {
  final Map<String, String> equippedByCategory;

  const EquippedItemsState({this.equippedByCategory = const {}});
  static const empty = EquippedItemsState();

  EquippedItemsState copyWith({Map<String, String>? equippedByCategory}) =>
      EquippedItemsState(
        equippedByCategory: equippedByCategory ?? this.equippedByCategory,
      );
}

/// 購入済みショップアイテムの「装着中」状態を管理する共通Notifier。
/// 各アプリは [storageKey] をオーバーライドしてSharedPreferencesの
/// 名前空間を分ける（badge_provider / character_state_provider と同じパターン）。
///
/// Usage in each app:
/// ```dart
/// class EquippedItemsNotifier extends BaseEquippedItemsNotifier {
///   @override String get storageKey => 'myapp_equipped_items';
/// }
///
/// // ProviderScope の overrides で差し替える
/// equippedItemsProvider.overrideWith(EquippedItemsNotifier.new),
/// ```
abstract class BaseEquippedItemsNotifier extends Notifier<EquippedItemsState> {
  String get storageKey;

  bool _loaded = false;

  @override
  EquippedItemsState build() {
    Future.microtask(_load);
    return EquippedItemsState.empty;
  }

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw != null) {
      final map = (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as String));
      state = EquippedItemsState(equippedByCategory: map);
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(state.equippedByCategory));
  }

  /// 指定カテゴリの装着中アイテムを更新する。
  Future<void> equip(String category, String itemId) async {
    if (!_loaded) await _load();
    state = state.copyWith(equippedByCategory: {
      ...state.equippedByCategory,
      category: itemId,
    });
    await _persist();
  }

  /// 指定カテゴリの装着を解除する。
  Future<void> unequip(String category) async {
    if (!_loaded) await _load();
    final updated = Map<String, String>.from(state.equippedByCategory)
      ..remove(category);
    state = state.copyWith(equippedByCategory: updated);
    await _persist();
  }

  /// 指定カテゴリで指定アイテムが装着中かどうか。
  bool isEquipped(String category, String itemId) =>
      state.equippedByCategory[category] == itemId;
}

/// Shared placeholder provider — override in each app's ProviderScope.
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     equippedItemsProvider.overrideWith(EquippedItemsNotifier.new),
///   ],
///   child: MyApp(),
/// )
/// ```
final equippedItemsProvider =
    NotifierProvider<BaseEquippedItemsNotifier, EquippedItemsState>(
  () => throw UnimplementedError(
    'equippedItemsProvider must be overridden in each app\'s ProviderScope',
  ),
);
