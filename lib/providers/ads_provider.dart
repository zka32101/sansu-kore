import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';

/// AdMob 広告 ID 設定
class AdUnitIds {
  // Android 広告 ID
  static const String androidBannerId = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';
  static const String androidInterstitialId = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';
  static const String androidRewardedId = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';

  // iOS 広告 ID
  static const String iosBannerId = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';
  static const String iosInterstitialId = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';
  static const String iosRewardedId = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';

  // テスト広告 ID
  static const String testDeviceId = 'F3DE2BC4A2B0F37F14577C2E0AF88FF8';
}

/// 広告管理状態
class AdsState {
  final bool isInitialized;
  final bool isBannerLoaded;
  final bool isInterstitialLoaded;
  final bool isRewardedLoaded;
  final String? error;

  AdsState({
    this.isInitialized = false,
    this.isBannerLoaded = false,
    this.isInterstitialLoaded = false,
    this.isRewardedLoaded = false,
    this.error,
  });

  AdsState copyWith({
    bool? isInitialized,
    bool? isBannerLoaded,
    bool? isInterstitialLoaded,
    bool? isRewardedLoaded,
    String? error,
  }) {
    return AdsState(
      isInitialized: isInitialized ?? this.isInitialized,
      isBannerLoaded: isBannerLoaded ?? this.isBannerLoaded,
      isInterstitialLoaded: isInterstitialLoaded ?? this.isInterstitialLoaded,
      isRewardedLoaded: isRewardedLoaded ?? this.isRewardedLoaded,
      error: error,
    );
  }
}

/// 広告管理ロジック - Stub 実装（google_mobile_ads 依存性回避）
///
/// google_mobile_ads は iOS SPM/CocoaPods 衝突のため一時的に無効化されています。
/// 本実装は no-op ですが、API 互換性を保ちます。
/// 本物の広告サポートは iOS 依存性衝突が解決されたら再度有効化します。
class AdsNotifier extends StateNotifier<AdsState> {
  AdsNotifier() : super(AdsState()) {
    _initializeMobileAds();
  }

  /// Google Mobile Ads SDK 初期化 (Stub)
  Future<void> _initializeMobileAds() async {
    if (!FeatureFlags.adsEnabled) return;

    try {
      // google_mobile_ads 無効化のため、スキップ
      state = state.copyWith(isInitialized: true);
      if (kDebugMode) print('⚠️  AdMob: Stub implementation (google_mobile_ads disabled due to iOS conflict)');
    } catch (e) {
      state = state.copyWith(error: '広告初期化スキップ: $e');
    }
  }

  /// バナー広告を表示 (Stub - no-op)
  void showBannerAd() {
    if (kDebugMode) print('⚠️  showBannerAd() called but google_mobile_ads is disabled');
  }

  /// インタースティシャル広告を表示 (Stub - no-op)
  Future<void> showInterstitialAd() async {
    if (kDebugMode) print('⚠️  showInterstitialAd() called but google_mobile_ads is disabled');
  }

  /// リワード広告を表示 (Stub - no-op)
  Future<void> showRewardedAd() async {
    if (kDebugMode) print('⚠️  showRewardedAd() called but google_mobile_ads is disabled');
  }

  /// 広告をクリア (Stub - no-op)
  void disposeAds() {
    if (kDebugMode) print('⚠️  disposeAds() called but google_mobile_ads is disabled');
  }

  /// リロード (Stub - no-op)
  Future<void> reloadAds() async {
    if (kDebugMode) print('⚠️  reloadAds() called but google_mobile_ads is disabled');
  }
}

/// 広告プロバイダー
final adsProvider = StateNotifierProvider<AdsNotifier, AdsState>((ref) {
  return AdsNotifier();
});
