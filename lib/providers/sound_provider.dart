// Sound & Audio Provider - Manages sound playback and audio settings
// Features: Sound playback state, audio settings management, preset application

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sansu_kore/models/sound_model.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// Sound playback state
class SoundPlaybackNotifier extends StateNotifier<SoundPlaybackState> {
  SoundPlaybackNotifier() : super(const SoundPlaybackState());

  /// Play a sound effect
  Future<void> playSound(SoundEffect soundEffect) async {
    final config = SoundEffectConfig.getConfig(soundEffect);
    if (config == null) return;

    state = SoundPlaybackState(
      isPlaying: true,
      currentSound: soundEffect,
      startedAt: DateTime.now(),
    );

    // In a real implementation, you would use a package like:
    // - `just_audio` for audio playback
    // - `assets_audio_player` for streaming audio
    // - `audioplayers` for simple sound effects
    //
    // Example with audioplayers:
    // final audioPlayer = AudioPlayer();
    // await audioPlayer.play(AssetSource(config.assetPath),
    //     volume: state.settings.getEffectiveVolume());

    // Simulate playback duration
    await Future.delayed(config.duration);

    state = SoundPlaybackState(
      isPlaying: false,
      currentSound: null,
    );
  }

  /// Stop current sound playback
  void stopSound() {
    state = const SoundPlaybackState(
      isPlaying: false,
      currentSound: null,
    );
  }

  /// Set error state
  void setError(String error) {
    state = SoundPlaybackState(
      isPlaying: false,
      currentSound: null,
      error: error,
    );
  }
}

/// Audio settings state manager
class AudioSettingsNotifier extends StateNotifier<AudioSettings> {
  AudioSettingsNotifier() : super(const AudioSettings());

  /// Initialize settings from SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final soundEnabled = prefs.getBool('sound_enabled') ?? true;
      final hapticEnabled = prefs.getBool('haptic_enabled') ?? true;
      final masterVolume = prefs.getDouble('master_volume') ?? 1.0;
      final effectVolume = prefs.getDouble('effect_volume') ?? 1.0;
      final muteInQuietHours = prefs.getBool('mute_in_quiet_hours') ?? true;

      state = AudioSettings(
        soundEnabled: soundEnabled,
        hapticEnabled: hapticEnabled,
        masterVolume: masterVolume,
        effectVolume: effectVolume,
        muteInQuietHours: muteInQuietHours,
      );
    } catch (e) {
      // Use default settings on error
      state = const AudioSettings();
    }
  }

  /// Toggle sound
  Future<void> toggleSound() async {
    final newSettings = state.copyWith(soundEnabled: !state.soundEnabled);
    await _saveSettings(newSettings);
    state = newSettings;
  }

  /// Toggle haptic feedback
  Future<void> toggleHaptic() async {
    final newSettings = state.copyWith(hapticEnabled: !state.hapticEnabled);
    await _saveSettings(newSettings);
    state = newSettings;
  }

  /// Set master volume
  Future<void> setMasterVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    final newSettings = state.copyWith(masterVolume: clampedVolume);
    await _saveSettings(newSettings);
    state = newSettings;
  }

  /// Set effect volume
  Future<void> setEffectVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    final newSettings = state.copyWith(effectVolume: clampedVolume);
    await _saveSettings(newSettings);
    state = newSettings;
  }

  /// Toggle quiet hours mute
  Future<void> toggleQuietHours() async {
    final newSettings = state.copyWith(
      muteInQuietHours: !state.muteInQuietHours,
    );
    await _saveSettings(newSettings);
    state = newSettings;
  }

  /// Apply a preset
  Future<void> applyPreset(String presetName) async {
    final preset = SoundPreset.getPreset(presetName);
    if (preset != null) {
      await _saveSettings(preset.settings);
      state = preset.settings;
    }
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    const defaults = AudioSettings();
    await _saveSettings(defaults);
    state = defaults;
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings(AudioSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_enabled', settings.soundEnabled);
      await prefs.setBool('haptic_enabled', settings.hapticEnabled);
      await prefs.setDouble('master_volume', settings.masterVolume);
      await prefs.setDouble('effect_volume', settings.effectVolume);
      await prefs.setBool('mute_in_quiet_hours', settings.muteInQuietHours);
    } catch (e) {
      // Handle save error
    }
  }
}

// Riverpod Providers

/// Sound playback state provider
final soundPlaybackProvider =
    StateNotifierProvider<SoundPlaybackNotifier, SoundPlaybackState>((ref) {
  return SoundPlaybackNotifier();
});

/// Audio settings provider
final audioSettingsProvider =
    StateNotifierProvider<AudioSettingsNotifier, AudioSettings>((ref) {
  return AudioSettingsNotifier();
});

/// Whether sound should actually play (considering quiet hours and settings)
final shouldPlaySoundProvider = Provider<bool>((ref) {
  final settings = ref.watch(audioSettingsProvider);
  return settings.shouldPlaySound();
});

/// Get effective volume (master × effect)
final effectiveVolumeProvider = Provider<double>((ref) {
  final settings = ref.watch(audioSettingsProvider);
  return settings.getEffectiveVolume();
});

/// Check if sound is currently playing
final isSoundPlayingProvider = Provider<bool>((ref) {
  final playback = ref.watch(soundPlaybackProvider);
  return playback.isPlaying;
});

/// Get current sound effect being played
final currentSoundEffectProvider = Provider<SoundEffect?>((ref) {
  final playback = ref.watch(soundPlaybackProvider);
  return playback.currentSound;
});

/// Check if any audio playback error occurred
final soundErrorProvider = Provider<String?>((ref) {
  final playback = ref.watch(soundPlaybackProvider);
  return playback.error;
});

/// Get list of available presets
final soundPresetsProvider = Provider<List<SoundPreset>>((ref) {
  return SoundPreset.presets;
});

/// Get current preset name
final currentSoundPresetProvider = Provider<String?>((ref) {
  final settings = ref.watch(audioSettingsProvider);

  // Try to match current settings to a preset
  for (final preset in SoundPreset.presets) {
    if (preset.settings.soundEnabled == settings.soundEnabled &&
        preset.settings.hapticEnabled == settings.hapticEnabled &&
        preset.settings.masterVolume == settings.masterVolume &&
        preset.settings.effectVolume == settings.effectVolume &&
        preset.settings.muteInQuietHours == settings.muteInQuietHours) {
      return preset.name;
    }
  }

  return null; // Custom settings, no preset match
});

/// Validate audio settings
final isAudioSettingsValidProvider = Provider<bool>((ref) {
  final settings = ref.watch(audioSettingsProvider);
  return settings.isValid;
});
