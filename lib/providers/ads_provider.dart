import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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

/// 広告管理ロジック
class AdsNotifier extends StateNotifier<AdsState> {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  AdsNotifier() : super(AdsState()) {
    _initializeMobileAds();
  }

  /// Google Mobile Ads SDK 初期化
  Future<void> _initializeMobileAds() async {
    if (!FeatureFlags.adsEnabled) return;

    try {
      await MobileAds.instance.initialize();
      state = state.copyWith(isInitialized: true);

      // 広告を読み込み
      _loadBannerAd();
      _loadInterstitialAd();
      _loadRewardedAd();
    } catch (e) {
      state = state.copyWith(error: '広告初期化失敗: $e');
      if (kDebugMode) print('Error initializing MobileAds: $e');
    }
  }

  /// バナー広告を読み込み（最適化：ホーム画面下部）
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _getAdUnitId('banner'),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          state = state.copyWith(isBannerLoaded: true);
          if (kDebugMode) print('✅ Banner Ad Loaded');
        },
        onAdFailedToLoad: (ad, error) {
          state = state.copyWith(error: 'バナー広告読み込み失敗: ${error.message}');
          if (kDebugMode) print('❌ Banner Ad Failed: $error');
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
  }

  /// インタースティシャル広告を読み込み（最適化：ステージ完了時）
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _getAdUnitId('interstitial'),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          state = state.copyWith(isInterstitialLoaded: true);
          if (kDebugMode) print('✅ Interstitial Ad Loaded');
        },
        onAdFailedToLoad: (error) {
          state = state.copyWith(error: 'インタースティシャル広告読み込み失敗: ${error.message}');
          if (kDebugMode) print('❌ Interstitial Ad Failed: $error');
        },
      ),
    );
  }

  /// リワード広告を読み込み（最適化：ボーナスコイン獲得時）
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _getAdUnitId('rewarded'),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          state = state.copyWith(isRewardedLoaded: true);
          if (kDebugMode) print('✅ Rewarded Ad Loaded');
        },
        onAdFailedToLoad: (error) {
          state = state.copyWith(error: 'リワード広告読み込み失敗: ${error.message}');
          if (kDebugMode) print('❌ Rewarded Ad Failed: $error');
        },
      ),
    );
  }

  /// バナー広告を表示（ホーム画面下部用）
  BannerAd? getBannerAd() {
    return (_bannerAd != null && state.isBannerLoaded) ? _bannerAd : null;
  }

  /// インタースティシャル広告を表示（ステージ完了後）
  Future<void> showInterstitialAd() async {
    if (!FeatureFlags.adsEnabled || _interstitialAd == null) return;

    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd(); // 次の広告を読み込み
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          if (kDebugMode) print('❌ Interstitial failed to show: $error');
          _loadInterstitialAd();
        },
      );

      await _interstitialAd!.show();
    } catch (e) {
      if (kDebugMode) print('Error showing interstitial: $e');
    }
  }

  /// リワード広告を表示（コイン獲得用）
  Future<void> showRewardedAd({
    required Function(RewardItem) onUserEarnedReward,
  }) async {
    if (!FeatureFlags.adsEnabled || _rewardedAd == null) return;

    try {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadRewardedAd(); // 次の広告を読み込み
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          if (kDebugMode) print('❌ Rewarded ad failed to show: $error');
          _loadRewardedAd();
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onUserEarnedReward(reward);
        },
      );
    } catch (e) {
      if (kDebugMode) print('Error showing rewarded ad: $e');
    }
  }

  /// 広告 ID を取得（テスト/本番）
  String _getAdUnitId(String type) {
    // デバッグモードまたはテスト中の場合はテスト広告を使用
    if (kDebugMode || _shouldUseTestAds()) {
      return _getTestAdUnitId(type);
    }

    // 本番広告
    return _getProductionAdUnitId(type);
  }

  /// 本番広告 ID を取得
  String _getProductionAdUnitId(String type) {
    switch (type) {
      case 'banner':
        return defaultTargetPlatform == TargetPlatform.android
            ? AdUnitIds.androidBannerId
            : AdUnitIds.iosBannerId;
      case 'interstitial':
        return defaultTargetPlatform == TargetPlatform.android
            ? AdUnitIds.androidInterstitialId
            : AdUnitIds.iosInterstitialId;
      case 'rewarded':
        return defaultTargetPlatform == TargetPlatform.android
            ? AdUnitIds.androidRewardedId
            : AdUnitIds.iosRewardedId;
      default:
        return '';
    }
  }

  /// テスト広告 ID を取得
  String _getTestAdUnitId(String type) {
    switch (type) {
      case 'banner':
        return 'ca-app-pub-3940256099942544/6300978111';
      case 'interstitial':
        return 'ca-app-pub-3940256099942544/1033173712';
      case 'rewarded':
        return 'ca-app-pub-3940256099942544/5224354917';
      default:
        return '';
    }
  }

  /// テスト広告を使用すべきか判定
  bool _shouldUseTestAds() {
    // 開発環境またはテストデバイスの場合
    return kDebugMode;
  }

  /// クリーンアップ
  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}

/// 広告 Provider
final adsProvider = StateNotifierProvider<AdsNotifier, AdsState>(
  (ref) => AdsNotifier(),
);

/// バナー広告用 Provider
final bannerAdProvider = Provider<BannerAd?>((ref) {
  final adsNotifier = ref.read(adsProvider.notifier);
  return adsNotifier.getBannerAd();
});
