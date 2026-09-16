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
  String? _referralCode;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final childName = profile.currentProfile?.name ?? 'お友達';

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
                    '算数コレ！を紹介してお友達と一緒に勉強しよう',
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
              title: '一緒に算数コレ！',
              description: '小学1〜6年の算数が遊びながら学べる！',
            ),
            const SizedBox(height: 24),

            // 紹介コード表示セクション
            _buildReferralCodeSection(context, childName),
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
  Widget _buildReferralCodeSection(BuildContext context, String childName) {
    if (_referralCode == null) {
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
                    onPressed: _isGenerating ? null : () => _generateCode(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _isGenerating ? 'コード生成中...' : 'コードを生成',
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
              _referralCode!,
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
                  onPressed: () => _copyCode(context, _referralCode!),
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
                  onPressed: () => _shareCode(context, childName, _referralCode!),
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

  // コード生成処理
  Future<void> _generateCode(BuildContext context) async {
    setState(() => _isGenerating = true);

    try {
      final newCode = await ref.read(generateReferralKeyProvider.future);
      setState(() => _referralCode = newCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('紹介コードが生成されました！'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
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

算数コレ！に招待します！🎓

👉 このコードを使ってサインアップしてね:
   $code

📚 小学1年～6年の算数が遊びながら学べます
🎮 バッジやコインでやる気アップ
🏆 正解するとキャラクターもゲット

一緒に算数を楽しもう！
#算数コレ #小学算数
''';

    try {
      await Share.share(message, subject: '算数コレ！へのお招待');
    } catch (_) {
      // シェアキャンセル
    }
  }

  // ランダム文字列生成
  String _randomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String result = '';
    final random = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < length; i++) {
      result += chars[(random + i) % chars.length];
    }
    return result;
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
