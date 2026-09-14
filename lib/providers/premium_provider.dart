import 'package:flutter_riverpod/flutter_riverpod.dart';

final premiumProvider = StateNotifierProvider<PremiumNotifier, PremiumStatus>((ref) {
  return PremiumNotifier();
});

class PremiumNotifier extends StateNotifier<PremiumStatus> {
  PremiumNotifier() : super(const PremiumStatus(
    isPremium: false,
    expiryDate: null,
    features: [],
    isTrialActive: false,
    trialDaysLeft: 0,
  ));

  void activatePremium(DateTime expiryDate) {
    state = PremiumStatus(
      isPremium: true,
      expiryDate: expiryDate,
      features: ['unlimited_stages', 'no_ads', 'exclusive_content'],
      isTrialActive: false,
      trialDaysLeft: 0,
    );
  }

  void deactivatePremium() {
    state = const PremiumStatus(
      isPremium: false,
      expiryDate: null,
      features: [],
      isTrialActive: false,
      trialDaysLeft: 0,
    );
  }

  bool hasFeature(String feature) {
    return state.features.contains(feature);
  }

  Future<void> load() async {
    // RevenueCat/サーバーから復元
  }

  Future<bool> restorePurchases() async {
    return false;
  }

  Future<bool> purchaseMonthly() async {
    return false;
  }

  Future<bool> purchaseYearly() async {
    return false;
  }
}

class PremiumStatus {
  final bool isPremium;
  final DateTime? expiryDate;
  final List<String> features;
  final bool isTrialActive;
  final int trialDaysLeft;

  const PremiumStatus({
    required this.isPremium,
    required this.expiryDate,
    required this.features,
    required this.isTrialActive,
    required this.trialDaysLeft,
  });
}
