import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

import '../data/sansu_characters.dart';

// ─── Phase 4.1: CharacterProfile統合版 ────────────────────────────────────

/// 算数コレ！キャラクター管理（Phase 4.1: CharacterProfile対応）
class CharacterNotifier extends BaseCharacterProfileNotifier {
  @override
  List<BaseCharacter> get characterList => kSansuCharacters;

  @override
  String get storageKey => 'sansu_character_profiles';

  @override
  Subject get appSubject => Subject.sansu;
}

/// 統一キャラクタープロバイダー（Phase 4.1）
final characterProvider = NotifierProvider<CharacterNotifier, CharacterProfileMap>(
  CharacterNotifier.new,
);

/// 算数コレ固有の装着中アイテムノティファイア（ショップで購入したテーマ・
/// フレーム等の装着状態を管理）。
/// main.dart で equippedItemsProvider をこれで上書きする:
/// ```dart
/// equippedItemsProvider.overrideWith(EquippedItemsNotifier.new)
/// ```
class EquippedItemsNotifier extends BaseEquippedItemsNotifier {
  @override
  String get storageKey => 'sansu_equipped_items';
}
