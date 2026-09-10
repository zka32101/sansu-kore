import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart'
    show
        CrossPromoSection,
        FeedbackFormPage,
        requireParentalGate,
        ScreenTimeSettingsWidget;

import '../providers/adaptive_provider.dart';
import '../providers/daily_login_provider.dart';
import '../providers/logout_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/ranking_provider.dart';
import '../providers/sansu_profile_provider.dart';
import '../providers/tts_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ranking_privacy_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).currentProfile;
    final premium = ref.watch(premiumProvider);
    final daily = ref.watch(dailyLoginProvider);
    final sansuProfile = ref.watch(sansuProfileProvider);
    final tts = ref.watch(ttsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('せってい'),
        backgroundColor: kPrimaryColor,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // プロフィール
            if (profile != null) ...[
              _SectionHeader('プロフィール'),
              _SettingCard(
                emoji: '👤',
                title: profile.name,
                subtitle: '小学${profile.grade}年生',
                onTap: () => Navigator.of(context).pushNamed('/profile-selection'),
              ),
            ],

            const SizedBox(height: 16),

            // 主人公の設定（②主人公文章題）
            _SectionHeader('文章題の主人公'),
            _SettingCard(
              emoji: '🎒',
              title: '好きなもの: ${sansuProfile.favoriteItem}',
              subtitle: '文章題に登場するものを選べるよ',
              onTap: () => _showFavoriteItemDialog(context, ref, sansuProfile.favoriteItem),
            ),

            const SizedBox(height: 16),

            // デイリーログイン情報
            _SectionHeader('デイリーログイン'),
            _InfoCard(
              children: [
                _InfoRow('連続ログイン', '${daily.loginStreak}日'),
                _InfoRow('累計ログイン', '${daily.totalLoginDays}日'),
                _InfoRow('今日の受け取り', daily.todayClaimed ? '✅ 受け取り済み' : '🎁 未受け取り'),
              ],
            ),

            const SizedBox(height: 16),

            // サブスクリプション
            _SectionHeader('プラン'),
            _SettingCard(
              emoji: premium.isPremium ? '⭐' : '🔓',
              title: premium.isPremium
                  ? 'プレミアム会員'
                  : premium.isTrialActive
                      ? 'トライアル中（あと${premium.trialDaysLeft}日）'
                      : '無料プラン',
              subtitle: premium.isPremium ? '全ステージ利用可能' : 'アップグレードで全機能解放',
              onTap: () => _goToUpgrade(context),
            ),

            const SizedBox(height: 16),

            // 親のほめメッセージ
            _SectionHeader('保護者へのメッセージ'),
            FutureBuilder<List<PraiseMessage>>(
              future: NotificationService.getPraiseQueue(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('読み込みエラー: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      height: 40,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('まだメッセージはありません', style: TextStyle(color: kTextMuted, fontSize: 14)),
                  );
                }
                return Column(
                  children: messages.reversed.take(5).map((msg) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isRead ? Colors.white : const Color(0xFFF0FFF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Text('👨‍👩‍👧', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(msg.achievement, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              Text(
                                '${msg.timestamp.month}/${msg.timestamp.day} ${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 11, color: kTextMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                );
              },
            ),

            const SizedBox(height: 16),

            // 🎤 音声読み上げ設定（TTS）
            _SectionHeader('🎤 音声読み上げ'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 音量スライダー
                  Row(
                    children: [
                      const Icon(Icons.volume_down, size: 20, color: kTextMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: tts.volume,
                          onChanged: (val) => ref.read(ttsProvider.notifier).setVolume(val),
                          min: 0,
                          max: 1,
                          activeColor: kPrimaryColor,
                          inactiveColor: Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.volume_up, size: 20, color: kPrimaryColor),
                      const SizedBox(width: 8),
                      Text(
                        '${(tts.volume * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 速度スライダー
                  Row(
                    children: [
                      const Icon(Icons.speed, size: 20, color: kTextMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: tts.rate,
                          onChanged: (val) => ref.read(ttsProvider.notifier).setRate(val),
                          min: 0,
                          max: 1,
                          activeColor: kPrimaryColor,
                          inactiveColor: Colors.grey.shade300,
                          divisions: 10,
                          label: tts.rate < 0.5 ? 'ゆっくり' : tts.rate < 0.8 ? '通常' : '速い',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(tts.rate * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // テスト読み上げボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (tts.isSpeaking && tts.currentSource == TtsSource.question) {
                          await ref.read(ttsProvider.notifier).stop();
                        } else {
                          try {
                            await ref.read(ttsProvider.notifier).speak(
                              'これはテストです。音声の調子をお確かめください。',
                              source: TtsSource.question,
                            ).timeout(
                              const Duration(seconds: 5),
                              onTimeout: () => throw Exception('音声再生がタイムアウトしました'),
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('エラー: $e')),
                              );
                            }
                          }
                        }
                      },
                      icon: Icon(
                        tts.isSpeaking ? Icons.stop : Icons.play_arrow,
                        size: 20,
                      ),
                      label: Text(
                        tts.isSpeaking ? '再生停止' : 'テスト再生',
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ランキング・分析
            _SectionHeader('🏆 ランキング・分析'),
            _SettingCard(
              emoji: '🏆',
              title: 'ランキング',
              subtitle: 'みんなの順位を見る',
              onTap: () => Navigator.of(context).pushNamed('/ranking'),
            ),
            const SizedBox(height: 8),
            _SettingCard(
              emoji: '📊',
              title: '誤答分析',
              subtitle: '苦手な分野を確認する',
              onTap: () => Navigator.of(context).pushNamed('/analysis'),
            ),
            const SizedBox(height: 16),

            // ランキング プライバシー設定
            _SectionHeader('🏆 ランキング設定'),
            Consumer(
              builder: (context, ref, child) {
                final ranking = ref.watch(rankingProvider);
                final isNamePublic = ranking.currentUserRanking?.isNamePublic ?? false;
                return RankingPrivacySettings(
                  initialValue: isNamePublic,
                );
              },
            ),

            const SizedBox(height: 16),

            // 利用時間制限
            _SectionHeader('⏰ 利用時間制限'),
            _SettingCard(
              emoji: '⏰',
              title: '利用時間を制限する',
              subtitle: '1日の利用時間に上限を設定できます（保護者向け）',
              onTap: () => _goToScreenTimeSettings(context),
            ),

            const SizedBox(height: 16),

            // その他
            _SectionHeader('その他'),
            _SettingCard(
              emoji: '📬',
              title: '成長タイムカプセル',
              subtitle: '最初の記録と今を比べよう',
              onTap: () => Navigator.of(context).pushNamed('/growth'),
            ),
            // ともコレ！友達招待: コード生成機能が動作しないため一時的に無効化（要修正）
            const SizedBox(height: 8),
            _SettingCard(
              emoji: '📄',
              title: 'プライバシーポリシー',
              subtitle: null,
              onTap: () => Navigator.of(context).pushNamed('/privacy'),
            ),
            const SizedBox(height: 8),
            _SettingCard(
              emoji: '📮',
              title: 'バグ報告・ご意見',
              subtitle: '不具合の報告や改善要望を送る',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FeedbackFormPage(
                    appName: 'sansu-kore',
                    appVersion: '3.2.0+18',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SettingCard(
              emoji: '🗑️',
              title: '学習データをリセット',
              subtitle: '進捗・コインが全て削除されます',
              onTap: () => _confirmResetWithGate(context, ref),
            ),
            const SizedBox(height: 8),
            _SettingCard(
              emoji: '🚪',
              title: 'ログアウト',
              subtitle: '別のプロフィールに切り替える',
              onTap: () => _showLogoutDialog(context, ref),
            ),

            const CrossPromoSection(
              currentAppId: 'com.yourwish.shougakukore.sansu',
              currentCategory: '小学コレ',
            ),

            const SizedBox(height: 24),
            const Center(
              child: Text(
                '小学コレ！算数 v2.0.0',
                style: TextStyle(color: kTextMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToUpgrade(BuildContext context) async {
    final passedGate = await requireParentalGate(context);
    if (!passedGate || !context.mounted) return;
    Navigator.of(context).pushNamed('/upgrade');
  }

  Future<void> _goToScreenTimeSettings(BuildContext context) async {
    final passedGate = await requireParentalGate(context);
    if (!passedGate || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('利用時間の設定'),
            backgroundColor: kPrimaryColor,
          ),
          body: const ScreenTimeSettingsWidget(primaryColor: kPrimaryColor),
        ),
      ),
    );
  }

  Future<void> _confirmResetWithGate(BuildContext context, WidgetRef ref) async {
    final passedGate = await requireParentalGate(context);
    if (!passedGate || !context.mounted) return;
    _showResetDialog(context, ref);
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('リセットしますか？'),
        content: const Text('学習履歴・コイン・バッジが全て削除されます。この操作は取り消せません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            onPressed: () async {
              await ref.read(progressProvider.notifier).reset();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('リセット'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ログアウトしますか？'),
        content: const Text(
          '現在のプロフィールからログアウトします。\n\n'
          'すべてのデータ（学習履歴・コイン・バッジ等）は保持されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // ログアウト処理を実行
              final notifier = ref.read(logoutWithUIProvider.notifier);
              final success = await notifier.logout();

              if (success && ctx.mounted) {
                // ログアウト成功 → ログイン画面へ
                Navigator.pop(ctx); // ダイアログを閉じる
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/splash', // またはログイン画面のルート
                  (route) => false,
                );

                // スナックバー表示
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ログアウトしました'),
                    backgroundColor: Color(0xFF27AE60),
                  ),
                );
              } else if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ログアウトに失敗しました'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'ログアウト',
              style: TextStyle(color: Colors.white),
            ),
          ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 13, color: kTextMuted, fontWeight: FontWeight.bold)),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingCard({required this.emoji, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  if (subtitle != null)
                    Text(subtitle!, style: const TextStyle(fontSize: 12, color: kTextMuted)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.arrow_forward_ios, color: kTextMuted, size: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6)],
      ),
      child: Column(children: children),
    );
  }
}

// ─── 好きなもの選択ダイアログ（②主人公文章題） ─────────────────────
void _showFavoriteItemDialog(
    BuildContext context, WidgetRef ref, String currentItem) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('🎒 好きなものを選んでね'),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: kFavoriteItemOptions.map((item) {
          final isSelected = item == currentItem;
          return GestureDetector(
            onTap: () {
              ref.read(sansuProfileProvider.notifier).setFavoriteItem(item);
              Navigator.pop(ctx);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? kPrimaryColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? kPrimaryColor : Colors.grey.shade300,
                ),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : kTextDark,
                ),
              ),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('とじる'))
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: kTextMuted)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
