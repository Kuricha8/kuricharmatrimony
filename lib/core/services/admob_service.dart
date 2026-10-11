import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  AdMobService._();
  static final AdMobService instance = AdMobService._();

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  bool get isRewardedAdReady => _isRewardedAdReady;

  // Test Rewarded Ad Unit ID
  static const String testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  void loadRewardedAd({String? adUnitId}) {
    if (kIsWeb) {
      _isRewardedAdReady = true;
      return;
    }

    try {
      RewardedAd.load(
        adUnitId: adUnitId ?? testRewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
            debugPrint('Rewarded ad loaded successfully.');
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad failed to load: $error');
            _isRewardedAdReady = false;
            _rewardedAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('AdMob load error: $e');
      _isRewardedAdReady = false;
    }
  }

  void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdDismissed,
  }) {
    if (kIsWeb || _rewardedAd == null || !_isRewardedAdReady) {
      // Fallback for web or unready ad
      onUserEarnedReward();
      onAdDismissed?.call();
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdReady = false;
        loadRewardedAd();
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Failed to show rewarded ad: $error');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdReady = false;
        onUserEarnedReward();
        onAdDismissed?.call();
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        onUserEarnedReward();
      },
    );
  }
}
