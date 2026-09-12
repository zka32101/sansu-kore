import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
const _premiumKey = 'is_premium';
const _trialStartKey = 'trial_start_date';
const _trialDays = 14;

// Google Play Console に登録された実際の製品IDと一致させる必要がある。
// 以前のID（sansu_kore_monthly_300 等）はストア側に存在せず、
// 「商品情報を取得できませんでした」エラーの原因だった。
const kProductIdMonthly = 'sansu-premium-monthly';
const kProductIdYearly = 'sansu-premium-annual';
const kFreeStageLimit = 5;

class PremiumState {
  final bool isPremium;
  final bool isTrialActive;
  final int trialDaysLeft;
  final bool isLoading;

  const PremiumState({
    this.isPremium = false,
    this.isTrialActive = false,
    this.trialDaysLeft = 0,
    this.isLoading = true,
  });

  // Compatibility getter for Phase 4.2-4.23 transition
  bool get isSubscribed => isPremium || isTrialActive;

  PremiumState copyWith({bool? isPremium, bool? isTrialActive, int? trialDaysLeft, bool? isLoading}) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      isTrialActive: isTrialActive ?? this.isTrialActive,
      trialDaysLeft: trialDaysLeft ?? this.trialDaysLeft,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PremiumNotifier extends Notifier<PremiumState> {
  StreamSubscription<List<PurchaseDetails>>? _sub;

  @override
  PremiumState build() => const PremiumState();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool(_premiumKey) ?? false;

    final trialStartStr = prefs.getString(_trialStartKey);
    bool isTrialActive = false;
    int daysLeft = 0;

    if (trialStartStr == null) {
      final today = DateTime.now().toIso8601String();
      await prefs.setString(_trialStartKey, today);
      isTrialActive = true;
      daysLeft = _trialDays;
    } else {
      final trialStart = DateTime.tryParse(trialStartStr);
      if (trialStart != null) {
        final elapsed = DateTime.now().difference(trialStart).inDays;
        daysLeft = _trialDays - elapsed;
        isTrialActive = daysLeft > 0;
      }
    }

    state = PremiumState(
      isPremium: isPremium,
      isTrialActive: isTrialActive && !isPremium,
      trialDaysLeft: daysLeft > 0 ? daysLeft : 0,
      isLoading: false,
    );

    _listenPurchases();
  }

  void _listenPurchases() {
    _sub?.cancel();
    _sub = InAppPurchase.instance.purchaseStream.listen(
      (purchases) {
        for (final p in purchases) {
          if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
            if (p.productID == kProductIdMonthly || p.productID == kProductIdYearly) {
              _setPremium(true);
              InAppPurchase.instance.completePurchase(p);
            }
          }
        }
      },
      onError: (_) {},
    );
  }

  Future<void> _setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
    state = state.copyWith(isPremium: value, isTrialActive: false, isLoading: false);
  }

  Future<bool> purchaseMonthly() => _purchase(kProductIdMonthly);
  Future<bool> purchaseYearly() => _purchase(kProductIdYearly);

  Future<bool> _purchase(String productId) async {
    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) return false;
      final response = await InAppPurchase.instance.queryProductDetails({productId});
      if (response.productDetails.isEmpty) return false;
      final param = PurchaseParam(productDetails: response.productDetails.first);
      return InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
    } catch (_) {
      return false;
    }
  }

  Future<void> restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
  }

  void cancelSubscription() => _sub?.cancel();
}

final premiumProvider = NotifierProvider<PremiumNotifier, PremiumState>(PremiumNotifier.new);
