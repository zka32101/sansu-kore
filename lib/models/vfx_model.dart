// Visual Effects Model - Manages animations and particle effects
// Features: Confetti variations, floating text, impact animations

import 'package:flutter/material.dart';

enum ParticleType {
  confetti,      // カラフルな紙吹雪
  stars,         // キラキラする星
  sparkles,      // 小さな火花
  hearts,        // ハート型パーティクル
  coins,         // コインパーティクル
  badges,        // バッジパーティクル
}

enum AnimationType {
  scaleIn,       // スケールイン
  slideIn,       // スライドイン
  bounce,        // バウンス
  pulse,         // パルス
  shake,         // シェイク
  flip,          // フリップ
  glow,          // グロー効果
}

/// Particle effect configuration
class ParticleEffectConfig {
  final ParticleType type;
  final int particleCount;
  final Duration duration;
  final double speed;
  final double gravity;
  final List<int> colors;

  const ParticleEffectConfig({
    required this.type,
    required this.particleCount,
    required this.duration,
    required this.speed,
    required this.gravity,
    required this.colors,
  });

  /// Pre-configured particle effects
  static const Map<ParticleType, ParticleEffectConfig> presets = {
    ParticleType.confetti: ParticleEffectConfig(
      type: ParticleType.confetti,
      particleCount: 50,
      duration: Duration(seconds: 3),
      speed: 8.0,
      gravity: 0.1,
      colors: [
        0xFFFFD700, // Gold
        0xFFFF6B6B, // Red
        0xFF4ECDC4, // Teal
        0xFF95E1D3, // Mint
        0xFFF38181, // Pink
      ],
    ),
    ParticleType.stars: ParticleEffectConfig(
      type: ParticleType.stars,
      particleCount: 30,
      duration: Duration(seconds: 2),
      speed: 5.0,
      gravity: 0.05,
      colors: [
        0xFFFFD700, // Gold
        0xFFFFED4E, // Yellow
      ],
    ),
    ParticleType.sparkles: ParticleEffectConfig(
      type: ParticleType.sparkles,
      particleCount: 20,
      duration: Duration(milliseconds: 1500),
      speed: 4.0,
      gravity: 0.15,
      colors: [
        0xFFFFFFFF, // White
        0xFFE0E0E0, // Silver
      ],
    ),
    ParticleType.hearts: ParticleEffectConfig(
      type: ParticleType.hearts,
      particleCount: 15,
      duration: Duration(seconds: 2),
      speed: 3.0,
      gravity: 0.08,
      colors: [
        0xFFFF1744, // Red
        0xFFFFC0CB, // Pink
      ],
    ),
    ParticleType.coins: ParticleEffectConfig(
      type: ParticleType.coins,
      particleCount: 25,
      duration: Duration(seconds: 2),
      speed: 6.0,
      gravity: 0.12,
      colors: [
        0xFFFFD700, // Gold
        0xFFFFC107, // Amber
      ],
    ),
    ParticleType.badges: ParticleEffectConfig(
      type: ParticleType.badges,
      particleCount: 35,
      duration: Duration(seconds: 3),
      speed: 7.0,
      gravity: 0.1,
      colors: [
        0xFF9C27B0, // Purple
        0xFFE91E63, // Pink
        0xFF2196F3, // Blue
      ],
    ),
  };

  /// Get preset for particle type
  static ParticleEffectConfig? getPreset(ParticleType type) {
    return presets[type];
  }
}

/// Animation effect configuration
class AnimationEffectConfig {
  final AnimationType type;
  final Duration duration;
  final double beginValue;
  final double endValue;
  final Curve curve;

  const AnimationEffectConfig({
    required this.type,
    required this.duration,
    required this.beginValue,
    required this.endValue,
    this.curve = Curves.easeInOut,
  });

  /// Pre-configured animations
  static const Map<AnimationType, AnimationEffectConfig> presets = {
    AnimationType.scaleIn: AnimationEffectConfig(
      type: AnimationType.scaleIn,
      duration: Duration(milliseconds: 500),
      beginValue: 0.5,
      endValue: 1.0,
      curve: Curves.elasticOut,
    ),
    AnimationType.slideIn: AnimationEffectConfig(
      type: AnimationType.slideIn,
      duration: Duration(milliseconds: 400),
      beginValue: -100,
      endValue: 0,
      curve: Curves.easeOut,
    ),
    AnimationType.bounce: AnimationEffectConfig(
      type: AnimationType.bounce,
      duration: Duration(milliseconds: 600),
      beginValue: 0,
      endValue: 1,
      curve: Curves.bounceOut,
    ),
    AnimationType.pulse: AnimationEffectConfig(
      type: AnimationType.pulse,
      duration: Duration(milliseconds: 800),
      beginValue: 0.8,
      endValue: 1.2,
      curve: Curves.easeInOut,
    ),
    AnimationType.shake: AnimationEffectConfig(
      type: AnimationType.shake,
      duration: Duration(milliseconds: 500),
      beginValue: -5,
      endValue: 5,
      curve: Curves.linear,
    ),
    AnimationType.flip: AnimationEffectConfig(
      type: AnimationType.flip,
      duration: Duration(milliseconds: 700),
      beginValue: 0,
      endValue: 1,
      curve: Curves.easeInOut,
    ),
    AnimationType.glow: AnimationEffectConfig(
      type: AnimationType.glow,
      duration: Duration(milliseconds: 1000),
      beginValue: 0,
      endValue: 1,
      curve: Curves.easeInOut,
    ),
  };

