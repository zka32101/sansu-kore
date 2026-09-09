library shared_core;

// Models
export 'models/user_profile.dart';
export 'models/quest_model.dart';
export 'models/badge_model.dart';
export 'models/avatar_model.dart';
export 'models/character_data.dart'; // BaseCharacter, CharacterState, AppShopItem, kLevelUpCost
export 'models/lesson_content_model.dart'; // LessonContent, LessonSection（解説メニュー）

// Providers
export 'providers/progress_provider.dart';
export 'providers/adaptive_provider.dart';
export 'providers/daily_bonus_provider.dart';
export 'providers/coin_provider.dart';
export 'providers/badge_provider.dart';
export 'providers/avatar_provider.dart';
export 'providers/profile_provider.dart';
export 'providers/profile_data_migration.dart'; // ProfileDataMigration
export 'providers/learning_timer_provider.dart';
export 'providers/character_state_provider.dart'; // BaseCharacterNotifier, characterStateProvider
export 'providers/inventory_provider.dart';        // InventoryNotifier, inventoryProvider
export 'providers/lesson_provider.dart';           // LessonNotifier, lessonProvider（解説メニュー）

// Widgets
export 'widgets/generic_quiz_widget.dart';
export 'widgets/daily_bonus_dialog.dart';
export 'widgets/daily_mission_card.dart';
export 'widgets/timer_chip_widget.dart';
export 'widgets/coin_balance_widget.dart';         // CoinBalanceWidget
export 'widgets/avatar_widget.dart';               // AvatarWidget, LockedAvatarWidget
export 'widgets/character_collection_page.dart';   // CharacterCollectionPage
export 'widgets/coin_shop_page.dart';              // CoinShopPage, ShopItemTile
export 'widgets/furigana_text.dart';               // FuriganaText（{漢字|かんじ}形式のルビ表示、全アプリ共通化）
export 'widgets/lesson_menu_page.dart';            // LessonMenuPage, LessonDetailPage（解説メニュー）

// Services
export 'services/firebase_service.dart';

// Theme
export 'theme/app_theme_base.dart';

// クロスプロモーション（他アプリ紹介）— 実装は cross_promo_kit（ポートフォリオ全体の共通パッケージ）
// に一本化されている。shared_core はそれを再エクスポートするだけ。
export 'package:cross_promo_kit/cross_promo_kit.dart';
