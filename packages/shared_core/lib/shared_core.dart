library shared_core;

// Models
export 'models/user_profile.dart';
export 'models/quest_model.dart';
export 'models/badge_model.dart';
export 'models/avatar_model.dart';
export 'models/character_data.dart'; // BaseCharacter, CharacterState, AppShopItem, ShopItemKind, kLevelUpCost
export 'models/lesson_content_model.dart'; // LessonContent, LessonSection（解説メニュー）
export 'models/feedback_model.dart'; // FeedbackType, FeedbackReport（バグ報告・改善要望）
export 'models/multiplayer_model.dart'; // MatchmakingQueueEntry, MatchState, PlayerRating（マルチプレイ対戦の共通基盤）
export 'models/screen_time_model.dart'; // ScreenTimeSettings, ScreenTimeUsage（利用時間制限）

// Data
export 'data/common_shop_items.dart'; // kCommonShopItems（背景テーマ・フレームの共通カタログ）

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
export 'providers/equipped_items_provider.dart';   // BaseEquippedItemsNotifier, equippedItemsProvider（装着状態）
export 'providers/lesson_provider.dart';           // LessonNotifier, lessonProvider（解説メニュー）
export 'providers/feedback_provider.dart';         // FeedbackNotifier, feedbackProvider（バグ報告・改善要望）
export 'providers/matchmaking_provider.dart';      // BaseMatchmakingNotifier, matchmakingProvider, MatchmakingHandlers（マッチメイキング）
export 'providers/match_provider.dart';            // BaseMatchNotifier, currentMatchProvider, MatchHandlers（対戦中マッチ状態）
export 'providers/screen_time_provider.dart';      // BaseScreenTimeNotifier, screenTimeProvider（利用時間制限）

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
export 'widgets/feedback_form_page.dart';          // FeedbackFormPage（バグ報告・改善要望）
export 'widgets/parental_gate.dart';               // ParentalGateDialog（保護者ゲート）
export 'widgets/screen_time_limit_screen.dart';    // ScreenTimeLimitReachedWidget, ScreenTimeSettingsWidget（利用時間制限）
export 'widgets/multiplayer/matchmaking_search_widget.dart'; // MatchmakingSearchWidget（マッチング待機アニメーション）
export 'widgets/multiplayer/player_rating_card.dart';        // PlayerRatingCard（自分のレーティングカード）
export 'widgets/multiplayer/leaderboard_view.dart';          // LeaderboardView（ランキング表示）
export 'widgets/multiplayer/match_history_tile.dart';        // MatchHistoryTile（対戦履歴1件表示）

// Services
export 'services/firebase_service.dart';
export 'services/firestore_matchmaking_service.dart'; // FirestoreMatchmakingService（マルチプレイのFirestoreデフォルト実装）

// Utils
export 'utils/rating_calculator.dart'; // RatingCalculator（Elo類似のレーティング計算）
export 'utils/parental_gate_helper.dart'; // requireParentalGate（保護者ゲート呼び出しヘルパー）

// Theme
export 'theme/app_theme_base.dart';

// クロスプロモーション（他アプリ紹介）— 実装は cross_promo_kit（ポートフォリオ全体の共通パッケージ）
// に一本化されている。shared_core はそれを再エクスポートするだけ。
export 'package:cross_promo_kit/cross_promo_kit.dart';
