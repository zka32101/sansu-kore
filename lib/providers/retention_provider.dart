import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final retentionProvider = StateNotifierProvider<RetentionNotifier, RetentionData>((ref) {
  return RetentionNotifier();
});

class RetentionNotifier extends StateNotifier<RetentionData> {
  RetentionNotifier() : super(const RetentionData(
    lastLoginDate: null,
    offboardDays: 0,
    bonusCoins: 0,
    hasReceivedBonus: false,
  )) {
    _initializeRetention();
  }

  Future<void> _initializeRetention() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getString('last_login');

    if (lastLogin != null) {
      final lastDate = DateTime.parse(lastLogin);
      final now = DateTime.now();
      final offboardDays = now.difference(lastDate).inDays;

      int bonusCoins = 0;
      if (offboardDays >= 1 && offboardDays <= 7) {
        bonusCoins = 50 + (offboardDays * 10);
      } else if (offboardDays > 7) {
        bonusCoins = 200;
      }

      state = RetentionData(
        lastLoginDate: lastDate,
        offboardDays: offboardDays,
        bonusCoins: bonusCoins,
        hasReceivedBonus: prefs.getBool('retention_bonus_received') ?? false,
      );
    }
  }

  Future<void> claimBonus() async {
    if (!state.hasReceivedBonus && state.bonusCoins > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('retention_bonus_received', true);
      state = state.copyWith(hasReceivedBonus: true);
    }
  }

  Future<void> recordLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_login', DateTime.now().toIso8601String());
    await prefs.setBool('retention_bonus_received', false);
  }
}

class RetentionData {
  final DateTime? lastLoginDate;
  final int offboardDays;
  final int bonusCoins;
  final bool hasReceivedBonus;

  const RetentionData({
    required this.lastLoginDate,
    required this.offboardDays,
    required this.bonusCoins,
    required this.hasReceivedBonus,
  });

  RetentionData copyWith({
    DateTime? lastLoginDate,
    int? offboardDays,
    int? bonusCoins,
    bool? hasReceivedBonus,
  }) {
    return RetentionData(
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      offboardDays: offboardDays ?? this.offboardDays,
      bonusCoins: bonusCoins ?? this.bonusCoins,
      hasReceivedBonus: hasReceivedBonus ?? this.hasReceivedBonus,
    );
  }
}
