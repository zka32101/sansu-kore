import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/premium_provider.dart';
import '../theme/app_theme.dart';

class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  bool _purchasing = false;

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumProvider);

    if (premium.isPremium) {
      return Scaffold(
        appBar: AppBar(title: const Text('プレミアム'), backgroundColor: kPrimaryColor),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⭐', style: TextStyle(fontSize: 64)),
              SizedBox(height: 16),
              Text('プレミアム会員', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('全ての機能が使えます！', style: TextStyle(color: kTextMuted)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('プレミアムにアップグレード'), backgroundColor: kPrimaryColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ヘッダー
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimaryColor, kPrimaryDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  const Text(
                    '小学コレ！算数プレミアム',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (premium.isTrialActive)
                    Text(
                      'トライアル残り${premium.trialDaysLeft}日',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 機能リスト
            _FeatureList(),
            const SizedBox(height: 24),

            // 料金プラン
            _PlanCard(
              title: '月額プラン',
              price: '¥300/月',
              description: '小学コレ！算数全ステージ解放',
              badge: null,
              onTap: _purchasing ? null : () => _purchase(context, ref, monthly: true),
            ),
            const SizedBox(height: 12),
            _PlanCard(
              title: '年額プラン',
              price: '¥2,400/年',
              description: '小学コレ！算数全ステージ解放（月あたり¥200）',
              badge: '4ヶ月分おトク',
              onTap: _purchasing ? null : () => _purchase(context, ref, monthly: false),
            ),
            const SizedBox(height: 20),

            // 購入復元
            TextButton(
              onPressed: () async {
                await ref.read(premiumProvider.notifier).restorePurchases();
              },
              child: const Text('購入を復元する', style: TextStyle(color: kTextMuted)),
            ),
            const SizedBox(height: 8),
            Text(
              '• 支払いは${Platform.isIOS ? 'Apple ID' : 'Googleアカウント'}に請求されます\n• 購読はいつでもキャンセル可能\n• キャンセルは更新日の24時間前まで',
              style: const TextStyle(fontSize: 11, color: kTextMuted, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchase(BuildContext context, WidgetRef ref, {required bool monthly}) async {
    setState(() => _purchasing = true);
    try {
      final success = monthly
          ? await ref.read(premiumProvider.notifier).purchaseMonthly()
          : await ref.read(premiumProvider.notifier).purchaseYearly();
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('購入に失敗しました。再度お試しください。')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }
}

class _FeatureList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const features = [
      ('🔢', '全ステージ解放（小1〜小6）'),
      ('🏆', '全キャラクター（10体）をコンプリート'),
    ];

    return Column(
      children: features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Text(f.$1, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(f.$2, style: const TextStyle(fontSize: 15, color: kTextDark)),
            const Spacer(),
            const Icon(Icons.check_circle, color: kAccentGreen, size: 20),
          ],
        ),
      )).toList(),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final String? badge;
  final VoidCallback? onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.description,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kPrimaryColor.withAlpha(60)),
          boxShadow: [BoxShadow(color: kPrimaryColor.withAlpha(20), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kAccentGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ],
                    ],
                  ),
                  Text(description, style: const TextStyle(color: kTextMuted, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                const Text('（税込）', style: TextStyle(fontSize: 10, color: kTextMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
