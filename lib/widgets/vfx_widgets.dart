// VFX Widget Layer - Rendering visual effects
// Features: Particle effects, animations, floating text, impact effects

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:sansu_kore/models/vfx_model.dart';
import 'package:sansu_kore/providers/vfx_provider.dart';

/// パーティクルエフェクトを表示するウィジェット
class ParticleEffectWidget extends StatefulWidget {
  final ParticleEffectConfig config;
  final Offset position;

  const ParticleEffectWidget({
    Key? key,
    required this.config,
    required this.position,
  }) : super(key: key);

  @override
  State<ParticleEffectWidget> createState() => _ParticleEffectWidgetState();
}

class _ParticleEffectWidgetState extends State<ParticleEffectWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.config.duration,
      vsync: this,
    );

    _initializeParticles();
    _animationController.forward();
  }

  void _initializeParticles() {
    final random = Random();
    _particles = List.generate(widget.config.particleCount, (index) {
      return _Particle(
        position: widget.position,
        velocity: Offset(
          (random.nextDouble() - 0.5) * widget.config.speed * 2,
          -widget.config.speed + (random.nextDouble() * widget.config.speed),
        ),
        color: Color(widget.config.colors[index % widget.config.colors.length]),
        size: 8.0 + random.nextDouble() * 4.0,
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _animationController.value,
            gravity: widget.config.gravity,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// パーティクルデータ
class _Particle {
  final Offset initialPosition;
  final Offset velocity;
  final Color color;
  final double size;

  _Particle({
    required Offset position,
    required this.velocity,
    required this.color,
    required this.size,
  }) : initialPosition = position;

  Offset getPosition(double progress, double gravity) {
    final time = progress;
    final x = initialPosition.dx + (velocity.dx * time * 100);
    final y = initialPosition.dy + (velocity.dy * time * 100) +
        (0.5 * gravity * time * time * 1000);
    return Offset(x, y);
  }

  double getOpacity(double progress) {
    // Fade out near the end
    if (progress > 0.8) {
      return (1.0 - progress) * 5;
    }
    return 1.0;
  }
}

/// パーティクルペイント
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final double gravity;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.gravity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final position = particle.getPosition(progress, gravity);
      final opacity = particle.getOpacity(progress);

      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      // Draw circle particle
      canvas.drawCircle(position, particle.size / 2, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

/// アニメーション効果ウィジェット
class AnimationEffectWidget extends StatefulWidget {
  final AnimationEffectConfig config;
  final Widget child;
  final VoidCallback? onComplete;

  const AnimationEffectWidget({
    Key? key,
    required this.config,
    required this.child,
    this.onComplete,
  }) : super(key: key);

  @override
  State<AnimationEffectWidget> createState() => _AnimationEffectWidgetState();
}

class _AnimationEffectWidgetState extends State<AnimationEffectWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.config.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: widget.config.beginValue,
      end: widget.config.endValue,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.config.curve,
    ));

    _animationController.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _buildAnimatedWidget(_animation.value);
      },
      child: widget.child,
    );
  }

  Widget _buildAnimatedWidget(double value) {
    switch (widget.config.type) {
      case AnimationType.scaleIn:
        return Transform.scale(scale: value, child: widget.child);

      case AnimationType.slideIn:
        return Transform.translate(
          offset: Offset(0, value),
          child: widget.child,
        );

      case AnimationType.bounce:
        // Simple bounce effect using scale
        final bounceValue = (sin(value * pi * 4) * 0.1 + 1.0).clamp(0.8, 1.2);
        return Transform.scale(scale: bounceValue, child: widget.child);

      case AnimationType.pulse:
        return Transform.scale(scale: value, child: widget.child);

      case AnimationType.shake:
        final shakeOffset = sin(value * pi * 8) * value;
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: widget.child,
        );

      case AnimationType.flip:
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(value * pi),
          child: widget.child,
        );

      case AnimationType.glow:
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withOpacity(value * 0.5),
                blurRadius: value * 20,
                spreadRadius: value * 5,
              ),
            ],
          ),
          child: widget.child,
        );
    }
  }
}

