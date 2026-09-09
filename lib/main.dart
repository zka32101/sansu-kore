import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart'
    show characterStateProvider, coinProvider, CrossPromoService;
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'models/quest_model.dart';
import 'providers/character_provider.dart';
import 'services/profile_migration_service.dart';
import 'screens/character_screen.dart';
import 'screens/badge_collection_screen.dart';
import 'screens/ranking_filter_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/daily_bonus_screen.dart';
import 'screens/weekly_challenge_screen.dart';
import 'screens/growth_screen.dart';
import 'screens/invite_screen.dart';
import 'screens/home_screen.dart';
import 'screens/math_guide_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/org_splash_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/profile_selection_screen.dart';
import 'screens/quest_screen.dart';
import 'screens/result_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/stage_select_screen.dart';
import 'screens/infinite_practice_screen.dart';
import 'screens/upgrade_screen.dart';
import 'screens/analysis_dashboard_screen.dart';
import 'screens/grade_upgrade_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // 匿名認証: ランキング・誤答分析・進捗クラウド同期など、多くの機能が
    // FirebaseAuth.instance.currentUser (uid) をキーに Firestore へ読み書きする。
    // サインインしていないと currentUser は常に null で、それらの機能は
    // 静かに no-op していた（ランキングが機能しない、誤答分析が保存されない等）。
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    // プロフィール対応のマイグレーション処理
    // アクティブなプロフィールIDが設定されていない場合はダミーIDを使用
    final prefs = await SharedPreferences.getInstance();
    final currentProfileId = prefs.getString('current_profile_id') ?? 'default_profile_id';
    await ProfileMigrationService.migrate(currentProfileId);

    await CrossPromoService.init();
  } catch (e) {
    if (kDebugMode) {
      print('❌ Firebase init error: $e');
    }
  }

  runApp(ProviderScope(
    overrides: [
      // 算数コレのキャラクターノティファイアを注入
      characterStateProvider.overrideWith(CharacterNotifier.new),
    ],
    child: const SansuKoreApp(),
  ));
}

class SansuKoreApp extends ConsumerWidget {
  const SansuKoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GradeUpgradeChecker(
      child: MaterialApp(
        title: '小学コレ！算数',
        theme: buildSansuTheme(),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const OrgSplashScreen(),
          '/app-splash': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/profile-selection': (context) => const ProfileSelectionScreen(),
          '/home': (context) => const RootShell(),
          '/stages': (context) => const StageSelectScreen(),
          '/characters': (context) => const CharacterScreen(),
          '/badge-collection': (context) => const BadgeCollectionScreen(),
          '/ranking': (context) => const RankingFilterScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/upgrade': (context) => const UpgradeScreen(),
          '/privacy': (context) => const PrivacyPolicyScreen(),
          '/terms': (context) => const PrivacyPolicyScreen(),
          '/daily-bonus': (context) => const DailyBonusScreen(),
          '/weekly-challenge': (context) => const WeeklyChallengeScreen(),
          '/growth': (context) => const GrowthScreen(),
          '/invite': (context) => const InviteScreen(),
          '/math-guide': (context) => const MathGuideScreen(),
          '/analysis': (context) => const AnalysisDashboardScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/quest') {
            final stage = settings.arguments as Stage;
            return MaterialPageRoute(
              builder: (_) => QuestScreen(stage: stage),
              settings: settings,
            );
          }
          if (settings.name == '/result') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => ResultScreen(
                result: args['result'] as QuestResult,
                stage: args['stage'] as Stage,
              ),
              settings: settings,
            );
          }
          if (settings.name == '/infinite-practice') {
            final topic = settings.arguments as MathTopicType?;
            return MaterialPageRoute(
              builder: (_) => InfinitePracticeScreen(initialTopic: topic),
              settings: settings,
            );
          }
          return null;
        },
      ),
    );
  }
}

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _tab = 0;

  static const _screens = [
    HomeScreen(),
    StageSelectScreen(),
    CharacterScreen(),
    ShopScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'ステージ'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'キャラ'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'ショップ'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'せってい'),
        ],
      ),
    );
  }
}
