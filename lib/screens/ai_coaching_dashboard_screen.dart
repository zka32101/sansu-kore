import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart'
    show CoachingDashboard;

import '../design_system/design_system.dart';
import '../providers/user_profile_provider.dart';

/// AI コーチング ダッシュボード画面
///
/// ユーザーの学習パターンを分析し、個別のコーチングアドバイスを表示します。
class AiCoachingDashboardScreen extends ConsumerWidget {
  const AiCoachingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI コーチング'),
          backgroundColor: AppColors.primary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 64,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'ユーザーが未選択です',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 AI コーチング'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: CoachingDashboard(
        userId: userId,
        primaryColor: AppColors.primary,
      ),
    );
  }
}
