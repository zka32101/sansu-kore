// Visual Effects Provider - Manages animations and particle effects
// Features: VFX playback state, particle effects, animation triggers

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sansu_kore/models/vfx_model.dart';

/// Active VFX effect being displayed
class ActiveVFXEffect {
  final VFXPreset preset;
  final DateTime startedAt;
  final Duration totalDuration;

  const ActiveVFXEffect({
    required this.preset,
    required this.startedAt,
    required this.totalDuration,
  });

  bool get isFinished =>
      DateTime.now().difference(startedAt) >= totalDuration;

  double get progress {
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    final total = totalDuration.inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}

/// VFX playback state container
class VFXPlaybackState {
  final List<ActiveVFXEffect> activeEffects;
  final bool isAnyEffectPlaying;

  const VFXPlaybackState({
    this.activeEffects = const [],
    this.isAnyEffectPlaying = false,
  });

  VFXPlaybackState copyWith({
    List<ActiveVFXEffect>? activeEffects,
    bool? isAnyEffectPlaying,
  }) {
    return VFXPlaybackState(
      activeEffects: activeEffects ?? this.activeEffects,
      isAnyEffectPlaying: isAnyEffectPlaying ?? this.isAnyEffectPlaying,
    );
  }
}

/// VFX playback state manager
class VFXPlaybackNotifier extends StateNotifier<VFXPlaybackState> {
  VFXPlaybackNotifier() : super(const VFXPlaybackState());

  /// Play a VFX preset
  Future<void> playVFX(VFXPreset preset) async {
    // Calculate total duration as the maximum of all animations and particles
    final maxParticleDuration = preset.particles
        .map((p) => p.duration.inMilliseconds)
        .fold<int>(0, (max, val) => val > max ? val : max);

    final maxAnimationDuration = preset.animations
        .map((a) => a.duration.inMilliseconds)
        .fold<int>(0, (max, val) => val > max ? val : max);

    final impactDuration = preset.impact?.duration.inMilliseconds ?? 0;
    final totalMs = [maxParticleDuration, maxAnimationDuration, impactDuration]
        .reduce((a, b) => a > b ? a : b);
    final totalDuration = Duration(milliseconds: totalMs);

    final effect = ActiveVFXEffect(
      preset: preset,
      startedAt: DateTime.now(),
      totalDuration: totalDuration,
    );

    state = state.copyWith(
      activeEffects: [...state.activeEffects, effect],
      isAnyEffectPlaying: true,
    );

    // Wait for effect to finish
    await Future.delayed(totalDuration);

    // Remove finished effect
    _removeEffect(effect);
  }

  /// Play a particle effect
  Future<void> playParticleEffect(ParticleEffectConfig config) async {
    // Create a temporary VFX preset with just this particle effect
    final tempPreset = VFXPreset(
      name: 'Particle_${config.type}',
      trigger: 'Particle effect',
      particles: [config],
      animations: const [],
    );

    await playVFX(tempPreset);
  }

  /// Play a floating text effect
  Future<void> playFloatingText(FloatingTextEffect effect) async {
    // Create a temporary VFX preset with animation for floating text
    final floatingAnimation = AnimationEffectConfig(
      type: AnimationType.slideIn,
      duration: effect.duration,
      beginValue: 0,
      endValue: effect.offsetY,
      curve: Curves.easeOut,
    );

    final tempPreset = VFXPreset(
      name: 'FloatingText_${effect.text}',
      trigger: 'Floating text',
      particles: const [],
      animations: [floatingAnimation],
    );

    await playVFX(tempPreset);
  }

  /// Play an animation effect
  Future<void> playAnimation(AnimationEffectConfig config) async {
    final tempPreset = VFXPreset(
      name: 'Animation_${config.type}',
      trigger: 'Animation effect',
      particles: const [],
      animations: [config],
    );

    await playVFX(tempPreset);
  }

  /// Play an impact effect (screen shake, flash, etc.)
  Future<void> playImpact(ImpactEffect impact) async {
    final tempPreset = VFXPreset(
      name: 'Impact_${impact.type}',
      trigger: 'Impact effect',
      particles: const [],
      animations: const [],
      impact: impact,
    );

    await playVFX(tempPreset);
  }

  /// Stop all VFX effects
  void stopAllEffects() {
    state = const VFXPlaybackState(
      activeEffects: [],
      isAnyEffectPlaying: false,
    );
  }

  /// Stop specific VFX effect
  void stopEffect(VFXPreset preset) {
    final updated = state.activeEffects
        .where((e) => e.preset.name != preset.name)
        .toList();

    state = state.copyWith(
      activeEffects: updated,
      isAnyEffectPlaying: updated.isNotEmpty,
    );
  }

  /// Remove finished effect
  void _removeEffect(ActiveVFXEffect effect) {
    final updated = state.activeEffects
        .where((e) => e.preset.name != effect.preset.name)
        .toList();

    state = state.copyWith(
      activeEffects: updated,
      isAnyEffectPlaying: updated.isNotEmpty,
    );
  }

