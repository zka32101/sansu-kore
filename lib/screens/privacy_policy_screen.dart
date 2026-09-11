import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
        backgroundColor: kPrimaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // セキュリティ透明化（設計書の教育工学機能）
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FFF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kAccentGreen.withAlpha(80)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🛡️ お子さまのデータを守ります', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  _DataItem('✅', '学習履歴（正答率・学習時間）', '学習改善のためだけに使用'),
                  _DataItem('✅', 'お子さまの名前・学年', '保護者確認のみに使用'),
                  _DataItem('❌', '位置情報', '一切収集しません'),
                  _DataItem('❌', 'SNSアカウント情報', '一切収集しません'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('保護方法', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const _BulletItem('HTTPS暗号化通信'),
            const _BulletItem('個人情報は別サーバーで管理'),
            const _BulletItem('定期的なセキュリティ監査'),
            const _BulletItem('個人情報保護法（日本）準拠'),
            const SizedBox(height: 20),
            const Text('データの削除', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'お子さまの個人情報の削除をご希望の場合は、設定画面から「学習データをリセット」するか、サポートまでお問い合わせください。リクエストから30日以内に完全削除いたします。',
              style: TextStyle(fontSize: 14, color: kTextDark, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataItem extends StatelessWidget {
  final String icon;
  final String label;
  final String description;
  const _DataItem(this.icon, this.label, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$icon ', style: const TextStyle(fontSize: 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(description, style: const TextStyle(fontSize: 12, color: kTextMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Text('• ', style: TextStyle(color: kAccentGreen, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