  /// Get preset for animation type
  static AnimationEffectConfig? getPreset(AnimationType type) {
    return presets[type];
  }
}

/// Floating text effect (for score popups, etc.)
class FloatingTextEffect {
  final String text;
  final Duration duration;
  final double offsetY; // How far up it floats
  final bool isCritical; // Makes text larger and more prominent

  const FloatingTextEffect({
    required this.text,
    this.duration = const Duration(milliseconds: 1500),
    this.offsetY = 100,
    this.isCritical = false,
  });

  /// Score text floating up
  static FloatingTextEffect scoreText(int score, {bool isPerfect = false}) {
    return FloatingTextEffect(
      text: '+$score',
      duration: const Duration(milliseconds: 1500),
      offsetY: 120,
      isCritical: isPerfect,
    );
  }

  /// Combo counter floating up
  static FloatingTextEffect comboText(int combo) {
    return FloatingTextEffect(
      text: '$combo COMBO!',
      duration: const Duration(milliseconds: 1200),
      offsetY: 100,
      isCritical: combo >= 5,
    );
  }

  /// Achievement/badge text
  static FloatingTextEffect achievementText(String achievement) {
    return FloatingTextEffect(
      text: achievement,
      duration: const Duration(milliseconds: 2000),
      offsetY: 150,
      isCritical: true,
    );
  }
}

/// Impact animation (screen shake, flash, etc.)
class ImpactEffect {
  final double intensity; // 0.0 to 1.0
  final Duration duration;
  final ImpactType type;

  const ImpactEffect({
    required this.intensity,
    required this.duration,
    required this.type,
  });

  static const ImpactEffect light = ImpactEffect(
    intensity: 0.3,
    duration: Duration(milliseconds: 300),
    type: ImpactType.shake,
  );

  static const ImpactEffect medium = ImpactEffect(
    intensity: 0.6,
    duration: Duration(milliseconds: 500),
    type: ImpactType.shake,
  );

  static const ImpactEffect heavy = ImpactEffect(
    intensity: 1.0,
    duration: Duration(milliseconds: 700),
    type: ImpactType.shake,
  );

  static const ImpactEffect flash = ImpactEffect(
    intensity: 0.8,
    duration: Duration(milliseconds: 400),
    type: ImpactType.flash,
  );
}

enum ImpactType { shake, flash, pulse }

/// VFX Preset combinations for different scenarios
class VFXPreset {
  final String name;
  final String trigger; // What triggers this preset
  final List<ParticleEffectConfig> particles;
  final List<AnimationEffectConfig> animations;
  final ImpactEffect? impact;

  const VFXPreset({
    required this.name,
    required this.trigger,
    required this.particles,
    required this.animations,
    this.impact,
  });

  /// Preset for perfect answer (5/5 or 100%)
  static const VFXPreset perfect = VFXPreset(
    name: 'Perfect',
    trigger: 'Perfect score (100%)',
    particles: [
      ParticleEffectConfig(
        type: ParticleType.confetti,
        particleCount: 100,
        duration: Duration(seconds: 3),
        speed: 10.0,
        gravity: 0.08,
        colors: [0xFFFFD700, 0xFFFF6B6B, 0xFF4ECDC4],
      ),
    ],
    animations: [
      AnimationEffectConfig(
        type: AnimationType.scaleIn,
        duration: Duration(milliseconds: 500),
        beginValue: 0.5,
        endValue: 1.2,
      ),
    ],
    impact: ImpactEffect(
      intensity: 0.8,
      duration: Duration(milliseconds: 600),
      type: ImpactType.shake,
    ),
  );

  /// Preset for daily challenge completion
  static const VFXPreset dailyChallenge = VFXPreset(
    name: 'Daily Challenge',
    trigger: 'Daily challenge complete',
    particles: [
      ParticleEffectConfig(
        type: ParticleType.stars,
        particleCount: 40,
        duration: Duration(seconds: 2),
        speed: 6.0,
        gravity: 0.1,
        colors: [0xFFFFD700, 0xFFFFED4E],
      ),
    ],
    animations: [
      AnimationEffectConfig(
        type: AnimationType.bounce,
        duration: Duration(milliseconds: 600),
        beginValue: 0,
        endValue: 1,
      ),
    ],
  );

  /// Preset for streak milestone
  static const VFXPreset streak = VFXPreset(
    name: 'Streak Milestone',
    trigger: 'Streak milestone reached',
    particles: [
      ParticleEffectConfig(
        type: ParticleType.coins,
        particleCount: 50,
        duration: Duration(seconds: 2),
        speed: 8.0,
        gravity: 0.12,
        colors: [0xFFFFD700, 0xFFFFC107],
      ),
    ],
    animations: [
      AnimationEffectConfig(
        type: AnimationType.pulse,
        duration: Duration(milliseconds: 800),
        beginValue: 0.8,
        endValue: 1.3,
      ),
    ],
    impact: ImpactEffect(
      intensity: 0.7,
      duration: Duration(milliseconds: 500),
      type: ImpactType.pulse,
    ),
  );
}
