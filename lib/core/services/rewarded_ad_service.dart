import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_status_service.dart';

class RewardedAdService {
  static final RewardedAdService instance = RewardedAdService._internal();
  RewardedAdService._internal();

  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isShowingAd = false;

  // Google Test Ad Unit ID for Rewarded Ads
  final String _adUnitId = 'ca-app-pub-3940256099942544/5224354917';

  void loadAd() {
    // Zero network calls if user is premium
    if (AdStatusService.instance.isPremiumUser) {
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _isAdLoaded = false;
      return;
    }

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded ad loaded.');
          _rewardedAd = ad;
          _isAdLoaded = true;

          _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isAdLoaded = false;
              _isShowingAd = false;
              // Preload next ad
              loadAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Failed to show rewarded ad: $error');
              ad.dispose();
              _rewardedAd = null;
              _isAdLoaded = false;
              _isShowingAd = false;
              loadAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _isAdLoaded = false;
        },
      ),
    );
  }

  /// Attempts to show the rewarded ad.
  /// If the user is premium, [onRewardEarned] is fired immediately without showing an ad.
  void showAdIfAvailable({
    required VoidCallback onRewardEarned,
    required VoidCallback onAdFailed,
  }) {
    if (AdStatusService.instance.isPremiumUser) {
      // Premium users bypass the ad completely and instantly earn the reward!
      onRewardEarned();
      return;
    }

    if (!_isAdLoaded || _rewardedAd == null) {
      debugPrint('Rewarded ad not available yet.');
      onAdFailed();
      loadAd();
      return;
    }

    if (_isShowingAd) return;
    _isShowingAd = true;

    _rewardedAd?.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
        debugPrint(
          'User earned reward: ${rewardItem.amount} ${rewardItem.type}',
        );
        onRewardEarned();
      },
    );
  }
}
