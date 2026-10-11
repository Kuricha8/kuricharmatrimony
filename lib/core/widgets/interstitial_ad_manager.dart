import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_frequency_controller.dart';
import '../services/ad_status_service.dart';

class InterstitialAdManager {
  static final InterstitialAdManager _instance =
      InterstitialAdManager._internal();
  factory InterstitialAdManager() => _instance;
  InterstitialAdManager._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  // Test Interstitial Ad Unit ID
  final String _adUnitId = 'ca-app-pub-3940256099942544/1033173712';

  void loadAd() {
    final isPremiumUser = AdStatusService.instance.isPremiumUser;
    if (isPremiumUser) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _isAdLoaded = false;
      return;
    }

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded.');
          _interstitialAd = ad;
          _isAdLoaded = true;

          _interstitialAd?.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _interstitialAd = null;
                  _isAdLoaded = false;
                  // Preload the next ad
                  loadAd();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  ad.dispose();
                  _interstitialAd = null;
                  _isAdLoaded = false;
                  loadAd();
                },
              );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _interstitialAd = null;
          _isAdLoaded = false;
        },
      ),
    );
  }

  /// Shows the interstitial ad if loaded and the user is on the Free Tier.
  /// Always executes the [onComplete] callback after the ad is dismissed or immediately if no ad is shown.
  void showAdIfAvailable({required VoidCallback onComplete}) {
    final isPremiumUser = AdStatusService.instance.isPremiumUser;
    // Check dynamic frequency controller
    if (isPremiumUser || !AdFrequencyController().shouldShowAd) {
      onComplete();
      return;
    }

    if (!_isAdLoaded || _interstitialAd == null) {
      onComplete();
      return;
    }

    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        AdFrequencyController().recordAdShown();
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
        onComplete();
        loadAd(); // Preload next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
        onComplete();
        loadAd(); // Preload next
      },
    );

    _interstitialAd?.show();
  }
}
