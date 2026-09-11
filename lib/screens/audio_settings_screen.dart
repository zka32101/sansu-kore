// Audio Settings Screen
// Manages all audio and sound effect settings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sansu_kore/models/sound_model.dart';
import 'package:sansu_kore/providers/sound_provider.dart';
import 'package:sansu_kore/widgets/sound_widgets.dart';

/// 音声設定画面
class AudioSettingsScreen extends ConsumerStatefulWidget {
  const AudioSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AudioSettingsScreen> createState() =>
      _AudioSettingsScreenState();
}

class _AudioSettingsScreenState extends ConsumerState<AudioSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize audio settings from SharedPreferences on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioSettingsProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(audioSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔊 音声設定'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade400,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // プリセットセクション
              _buildSectionCard(
                title: 'クイック設定',
                child: Column(
                  children: [
                    const Text(
                      'よく使う設定から選択：',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SoundPresetSelector(
                      onPresetSelected: (preset) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$presetプリセットを適用しました'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 基本設定セクション
              _buildSectionCard(
                title: '基本設定',
                child: Column(
                  children: [
                    SoundToggleSwitch(
                      label: '音声効果を有効にする',
                      isSoundToggle: true,
                    ),
                    const Divider(height: 16),
                    SoundToggleSwitch(
                      label: 'ハプティクスフィードバック',
                      isSoundToggle: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ボリュームコントロールセクション
              _buildSectionCard(
                title: 'ボリューム調整',
                child: Column(
                  children: [
                    VolumeControlSlider(
                      label: 'マスターボリューム',
                      isMasterVolume: true,
                    ),
                    const SizedBox(height: 24),
                    VolumeControlSlider(
                      label: '効果音ボリューム',
                      isMasterVolume: false,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '実際の音量 = マスター × 効果音\n(${(settings.getEffectiveVolume() * 100).toStringAsFixed(0)}%)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 夜間設定セクション
              _buildSectionCard(
                title: '夜間設定',
                child: Column(
                  children: [
                    QuietHoursToggle(),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.shouldMuteForQuietHours()
                                ? '🔇 現在ミュート中です'
                                : '🔊 夜間ミュートは無効です',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: settings.shouldMuteForQuietHours()
                                  ? Colors.orange.shade700
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '夜間（22:00～8:00）に自動で音声を消音します。',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // テストセクション
              _buildSectionCard(
                title: '音声テスト',
                child: Column(
                  children: [
                    const Text(
                      '音声効果をテストして音量を確認：',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: [
                        SoundPlayButton(
                          soundEffect: SoundEffect.correct,
                          label: '正解音',
                          icon: Icons.check_circle,
                        ),
                        SoundPlayButton(
                          soundEffect: SoundEffect.incorrect,
                          label: '不正解音',
                          icon: Icons.cancel,
                        ),
                        SoundPlayButton(
                          soundEffect: SoundEffect.perfect,
                          label: 'パーフェクト',
                          icon: Icons.star,
                        ),
                        SoundPlayButton(
                          soundEffect: SoundEffect.achievement,
                          label: '実績音',
                          icon: Icons.emoji_events,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // リセットボタン
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('デフォルトにリセット'),
                        content: const Text('すべての音声設定をデフォルトに戻しますか？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('キャンセル'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(audioSettingsProvider.notifier)
                                  .resetToDefaults();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('デフォルト設定にリセットしました'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: const Text(
                              'リセット',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('デフォルトにリセット'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// セクションカード
  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