/// 浮動テキストウィジェット（スコアポップアップ等）
class FloatingTextWidget extends StatefulWidget {
  final FloatingTextEffect effect;

  const FloatingTextWidget({
    Key? key,
    required this.effect,
  }) : super(key: key);

  @override
  State<FloatingTextWidget> createState() => _FloatingTextWidgetState();
}

class _FloatingTextWidgetState extends State<FloatingTextWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.effect.duration,
      vsync: this,
    );

    // Move up animation
    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0, -widget.effect.offsetY),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Fade out animation
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Scale animation
    _scaleAnimation = Tween<double>(
      begin: widget.effect.isCritical ? 1.2 : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Text(
            widget.effect.text,
            style: TextStyle(
              fontSize: widget.effect.isCritical ? 28 : 18,
              fontWeight: FontWeight.bold,
              color: widget.effect.isCritical ? Colors.yellow : Colors.white,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// インパクト効果ウィジェット（画面シェイク等）
class ImpactEffectWidget extends StatefulWidget {
  final ImpactEffect effect;
  final Widget child;

  const ImpactEffectWidget({
    Key? key,
    required this.effect,
    required this.child,
  }) : super(key: key);

  @override
  State<ImpactEffectWidget> createState() => _ImpactEffectWidgetState();
}

class _ImpactEffectWidgetState extends State<ImpactEffectWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.effect.duration,
      vsync: this,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final progress = _animationController.value;

        switch (widget.effect.type) {
          case ImpactType.shake:
            // Screen shake effect
            final shakeAmount = sin(progress * pi * 8) *
                widget.effect.intensity *
                (1.0 - progress) *
                10;
            return Transform.translate(
              offset: Offset(shakeAmount, 0),
              child: child,
            );

          case ImpactType.flash:
            // Flash effect
            final flashOpacity = (1.0 - progress) * widget.effect.intensity;
            return Stack(
              children: [
                child!,
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(flashOpacity * 0.5),
                  ),
                ),
              ],
            );

          case ImpactType.pulse:
            // Pulse effect
            final pulseScale = 1.0 +
                (sin(progress * pi) * widget.effect.intensity * 0.1);
            return Transform.scale(
              scale: pulseScale,
              child: child,
            );
        }
      },
      child: widget.child,
    );
  }
}

/// VFX層を管理するウィジェット
class VFXLayer extends ConsumerWidget {
  final Widget child;
  final Alignment? floatingTextAlignment;

  const VFXLayer({
    Key? key,
    required this.child,
    this.floatingTextAlignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vfxPlayback = ref.watch(vfxPlaybackProvider);
    final shouldPlayParticles = ref.watch(shouldPlayParticlesProvider);
    final shouldPlayAnimations = ref.watch(shouldPlayAnimationsProvider);
    final shouldPlayImpact = ref.watch(shouldPlayImpactProvider);

    return Stack(
      children: [
        child,
        // Particle effects
        if (shouldPlayParticles)
          ...vfxPlayback.activeEffects.map((effect) {
            final particleEffects = effect.preset.particles;
            if (particleEffects.isEmpty) return SizedBox.shrink();

            return Stack(
              children: particleEffects.map((particle) {
                return Positioned.fill(
                  child: ParticleEffectWidget(
                    config: particle,
                    position: Offset(
                      MediaQuery.of(context).size.width / 2,
                      MediaQuery.of(context).size.height / 2,
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),

        // Floating text effects (positioned at center by default)
        if (shouldPlayAnimations)
          Positioned.fill(
            child: Align(
              alignment: floatingTextAlignment ?? Alignment.center,
              child: Stack(
                children: vfxPlayback.activeEffects.map((effect) {
                  final animations = effect.preset.animations;
                  if (animations.isEmpty) return SizedBox.shrink();

                  return Stack(
                    children: animations.map((anim) {
                      return AnimationEffectWidget(
                        config: anim,
                        child: const SizedBox.shrink(),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}
