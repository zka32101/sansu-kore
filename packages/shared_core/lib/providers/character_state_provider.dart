import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_data.dart';
import 'coin_provider.dart';
import 'profile_provider.dart';
import 'profile_data_migration.dart';

typedef CharacterStateMap = Map<String, CharacterState>;

/// Abstract base for all subject character notifiers.
/// Each app subclasses this and overrides [characterList] + [storageKey].
///
/// Usage in each app:
/// ```dart
/// class CharacterNotifier extends BaseCharacterNotifier {
///   @override List<BaseCharacter> get characterList => kMyCharacters;
///   @override String get storageKey => 'myapp_char_states';
/// }
///
/// final characterProvider = NotifierProvider<CharacterNotifier, CharacterStateMap>(
///   CharacterNotifier.new,
/// );
/// ```
/// Then override [characterStateProvider] in each app's ProviderScope.
abstract class BaseCharacterNotifier extends Notifier<CharacterStateMap> {
  List<BaseCharacter> get characterList;
  String get storageKey;

  bool _loaded = false;

  @override
  CharacterStateMap build() {
    Future.microtask(_load);
    return {};
  }

  String _getStorageKey(String profileId) {
    return ProfileDataMigration.profileScopedKey(profileId, storageKey);
  }

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final profileState = ref.watch(profileProvider);
    final profileId = profileState.currentProfileId;

    if (profileId == null) {
      state = {};
      _loaded = true;
      return;
    }

    final key = _getStorageKey(profileId);
    final raw = prefs.getString(key);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      state = map.map(
        (k, v) => MapEntry(k, CharacterState.fromJson(v as Map<String, dynamic>)),
      );
    } else {
      state = {
        for (final c in characterList)
          c.id: CharacterState(isUnlocked: c.unlockAt == 0),
      };
      await _persist();
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final profileState = ref.watch(profileProvider);
    final profileId = profileState.currentProfileId;

    if (profileId == null) return;

    final key = _getStorageKey(profileId);
    await prefs.setString(key, jsonEncode(
      state.map((k, v) => MapEntry(k, v.toJson())),
    ));
  }

  /// Call after stage completion to unlock eligible characters.
  Future<void> checkUnlocks(int totalStagesCleared) async {
    if (!_loaded) await _load();
    var updated = Map<String, CharacterState>.from(state);
    bool changed = false;
    for (final char in characterList) {
      final s = updated[char.id] ?? const CharacterState();
      if (!s.isUnlocked && totalStagesCleared >= char.unlockAt) {
        updated[char.id] = s.copyWith(isUnlocked: true);
        changed = true;
      }
    }
    if (changed) {
      state = updated;
      await _persist();
    }
  }

  /// Level up a character. Returns error message, or null on success.
  Future<String?> levelUp(String characterId) async {
    if (!_loaded) await _load();
    final cs = state[characterId];
    if (cs == null || !cs.isUnlocked) return 'キャラが解放されていません';
    if (cs.isMaxLevel) return 'すでにMAXレベルです';

    final nextLevel = cs.level + 1;
    final cost = kLevelUpCost[nextLevel]!;
    final ok = await ref.read(coinProvider.notifier).spendCoins(cost);
    if (!ok) return 'コインが足りません（必要: ${cost}コイン）';

    CharacterState updated = cs.copyWith(level: nextLevel);
    if (nextLevel == 2) updated = updated.copyWith(hasExpressions: true);
    if (nextLevel == 3) updated = updated.copyWith(hasPoses: true);
    if (nextLevel == 4) updated = updated.copyWith(hasBackstory: true);
    if (nextLevel == 5) {
      updated = updated.copyWith(hasSparkle: true, hasStampCoupon: true);
    }

    state = {...state, characterId: updated};
    await _persist();
    return null;
  }
}

/// Shared placeholder provider — override in each app's ProviderScope.
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     characterStateProvider.overrideWith(CharacterNotifier.new),
///   ],
///   child: MyApp(),
/// )
/// ```
final characterStateProvider =
    NotifierProvider<BaseCharacterNotifier, CharacterStateMap>(
  () => throw UnimplementedError(
    'characterStateProvider must be overridden in each app\'s ProviderScope',
  ),
);
