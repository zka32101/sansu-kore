import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart' show CrossPromoSection, AnalyticsDashboard;
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/daily_login_provider.dart';
import '../providers/adaptive_provider.dart';
import '../providers/logout_provider.dart';
import '../providers/sansu_profile_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: kPrimaryColor,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SettingsTabContent(ref: ref),
          const _AnalyticsTabContent(),
        ],
      ),
    );
  }
}

class _SettingsTabContent extends StatelessWidget {
  final WidgetRef ref;
  const _SettingsTabContent({required this.ref});

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).currentProfile;
    final premium = ref.watch(premiumProvider);
    final daily = ref.watch(dailyLoginProvider);
    final sansuProfile = ref.watch(sansuProfileProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile != null) ...[
            _SectionHeader('プロフィール'),
            _SettingCard(
              emoji: '👤',
              title: profile.name,
              subtitle: '学年${profile.grade}年生',
              onTap: () => Navigator.of(context).pushNamed('/profile-selection'),
            ),
          ],
          const SizedBox(height: 16),
          _SectionHeader('主人公設定'),
          _SettingCard(
            emoji: '🎁',
            title: 'すきなもの: ${sansuProfile.favoriteItem}',
            subtitle: '主人公に登場するもの',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _SectionHeader('デイリーログイン'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow('連続ログイン', '${daily.loginStreak}日'),
                  const Divider(height: 16),
                  _InfoRow('累計ログイン', '${daily.totalLoginDays}日'),
                  const Divider(height: 16),
                  _InfoRow('今日の受け取り', daily.todayClaimed ? '✅済み' : 'まだ'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader('プラン'),
          _SettingCard(
            emoji: premium.isPremium ? '👑' : '⭐',
            title: premium.isPremium ? 'プレミアムメンバー' : 'Free',
            subtitle: premium.isPremium ? '全ステージ利用可能' : 'アップグレード可能',
            onTap: () => Navigator.of(context).pushNamed('/upgrade'),
          ),
          const SizedBox(height: 16),
          _SectionHeader('その他'),
          _SettingCard(
            emoji: '❓',
            title: 'ヘルプ',
            onTap: () => Navigator.of(context).pushNamed('/help'),
          ),
          const SizedBox(height: 8),
          _SettingCard(
            emoji: '📋',
            title: 'プライバシーポリシー',
            onTap: () => Navigator.of(context).pushNamed('/privacy'),
          ),
          const SizedBox(height: 16),
          CrossPromoSection(
            appKey: 'sansu-kore',
            onAppSelected: (appName) {},
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(logoutProvider.notifier).state;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('ログアウト'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingCard({
    required this.emoji,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

class _AnalyticsTabContent extends StatelessWidget {
  const _AnalyticsTabContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AnalyticsDashboard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
