import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ranking_provider.dart';
class RankingPrivacySettings extends ConsumerStatefulWidget {
  final bool initialValue;
  final VoidCallback? onChanged;

  const RankingPrivacySettings({
    this.initialValue = false,
    this.onChanged,
    super.key,
  });

  @override
  ConsumerState<RankingPrivacySettings> createState() =>
      _RankingPrivacySettingsState();
}

class _RankingPrivacySettingsState extends ConsumerState<RankingPrivacySettings> {
  late bool _isNamePublic;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _isNamePublic = widget.initialValue;
  }

  Future<void> _updateSetting(bool value) async {
    setState(() => _isUpdating = true);
    try {
      await ref.read(rankingProvider.notifier).updateNamePublicSetting(value);
      setState(() => _isNamePublic = value);
      widget.onChanged?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'ランキングに名前を公開しました'
                  : 'ランキングで名前を非公開にしました',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('設定の更新に失敗しました: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ランキング表示設定',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Icon(
                  _isNamePublic ? Icons.public : Icons.lock,
                  color: _isNamePublic ? Colors.green : Colors.grey,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 説明文
            Text(
              _isNamePublic
                  ? 'あなたの名前はランキングで公開されています'
                  : 'あなたの名前はランキングで非公開です',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),

            // トグルスイッチ
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('ランキングに名前を公開する'),
              subtitle: const Text(
                '名前を公開すると、あなたのランキング順位に'
                '本名が表示されます',
              ),
              value: _isNamePublic,
              onChanged: _isUpdating
                  ? null
                  : (value) => _updateSetting(value),
              activeColor: Colors.green,
            ),
            const SizedBox(height: 12),

            // プレビュー
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ランキングでの表示例:',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _isNamePublic
                          ? 'あなたの名前'
                          : 'ユーザー ${1 + (DateTime.now().hashCode % 100)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_isUpdating) ...[
              const SizedBox(height: 12),
              const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
