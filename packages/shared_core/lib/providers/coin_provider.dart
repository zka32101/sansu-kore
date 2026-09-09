import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_provider.dart';
import 'profile_data_migration.dart';

const _coinBaseKey = 'total_coins';

class CoinState {
  final int totalCoins;

  const CoinState({required this.totalCoins});

  CoinState copyWith({int? totalCoins}) {
    return CoinState(totalCoins: totalCoins ?? this.totalCoins);
  }

  static const empty = CoinState(totalCoins: 0);
}

class CoinNotifier extends Notifier<CoinState> {
  @override
  CoinState build() => CoinState.empty;

  String _getCoinKey(String profileId) {
    return ProfileDataMigration.profileScopedKey(profileId, _coinBaseKey);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final profileState = ref.watch(profileProvider);
    final profileId = profileState.currentProfileId;

    if (profileId == null) {
      state = CoinState.empty;
      return;
    }

    final coinKey = _getCoinKey(profileId);
    state = CoinState(totalCoins: prefs.getInt(coinKey) ?? 0);
  }

  Future<void> addCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final profileState = ref.watch(profileProvider);
    final profileId = profileState.currentProfileId;

    if (profileId == null) return;

    final coinKey = _getCoinKey(profileId);
    final newTotal = state.totalCoins + amount;
    await prefs.setInt(coinKey, newTotal);
    state = state.copyWith(totalCoins: newTotal);
  }

  Future<bool> spendCoins(int amount) async {
    if (state.totalCoins < amount) return false;
    final prefs = await SharedPreferences.getInstance();
    final profileState = ref.watch(profileProvider);
    final profileId = profileState.currentProfileId;

    if (profileId == null) return false;

    final coinKey = _getCoinKey(profileId);
    final newTotal = state.totalCoins - amount;
    await prefs.setInt(coinKey, newTotal);
    state = state.copyWith(totalCoins: newTotal);
    return true;
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    final profileState = ref.watch(profileProvider);
    final profileId = profileState.currentProfileId;

    if (profileId == null) return;

    final coinKey = _getCoinKey(profileId);
    await prefs.remove(coinKey);
    state = CoinState.empty;
  }
}

final coinProvider = NotifierProvider<CoinNotifier, CoinState>(CoinNotifier.new);
