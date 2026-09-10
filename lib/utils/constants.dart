/// Application-wide constants and feature flags
/// Centralized configuration for features, limits, and hardcoded values

/// Application version and metadata
class AppConfig {
  /// Application version matching pubspec.yaml
  static const String version = '2.1.0';

  /// Build number
  static const int buildNumber = 3;

  /// Application name (Japanese)
  static const String appNameJa = '算数コレ！';

  /// Application name (English)
  static const String appNameEn = 'Sansu Kore';

  /// Support email
  static const String supportEmail = 'support@example.com';

  /// Privacy policy URL
  static const String privacyPolicyUrl = 'https://example.com/privacy';

  /// Terms of service URL
  static const String termsOfServiceUrl = 'https://example.com/terms';
}

/// Feature flags for enabling/disabling features
class FeatureFlags {
  /// Google Mobile Ads integration
  /// Disabled: Temporary disable for development/testing (google_mobile_ads SPM/CocoaPods conflict)
  /// Note: Revert to true after resolving iOS dependency issues
  static const bool adsEnabled = false;

  /// Premium features (ad-free, advanced analytics, etc.)
  /// Enabled: RevenueCat subscription integration (Phase 4.2)
  static const bool premiumEnabled = true;

  /// RevenueCat subscription system
  /// Enabled: ¥120/month subscription for premium features
  static const bool subscriptionEnabled = true;

  /// Friend ranking features
  /// Enabled: Friends system implementation complete
  static const bool friendsEnabled = true;

  /// Social sharing features
  /// Enabled: Share Plus package available
  static const bool shareEnabled = true;

  /// Analytics tracking
  /// Enabled: Firebase Analytics integrated
  static const bool analyticsEnabled = true;

  /// Firebase Firestore sync
  /// Enabled: Cloud sync for progress and profile
  static const bool firestoreSyncEnabled = true;

  /// Daily challenges feature
  /// Enabled: Dynamic challenge generation
  static const bool dailyChallengesEnabled = true;

  /// Infinite practice mode
  /// Enabled: Unlimited quiz generation
  static const bool infinitePracticeEnabled = true;

  /// Ranking and leaderboards
  /// Enabled: Global and friend rankings
  static const bool rankingEnabled = true;

  /// Ghost records (best times)
  /// Enabled: Time tracking for stages
  static const bool ghostRecordsEnabled = true;

  /// Adaptive learning recommendations
  /// Enabled: Based on performance analysis
  static const bool adaptiveLearnEnabled = true;

  /// VFX and animations
  /// Enabled: Particle effects, transitions, etc.
  static const bool vfxEnabled = true;

  /// Sound and audio
  /// Enabled: Background music and sound effects
  static const bool audioEnabled = true;

  /// Character system (level-up, upgrades)
  /// Enabled: Character progression mechanics
  static const bool characterSystemEnabled = true;

  /// Coin rewards system
  /// Enabled: In-game currency system
  static const bool coinSystemEnabled = true;

  /// Badge/Achievement system
  /// Enabled: Milestone tracking and rewards
  static const bool badgeSystemEnabled = true;
}

/// Grade levels and stage information
class GradeConfig {
  /// Minimum grade level
  static const int minGrade = 1;

  /// Maximum grade level
  static const int maxGrade = 6;

  /// Total number of grades
  static const int totalGrades = 6;

  /// Estimated stages per grade
  static const int stagesPerGrade = 18; // 108 total stages / 6 grades

  /// Total number of stages
  static const int totalStages = 109;

  /// Total number of quiz questions
  static const int totalQuestions = 672;
}

/// Gameplay configuration
class GameplayConfig {
  /// Maximum time allowed per question (milliseconds)
  static const int maxTimePerQuestion = 120000; // 2 minutes

  /// Time per question for ghost records (milliseconds)
  static const int timePerQuestion = 30000; // 30 seconds

  /// Minimum accuracy percentage for excellence badge
  static const double excellenceThreshold = 0.80; // 80%

  /// Minimum accuracy percentage for good performance
  static const double goodThreshold = 0.60; // 60%

  /// Minimum accuracy percentage for fair performance
  static const double fairThreshold = 0.40; // 40%

  /// Streak milestone for special rewards
  static const int streakMilestone = 7; // Weekly streak

  /// Maximum combo counter
  static const int maxCombo = 9999;
}

/// Reward configuration
class RewardConfig {
  /// Coins earned for correct answer
  static const int coinsPerCorrect = 10;

  /// Coins earned for completing a stage
  static const int coinsPerStageComplete = 50;

  /// Coins earned for daily challenge completion
  static const int coinsPerDailyChallenge = 100;

  /// Coins earned for streak milestone
  static const int coinsPerStreakMilestone = 200;

  /// Maximum coins that can be stored
  static const int maxCoins = 999999;

  /// Base XP per correct answer
  static const int xpPerCorrect = 10;

  /// Base XP per stage completion
  static const int xpPerStageComplete = 50;
}

/// Disabled features documentation
/// These features are not active but are designed for future implementation

class DisabledFeatures {
  /// Ads Integration
  /// Status: Disabled
  /// Reason: Requires google_mobile_ads package and Google Ad Manager account setup
  /// Package: google_mobile_ads
  /// Related Provider: ads_provider.dart (stub)
  /// Related Screen: result_screen.dart (line 18-19 commented imports)
  static const String adsReason =
      'Requires google_mobile_ads integration and Ad Manager configuration';

  /// Premium Features
  /// Status: Disabled
  /// Reason: Awaiting monetization strategy and pricing model decision
  /// Related Provider: premium_provider.dart (stub)
  /// Related Screen: result_screen.dart (line 19 commented import)
  /// Features: Ad-free mode, advanced analytics, theme customization
  static const String premiumReason =
      'Awaiting monetization strategy finalization';

  /// Friend System & Social Features
  /// Status: Disabled
  /// Reason: Requires user social profile management and friend request system
  /// Related Provider: ranking_provider.dart (line 26-27 TODO comments)
  /// Features: Add friends, friend-only challenges, friend leaderboards
  static const String friendsReason =
      'Requires user social profile system implementation';
}

/// RevenueCat Configuration for Subscription Management
/// Phase 4.2: Monetization through subscription
class AppConstants {
  /// RevenueCat API Key
  /// Used for SDK initialization and subscription verification
  /// Environment: Shared across all 小学コレ apps
  static const String revenueCatApiKey = String.fromEnvironment(
    'REVENUE_CAT_API_KEY',
    defaultValue: 'appl_test_key_sansu',  // Test key for development
  );

  /// Premium Entitlement ID
  /// Granted to users with active subscription
  static const String premiumEntitlementId = 'sansu_premium';

  /// Monthly Subscription Product ID
  /// ¥120/month subscription package
  static const String monthlySubscriptionId = 'sansu_premium_monthly';

  /// Annual Subscription Product ID (Future)
  /// Planned for discounted annual offering
  static const String annualSubscriptionId = 'sansu_premium_annual';

  /// Premium Features granted by subscription:
  /// - Ad-free experience (remove banner/interstitial ads)
  /// - Unlimited daily challenges (default: 3 per day)
  /// - Advanced analytics and progress reports
  /// - Early access to new features
  /// - Offline quiz download support
}
