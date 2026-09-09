import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// プロフィール対応への マイグレーション処理
/// 既存のグローバルキーをプロフィール別キーに移行
class ProfileDataMigration {
  /// マイグレーション実行フラグキー
  static const _migrationDoneKey = 'profile_data_migration_v1_done';

  /// プロフィール別キーの作成（プロフィールIDを含める）
  static String profileScopedKey(String profileId, String baseKey) {
    return '${profileId}_$baseKey';
  }

  /// 既存データをプロフィール対応に移行
  /// [activeProfileId]: 現在のアクティブなプロフィールID
  /// [oldKey]: 従来のグローバルキー
  /// [newBaseKey]: 新しいベースキー（プロフィールIDは自動で付与）
  static Future<void> migrateKey({
    required SharedPreferences prefs,
    required String activeProfileId,
    required String oldKey,
    required String? newBaseKey,
  }) async {
    final targetKey = newBaseKey ?? oldKey;
    final newKey = profileScopedKey(activeProfileId, targetKey);

    // 既に新形式で保存されていたらスキップ
    if (prefs.containsKey(newKey)) {
      return;
    }

    // 旧キーに値があればコピーして、旧キーは削除
    if (prefs.containsKey(oldKey)) {
      final type = _getValueType(prefs, oldKey);
      switch (type) {
        case 'String':
          await prefs.setString(newKey, prefs.getString(oldKey) ?? '');
          break;
        case 'int':
          await prefs.setInt(newKey, prefs.getInt(oldKey) ?? 0);
          break;
        case 'bool':
          await prefs.setBool(newKey, prefs.getBool(oldKey) ?? false);
          break;
        case 'double':
          await prefs.setDouble(newKey, prefs.getDouble(oldKey) ?? 0.0);
          break;
        case 'StringList':
          await prefs.setStringList(newKey, prefs.getStringList(oldKey) ?? []);
          break;
        default:
          break;
      }
      // 旧キーは削除（スペース節約）
      await prefs.remove(oldKey);
    }
  }

  /// 複数のキーをまとめてマイグレーション
  static Future<void> migrateKeys({
    required SharedPreferences prefs,
    required String activeProfileId,
    required Map<String, String?> keyMapping, // oldKey -> newBaseKey
  }) async {
    for (final entry in keyMapping.entries) {
      await migrateKey(
        prefs: prefs,
        activeProfileId: activeProfileId,
        oldKey: entry.key,
        newBaseKey: entry.value,
      );
    }
  }

  /// プレフィックス付きキーをマイグレーション（例：stage_cleared_*）
  static Future<void> migratePrefixedKeys({
    required SharedPreferences prefs,
    required String activeProfileId,
    required String oldPrefix,
    required String newPrefix,
  }) async {
    final allKeys = prefs.getKeys().toList();
    for (final oldKey in allKeys) {
      if (oldKey.startsWith(oldPrefix)) {
        final suffix = oldKey.replaceFirst(oldPrefix, '');
        final newKey = profileScopedKey(activeProfileId, '$newPrefix$suffix');

        // 既に新形式で保存されていたらスキップ
        if (prefs.containsKey(newKey)) {
          continue;
        }

        // 値をコピー
        if (prefs.containsKey(oldKey)) {
          final value = prefs.getInt(oldKey);
          if (value != null) {
            await prefs.setInt(newKey, value);
          }
          await prefs.remove(oldKey);
        }
      }
    }
  }

  /// マイグレーション済みかチェック
  static bool isMigrationDone(SharedPreferences prefs) {
    return prefs.getBool(_migrationDoneKey) ?? false;
  }

  /// マイグレーション完了フラグを設定
  static Future<void> markMigrationDone(SharedPreferences prefs) async {
    await prefs.setBool(_migrationDoneKey, true);
  }

  /// 値の型をチェック（String/int/bool/double/StringList）
  static String _getValueType(SharedPreferences prefs, String key) {
    if (prefs.getString(key) != null) return 'String';
    if (prefs.getInt(key) != null) return 'int';
    if (prefs.getBool(key) != null) return 'bool';
    if (prefs.getDouble(key) != null) return 'double';
    if (prefs.getStringList(key) != null) return 'StringList';
    return 'unknown';
  }
}
