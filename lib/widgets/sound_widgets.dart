// Sound Widget Layer - Audio playback UI components
// Features: Sound effect buttons, volume control, preset selector

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sansu_kore/models/sound_model.dart';
import 'package:sansu_kore/providers/sound_provider.dart';

/// サウンドプレイボタン
class SoundPlayButton extends ConsumerWidget {
  final SoundEffect soundEffect;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const SoundPlayButton({
    Key? key,
    required this.soundEffect,
    this.label = '',
    this.icon = Icons.volume_up,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isSoundPlayingProvider);
    final currentSound = ref.watch(currentSoundEffectProvider);

    return ElevatedButton.icon(
      onPressed: () async {
        await ref.read(soundPlaybackProvider.notifier).playSound(soundEffect);
        onPressed?.call();
      },
      icon: Icon(icon),
      label: Text(label.isEmpty ? 'Play' : label),
      style: ElevatedButton.styleFrom(
        backgroundColor: (isPlaying && currentSound == soundEffect)
            ? Colors.orange
            : Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// 音量スライダーウィジェット
class VolumeControlSlider extends ConsumerWidget {
  final String label;
  final bool isMasterVolume;

  const VolumeControlSlider({
    Key? key,
    required this.label,
    this.isMasterVolume = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(audioSettingsProvider);
    final currentVolume = isMasterVolume
        ? settings.masterVolume
        : settings.effectVolume;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(currentVolume * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: currentVolume,
          onChanged: (value) {
            if (isMasterVolume) {
              ref.read(audioSettingsProvider.notifier).setMasterVolume(value);
            } else {
              ref.read(audioSettingsProvider.notifier).setEffectVolume(value);
            }
          },
          min: 0.0,
          max: 1.0,
          divisions: 10,
          activeColor: Colors.blue,
          inactiveColor: Colors.grey.shade300,
        ),
      ],
    );
  }
}

/// 音声トグルスイッチ
class SoundToggleSwitch extends ConsumerWidget {
  final String label;
  final bool isSoundToggle;

  const SoundToggleSwitch({
    Key? key,
    required this.label,
    this.isSoundToggle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(audioSettingsProvider);
    final isEnabled = isSoundToggle ? settings.soundEnabled : settings.hapticEnabled;

    return SwitchListTile(
      title: Text(label),
      value: isEnabled,
      onChanged: (value) {
        if (isSoundToggle) {
          ref.read(audioSettingsProvider.notifier).toggleSound();
        } else {
          ref.read(audioSettingsProvider.notifier).toggleHaptic();
        }
      },
      activeColor: Colors.blue,
      activeTrackColor: Colors.blue.shade200,
    );
  }
}

/// 夜間ミュートトグル
class QuietHoursToggle extends ConsumerWidget {
  final String label;

  const QuietHoursToggle({
    Key? key,
    this.label = '夜間（22:00-8:00）に自動ミュート',
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(audioSettingsProvider);

    return SwitchListTile(
      title: Text(label),
      subtitle: settings.shouldMuteForQuietHours()
          ? const Text('現在ミュート中')
          : null,
      value: settings.muteInQuietHours,
      onChanged: (value) {
        ref.read(audioSettingsProvider.notifier).toggleQuietHours();
      },
      activeColor: Colors.orange,
      activeTrackColor: Colors.orange.shade200,
    );
  }
}

/// プリセットセレクター
class SoundPresetSelector extends ConsumerWidget {
  final Function(String)? onPresetSelected;

  const SoundPresetSelector({
    Key? key,
    this.onPresetSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(soundPresetsProvider);
    final currentPreset = ref.watch(currentSoundPresetProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'プリセット設定',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((preset) {
            final isSelected = currentPreset == preset.name;
            return FilterChip(
              label: Text(preset.name),
              selected: isSelected,
              onSelected: (selected) {
                ref.read(audioSettingsProvider.notifier)
                    .applyPreset(preset.name);
                onPresetSelected?.call(preset.name);
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: Colors.blue.shade300,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 音声設定パネル
class AudioSettingsPanel extends ConsumerWidget {
  final VoidCallback? onClose;

  const AudioSettingsPanel({
    Key? key,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🔊 音声設定',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sound toggle
            SoundToggleSwitch(
              label: '音声効果を有効にする',
              isSoundToggle: true,
            ),
            const SizedBox(height: 12),

            // Haptic toggle
            SoundToggleSwitch(
              label: 'ハプティクスフィードバック',
              isSoundToggle: false,
            ),
            const SizedBox(height: 20),

            // Master volume
            VolumeControlSlider(
              label: 'マスターボリューム',
              isMasterVolume: true,
            ),
            const SizedBox(height: 16),

            // Effect volume
            VolumeControlSlider(
              label: '効果音ボリューム',
              isMasterVolume: false,
            ),
            const SizedBox(height: 20),

            // Quiet hours
            QuietHoursToggle(),
            const SizedBox(height: 20),

            // Presets
            SoundPresetSelector(
              onPresetSelected: (preset) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$presetプリセットを適用しました'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Reset button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(audioSettingsProvider.notifier).resetToDefaults();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('デフォルト設定にリセットしました'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('デフォルトにリセット'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 音声設定ダイアログ
class AudioSettingsDialog extends ConsumerWidget {
  const AudioSettingsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: AudioSettingsPanel(
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}
