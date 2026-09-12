import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/subscription_provider.dart';

/// サブスクリプション購入を促すペイウォール画面
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('クイズをもっと解く'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_outline, size: 48, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      '無料期間が終了しました',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'プレミアム会員になると\nすべてのクイズが解き放題！',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 機能一覧
              Text(
                'プレミアム会員の特典',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _FeatureItem(
                icon: Icons.check_circle,
                title: '全ステージのクイズに挑戦',
                description: '通常版では解けない問題もすべてOK',
              ),
              const SizedBox(height: 8),
              _FeatureItem(
                icon: Icons.check_circle,
                title: '広告なしで快適プレイ',
                description: '邪魔な広告を表示しません',
              ),
              const SizedBox(height: 8),
              _FeatureItem(
                icon: Icons.check_circle,
                title: '学習レポート機能',
                description: '詳細な進捗分析と親への報告機能',
              ),
              const SizedBox(height: 32),

              // 価格表示
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Text('月額'),
                      Text(
                        '¥120',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('/月（税込）'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 購入ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: subscriptionState.isLoading
                      ? null
                      : () async {
                          // 購入処理（本来はユーザーが実装）
                          await ref
                              .read(subscriptionProvider.notifier)
                              .refreshSubscriptionStatus();
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                  ),
                  child: subscriptionState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          '今すぐ購入',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // キャンセルボタン
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
              ),

              const SizedBox(height: 24),

              // 利用規約
              Center(
                child: Text(
                  '7日間の無料トライアルあり',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
