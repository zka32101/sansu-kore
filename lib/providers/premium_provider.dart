import 'package:flutter_riverpod/flutter_riverpod.dart';

final premiumProvider = StateNotifierProvider<PremiumNotifier, PremiumStatus>((ref) {
  return PremiumNotifier();
});

class PremiumNotifier extends StateNotifier<PremiumStatus> {
  PremiumNotifier() : super(const PremiumStatus(
    isPremium: false,
    expiryDate: null,
    features: [],
  ));

  void activatePremium(DateTime expiryDate) {
    state = PremiumStatus(
      isPremium: true,
      expiryDate: expiryDate,
      features: ['unlimited_stages', 'no_ads', 'exclusive_content'],
    );
  }

  void deactivatePremium() {
    state = const PremiumStatus(
      isPremium: false,
      expiryDate: null,
      features: [],
    );
  }

  bool hasFeature(String feature) {
    return state.features.contains(feature);
  }
}

class PremiumStatus {
  final bool isPremium;
  final DateTime? expiryDate;
  final List<String> features;

  const PremiumStatus({
    required this.isPremium,
    required this.expiryDate,
    required this.features,
  });
}
