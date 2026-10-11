import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../utils/mock_data.dart';

class AdFrequencyController {
  static final AdFrequencyController _instance =
      AdFrequencyController._internal();
  factory AdFrequencyController() => _instance;
  AdFrequencyController._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Remote Config Keys
  static const String _keyMaxAdsPerSession = 'max_ads_per_session';
  static const String _keyAdIntervalMinutes = 'ad_interval_minutes';

  // Local state
  int _adsSeenThisSession = 0;
  DateTime? _lastAdShownAt;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setDefaults(<String, dynamic>{
        _keyMaxAdsPerSession: 5,
        _keyAdIntervalMinutes: 3,
      });

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('AdFrequencyController: Remote Config init failed: $e');
    }
  }

  int get maxAdsPerSession => _remoteConfig.getInt(_keyMaxAdsPerSession);
  int get adIntervalMinutes => _remoteConfig.getInt(_keyAdIntervalMinutes);

  bool get shouldShowAd {
    // Check Supabase feature toggle
    final bool adsEnabled = MockData().adsEnabled;

    if (!adsEnabled) return false;

    // 1. Check session limit
    if (_adsSeenThisSession >= maxAdsPerSession) {
      debugPrint(
        'AdFrequencyController: Session limit reached ($_adsSeenThisSession >= $maxAdsPerSession). Bypassing ad.',
      );
      return false;
    }

    // 2. Check time interval
    if (_lastAdShownAt != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShownAt!);
      if (timeSinceLastAd.inMinutes < adIntervalMinutes) {
        debugPrint(
          'AdFrequencyController: Interval not reached (${timeSinceLastAd.inMinutes} < $adIntervalMinutes min). Bypassing ad.',
        );
        return false;
      }
    }

    return true;
  }

  void recordAdShown() {
    _adsSeenThisSession++;
    _lastAdShownAt = DateTime.now();
    debugPrint(
      'AdFrequencyController: Ad recorded. Session count: $_adsSeenThisSession',
    );
  }

  // Optional: Persistent daily limit if needed
  // For now, we use session-based as per "user traffic condition" hint
}
