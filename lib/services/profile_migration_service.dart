import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart'
    show ProfileDataMigration;
import 'package:shared_preferences/shared_preferences.dart';


/// アプリ起動時に実行される、プロフィール対応へのマイグレーションサービス
class ProfileMigrationService {
  static const _migrationDoneKey = 'profile_data_migration_v1_done';

  /// マイグレーション処理を実行
  /// [activeProfileId]: 現在のアクティブなプロフィールID
  static Future<void> migrate(String activeProfileId) async {
    final prefs = await SharedPreferences.getInstance();

    // 既にマイグレーション済みならスキップ
    if (prefs.getBool(_migrationDoneKey) ?? false) {
      if (kDebugMode) print('✅ Profile migration already done');
      return;
    }

    if (kDebugMode) print('🔄 Starting profile data migration...');

    try {
      // 既存のグローバルキーをプロフィール対応に移行
      await _migrateProgressData(prefs, activeProfileId);
      await _migrateCoinData(prefs, activeProfileId);
      await _migrateBadgeData(prefs, activeProfileId);
      await _migrateCharacterData(prefs, activeProfileId);
      await _migrateGradeData(prefs, activeProfileId);
      await _migrateGrowthData(prefs, activeProfileId);
      await _migrateDailyBonusData(prefs, activeProfileId);
      await _migrateAdaptiveData(prefs, activeProfileId);

      // マイグレーション完了フラグを設定
      await prefs.setBool(_migrationDoneKey, true);
      if (kDebugMode) print('✅ Profile migration completed successfully');
    } catch (e) {
      if (kDebugMode) print('❌ Profile migration error: $e');
    }
  }

  /// 進捗データのマイグレーション
  static Future<void> _migrateProgressData(
      SharedPreferences prefs, String profileId) async {
    const clearedPrefix = 'stage_cleared_';
    const keys = [
      'streak_count',
      'last_study_date',
      'total_correct',
      'total_primary_correct',
      'total_secondary_correct',
      'max_stage_cleared',
      'perfect_stage_count',
    ];

    // プレフィックス付きキーをマイグレーション
    await ProfileDataMigration.migratePrefixedKeys(
      prefs: prefs,
      activeProfileId: profileId,
      oldPrefix: clearedPrefix,
      newPrefix: clearedPrefix,
    );

    // その他のキーをマイグレーション
    for (final key in keys) {
      await ProfileDataMigration.migrateKey(
        prefs: prefs,
        activeProfileId: profileId,
        oldKey: key,
        newBaseKey: key,
      );
    }
  }

  /// コインデータのマイグレーション
  static Future<void> _migrateCoinData(
      SharedPreferences prefs, String profileId) async {
    await ProfileDataMigration.migrateKey(
      prefs: prefs,
      activeProfileId: profileId,
      oldKey: 'total_coins',
      newBaseKey: 'total_coins',
    );
  }

  /// バッジデータのマイグレーション
  static Future<void> _migrateBadgeData(
      SharedPreferences prefs, String profileId) async {
    const badgePrefix = 'badge_earned_';
    await ProfileDataMigration.migratePrefixedKeys(
      prefs: prefs,
      activeProfileId: profileId,
      oldPrefix: badgePrefix,
      newPrefix: badgePrefix,
    );
  }

  /// キャラクターデータのマイグレーション
  static Future<void> _migrateCharacterData(
      SharedPreferences prefs, String profileId) async {
    const storageKey = 'myapp_char_states'; // sansu-kore固有のキー
    await ProfileDataMigration.migrateKey(
      prefs: prefs,
      activeProfileId: profileId,
      oldKey: storageKey,
      newBaseKey: storageKey,
    );
  }

  /// 学年データのマイグレーション
  static Future<void> _migrateGradeData(
      SharedPreferences prefs, String profileId) async {
    await ProfileDataMigration.migrateKey(
      prefs: prefs,
      activeProfileId: profileId,
      oldKey: 'selected_grade',
      newBaseKey: 'selected_grade',
    );
  }

  /// 成長データのマイグレーション
  static Future<void> _migrateGrowthData(
      SharedPreferences prefs, String profileId) async {
    await ProfileDataMigration.migrateKey(
      prefs: prefs,
      activeProfileId: profileId,
      oldKey: 'growth_record',
      newBaseKey: 'growth_record',
    );
  }

  /// デイリーボーナスデータのマイグレーション（shared_core）
  static Future<void> _migrateDailyBonusData(
      SharedPreferences prefs, String profileId) async {
    const keys = [
      'daily_bonus_claimed_count',
      'daily_bonus_last_claimed',
      'daily_bonus_current_streak',
    ];

    for (final key in keys) {
      await ProfileDataMigration.migrateKey(
        prefs: prefs,
        activeProfileId: profileId,
        oldKey: key,
        newBaseKey: key,
      );
    }
  }

  /// 適応学習データのマイグレーション
  static Future<void> _migrateAdaptiveData(
      SharedPreferences prefs, String profileId) async {
    const prefix = 'topic_accuracy'; // adaptive_provider で使用
    await ProfileDataMigration.migratePrefixedKeys(
      prefs: prefs,
      activeProfileId: profileId,
      oldPrefix: prefix,
      newPrefix: prefix,
    );
  }
}