  /// Pause all effects
  void pauseAllEffects() {
    // In a real implementation, you would track pause time
    // and adjust progress calculations accordingly
  }

  /// Resume all effects
  void resumeAllEffects() {
    // In a real implementation, you would resume from pause time
  }
}

/// VFX Settings (enable/disable, intensity scale)
class VFXSettings {
  final bool particlesEnabled;
  final bool animationsEnabled;
  final bool impactEnabled;
  final double intensityScale; // 0.0 to 1.0

  const VFXSettings({
    this.particlesEnabled = true,
    this.animationsEnabled = true,
    this.impactEnabled = true,
    this.intensityScale = 1.0,
  });

  VFXSettings copyWith({
    bool? particlesEnabled,
    bool? animationsEnabled,
    bool? impactEnabled,
    double? intensityScale,
  }) {
    return VFXSettings(
      particlesEnabled: particlesEnabled ?? this.particlesEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      impactEnabled: impactEnabled ?? this.impactEnabled,
      intensityScale: intensityScale ?? this.intensityScale,
    );
  }

  bool get isValid => intensityScale >= 0.0 && intensityScale <= 1.0;
}

/// VFX Settings state manager
class VFXSettingsNotifier extends StateNotifier<VFXSettings> {
  VFXSettingsNotifier() : super(const VFXSettings());

  /// Toggle particle effects
  void toggleParticles() {
    state = state.copyWith(particlesEnabled: !state.particlesEnabled);
  }

  /// Toggle animations
  void toggleAnimations() {
    state = state.copyWith(animationsEnabled: !state.animationsEnabled);
  }

  /// Toggle impact effects
  void toggleImpact() {
    state = state.copyWith(impactEnabled: !state.impactEnabled);
  }

  /// Set intensity scale (for performance tuning)
  void setIntensityScale(double scale) {
    final clamped = scale.clamp(0.0, 1.0);
    state = state.copyWith(intensityScale: clamped);
  }

  /// Disable all effects (performance mode)
  void setPerformanceMode(bool enabled) {
    if (enabled) {
      state = const VFXSettings(
        particlesEnabled: false,
        animationsEnabled: false,
        impactEnabled: false,
        intensityScale: 0.0,
      );
    } else {
      state = const VFXSettings();
    }
  }

  /// Reset to defaults
  void resetToDefaults() {
    state = const VFXSettings();
  }
}

// Riverpod Providers

/// VFX playback state provider
final vfxPlaybackProvider =
    StateNotifierProvider<VFXPlaybackNotifier, VFXPlaybackState>((ref) {
  return VFXPlaybackNotifier();
});

/// VFX settings provider
final vfxSettingsProvider =
    StateNotifierProvider<VFXSettingsNotifier, VFXSettings>((ref) {
  return VFXSettingsNotifier();
});

/// Check if any VFX is currently playing
final isVFXPlayingProvider = Provider<bool>((ref) {
  final playback = ref.watch(vfxPlaybackProvider);
  return playback.isAnyEffectPlaying;
});

/// Get list of active VFX effects
final activeVFXEffectsProvider = Provider<List<ActiveVFXEffect>>((ref) {
  final playback = ref.watch(vfxPlaybackProvider);
  return playback.activeEffects;
});

/// Get number of active effects
final activeEffectCountProvider = Provider<int>((ref) {
  final effects = ref.watch(activeVFXEffectsProvider);
  return effects.length;
});

/// Get current progress of first active effect (0.0 to 1.0)
final currentVFXProgressProvider = Provider<double>((ref) {
  final effects = ref.watch(activeVFXEffectsProvider);
  if (effects.isEmpty) return 0.0;
  return effects.first.progress;
});

/// Get all VFX presets available
final vfxPresetsProvider = Provider<List<VFXPreset>>((ref) {
  return [
    VFXPreset.perfect,
    VFXPreset.dailyChallenge,
    VFXPreset.streak,
  ];
});

/// Check if should play particle effects (based on settings)
final shouldPlayParticlesProvider = Provider<bool>((ref) {
  final settings = ref.watch(vfxSettingsProvider);
  return settings.particlesEnabled && settings.intensityScale > 0.0;
});

/// Check if should play animations (based on settings)
final shouldPlayAnimationsProvider = Provider<bool>((ref) {
  final settings = ref.watch(vfxSettingsProvider);
  return settings.animationsEnabled && settings.intensityScale > 0.0;
});

/// Check if should play impact effects (based on settings)
final shouldPlayImpactProvider = Provider<bool>((ref) {
  final settings = ref.watch(vfxSettingsProvider);
  return settings.impactEnabled && settings.intensityScale > 0.0;
});

/// Get intensity scale for VFX effects
final vfxIntensityProvider = Provider<double>((ref) {
  final settings = ref.watch(vfxSettingsProvider);
  return settings.intensityScale;
});

/// Validate VFX settings
final isVFXSettingsValidProvider = Provider<bool>((ref) {
  final settings = ref.watch(vfxSettingsProvider);
  return settings.isValid;
});
