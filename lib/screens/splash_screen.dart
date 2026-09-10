import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../data/badge_data.dart';
import '../providers/adaptive_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/coin_provider.dart';
import '../providers/daily_login_provider.dart';
import '../providers/grade_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.easeIn)),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );
    _ctrl.forward();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([
      ref.read(profileProvider.notifier).load(),
      ref.read(gradeProvider.notifier).load(),
      ref.read(progressProvider.notifier).load(),
      ref.read(badgeProvider.notifier).load(allSansuBadges),
      ref.read(coinProvider.notifier).load(),
      ref.read(premiumProvider.notifier).load(),
      ref.read(adaptiveProvider.notifier).load(),
      ref.read(dailyLoginProvider.notifier).load(),
      FirebaseService.signInAnonymously(),
    ]);
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) {
      final profiles = ref.read(profileProvider).profiles;
      final currentProfile = ref.read(profileProvider).currentProfileId;

      if (profiles.isEmpty) {
        Navigator.of(context).pushReplacementNamed('/profile-selection');
      } else if (currentProfile == null) {
        Navigator.of(context).pushReplacementNamed('/profile-selection');
      } else {
        final isFirst = ref.read(gradeProvider.notifier).isFirstLaunch;
        Navigator.of(context).pushReplacementNamed(
          isFirst ? '/onboarding' : '/home',
        );
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryColor, kPrimaryDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(40),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🔴', style: TextStyle(fontSize: 52)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '小学コレ！算数',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'たし算からかんすうまで',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
