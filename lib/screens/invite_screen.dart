import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';


import '../providers/profile_provider.dart';
import '../providers/referral_provider.dart';
import '../theme/app_theme.dart';
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _redeemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 自分のコードが友達に使われて貯まった未受取コインを回収
    Future.microtask(
      () => ref.read(referralProvider.notifier).claimPendingCreatorRewards(),
    );
  }

  @override
  void dispose() {
    _redeemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final childName = profile.currentProfile?.name ?? 'お友達';
    final referral = ref.watch(referralProvider);

    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        title: const Text('ともコレ！友達招待'),
        backgroundColor: const Color(0xFF27AE60),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ヘッダーカード
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF27AE60), Color(0xFF1E8449)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF27AE60).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  const Text('👫', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    '$childName のお友達を招待しよう！',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '小学コレ！算数を紹介してお友達と一緒に勉強しよう',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 招待ボーナス説明
            _BonusCard(
              icon: '🔑',
              title: 'ユニークコード',
              description: 'お友達に専用コードを共有してコインゲット！',
            ),
            const SizedBox(height: 12),
            _BonusCard(
              icon: '🪙',
              title: 'ボーナスコイン',
              description: '紹介者: 100コイン、紹介された側: 50コイン',
            ),
            const SizedBox(height: 12),
            _BonusCard(
              icon: '⭐',
              title: '一緒に小学コレ！算数',
              description: '小学1〜6年の算数が遊びながら学べる！',
            ),
            const SizedBox(height: 24),

            // 紹介コード表示セクション
            _buildReferralCodeSection(context, childName, referral),
            const SizedBox(height: 24),

            // 友達のコードを入力するセクション
            _buildRedeemSection(context, referral),
            const SizedBox(height: 24),

            // 説明テキスト
            const Text(
              '※ お友達がこのコードを入力すると、あなたにコインが加算されます\n※ 1つのコードで最大5人まで紹介可能\n※ コード有効期限: 生成から30日',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 紹介コード表示セクションを構築
  Widget _buildReferralCodeSection(
      BuildContext context, String childName, ReferralState referral) {
    if (referral.activeCode == null) {
      // コード生成前
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.code, size: 40, color: Color(0xFF27AE60)),
                const SizedBox(height: 12),
                const Text(
                  'あなたの紹介コード',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: referral.isBusy ? null : () => _generateCode(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      referral.isBusy ? 'コード生成中...' : 'コードを生成',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // コード生成後
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27AE60), width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified, size: 40, color: Color(0xFF27AE60)),
          const SizedBox(height: 12),
          const Text(
            'あなたの紹介コード',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          // コード表示
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF27AE60).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF27AE60), width: 2),
            ),
            child: Text(
              referral.activeCode!,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF27AE60),
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          // コピーボタン
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _copyCode(context, referral.activeCode!),
                  icon: const Icon(Icons.copy),
                  label: const Text('コピー'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareCode(context, childName, referral.activeCode!),
                  icon: const Icon(Icons.share),
                  label: const Text('シェア'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 友達のコードを入力するセクション
  Widget _buildRedeemSection(BuildContext context, ReferralState referral) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mail_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('友達のコードを入力',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _redeemController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: '例：SANSUXXXXXX',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: referral.isBusy ? null : () => _redeemCode(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(referral.isBusy ? '確認中...' : 'コードを使う'),
            ),
          ),
        ],
      ),
    );
  }

  // コード生成処理
  Future<void> _generateCode(BuildContext context) async {
    final code = await ref.read(referralProvider.notifier).generateCode();
    if (!mounted) return;
    final error = ref.read(referralProvider).errorMessage;
    if (code != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('紹介コードが生成されました！'),
          backgroundColor: Color(0xFF27AE60),
        ),
      );
    } else if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  // コード入力処理
  Future<void> _redeemCode(BuildContext context) async {
    final input = _redeemController.text;
    final error = await ref.read(referralProvider.notifier).redeemCode(input);
    if (!mounted) return;
    if (error == null) {
      _redeemController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('コードを適用しました！50コインを獲得！'),
          backgroundColor: Color(0xFF27AE60),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  // コード表示
  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('コードをコピーしました！'),
        backgroundColor: Color(0xFF27AE60),
      ),
    );
  }

  // コード共有
  Future<void> _shareCode(BuildContext context, String childName, String code) async {
    final message = '''
$childName のお友達へ

小学コレ！算数に招待します！🎓

👉 このコードを使ってサインアップしてね:
   $code

📚 小学1年～6年の算数が遊びながら学べます
🎮 バッジやコインでやる気アップ
🏆 正解するとキャラクターもゲット

一緒に算数を楽しもう！
#算数コレ #小学算数
''';

    try {
      await Share.share(message, subject: '小学コレ！算数へのお招待');
    } catch (_) {
      // シェアキャンセル
    }
  }
}

class _BonusCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;

  const _BonusCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Text(description,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
