import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

class TrafficAnalyticsService {
  TrafficAnalyticsService._internal();
  static final TrafficAnalyticsService instance =
      TrafficAnalyticsService._internal();

  RealtimeChannel? _presenceChannel;
  Timer? _heartbeatTimer;
  Timer? _screenTimer;

  String? _deviceId;
  String? _deviceModel;
  String? _currentScreen;
  DateTime? _screenStartTime;

  final List<Map<String, dynamic>> _screenBreadcrumbs = [];

  String? get deviceId => _deviceId;
  String? get deviceModel => _deviceModel;
  String? get currentScreen => _currentScreen;
  List<Map<String, dynamic>> get breadcrumbs =>
      List.unmodifiable(_screenBreadcrumbs);

  /// Initialize tracking for registered or guest users
  Future<void> init() async {
    try {
      await _initDeviceInfo();
      await _registerSession();
      _startPresence();
      _startHeartbeat();
    } catch (e) {
      debugPrint('TrafficAnalyticsService init error: $e');
    }
  }

  Future<void> _initDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        _deviceId = 'web_${webInfo.vendor}_${webInfo.userAgent.hashCode}';
        _deviceModel = 'Web Browser (${webInfo.browserName.name})';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = 'android_${androidInfo.id}';
        _deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = 'ios_${iosInfo.identifierForVendor ?? iosInfo.model}';
        _deviceModel = 'Apple ${iosInfo.model}';
      } else {
        _deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
        _deviceModel = 'Desktop / Unknown';
      }
    } catch (e) {
      _deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      _deviceModel = 'Generic Device';
    }
  }

  Future<void> _registerSession() async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser != null) {
      // 1. Registered User Session
      try {
        final profileRes = await supabase
            .from('kurichiyar_profiles')
            .select('name, phone, house_name, district')
            .eq('id', currentUser.id)
            .maybeSingle();

        final name = profileRes?['name'] ?? 'Matrimony Member';
        final phone = profileRes?['phone'] ?? currentUser.email ?? '';
        final location = profileRes?['district'] ?? 'Wayanad, Kerala';

        await supabase.from('user_sessions').insert({
          'user_id': currentUser.id,
          'user_name': name,
          'user_phone': phone,
          'location': location,
          'device_model': _deviceModel,
          'is_online': true,
          'last_active': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Error inserting user_session: $e');
      }
    } else if (_deviceId != null) {
      // 2. Guest Visitor Analytics
      try {
        final existing = await supabase
            .from('guest_analytics')
            .select('id, total_session_seconds')
            .eq('device_id', _deviceId!)
            .maybeSingle();

        if (existing != null) {
          await supabase
              .from('guest_analytics')
              .update({
                'last_active': DateTime.now().toIso8601String(),
                'is_online': true,
                'device_model': _deviceModel,
              })
              .eq('device_id', _deviceId!);
        } else {
          await supabase.from('guest_analytics').insert({
            'device_id': _deviceId,
            'device_model': _deviceModel,
            'first_seen': DateTime.now().toIso8601String(),
            'last_active': DateTime.now().toIso8601String(),
            'is_online': true,
            'location': 'Kerala, India',
          });
        }
      } catch (e) {
        debugPrint('Error inserting guest_analytics: $e');
      }
    }
  }

  void _startPresence() {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      _presenceChannel = supabase.channel('traffic_analytics_presence');
      _presenceChannel!.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _presenceChannel!.track({
            'user_id': currentUser?.id,
            'device_id': _deviceId,
            'device_model': _deviceModel,
            'is_guest': currentUser == null,
            'online_at': DateTime.now().toIso8601String(),
            'current_screen': _currentScreen ?? 'Home',
          });
        }
      });
    } catch (e) {
      debugPrint('Realtime presence subscribe error: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 45), (_) async {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      final now = DateTime.now().toIso8601String();

      try {
        if (currentUser != null) {
          await supabase
              .from('user_sessions')
              .update({'last_active': now, 'is_online': true})
              .eq('user_id', currentUser.id);
        } else if (_deviceId != null) {
          await supabase
              .from('guest_analytics')
              .update({'last_active': now, 'is_online': true})
              .eq('device_id', _deviceId!);
        }

        if (_presenceChannel != null) {
          _presenceChannel!.track({
            'user_id': currentUser?.id,
            'device_id': _deviceId,
            'device_model': _deviceModel,
            'is_guest': currentUser == null,
            'online_at': now,
            'current_screen': _currentScreen ?? 'Home',
          });
        }
      } catch (e) {
        debugPrint('Heartbeat error: $e');
      }
    });
  }

  /// Track when a user navigates to a new screen
  void trackScreenView(String screenName) {
    if (_currentScreen == screenName) return;

    final now = DateTime.now();

    // Log time spent on previous screen
    if (_currentScreen != null && _screenStartTime != null) {
      final durationSec = now.difference(_screenStartTime!).inSeconds;
      if (durationSec > 1) {
        _logPageView(_currentScreen!, durationSec);
      }
    }

    _currentScreen = screenName;
    _screenStartTime = now;

    // Add to local breadcrumbs
    _screenBreadcrumbs.add({
      'screen': screenName,
      'timestamp': now.toIso8601String(),
    });
    if (_screenBreadcrumbs.length > 20) {
      _screenBreadcrumbs.removeAt(0);
    }
  }

  Future<void> _logPageView(String screenName, int durationSec) async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      await supabase.from('screen_page_views').insert({
        'user_id': currentUser?.id,
        'device_id': _deviceId,
        'screen_name': screenName,
        'time_spent_seconds': durationSec,
      });

      // Update total session seconds for guest
      if (currentUser == null && _deviceId != null) {
        await supabase
            .rpc(
              'increment_guest_time',
              params: {
                'target_device_id': _deviceId,
                'seconds_to_add': durationSec,
              },
            )
            .catchError((_) async {
              // Fallback direct update
              final current = await supabase
                  .from('guest_analytics')
                  .select('total_session_seconds')
                  .eq('device_id', _deviceId!)
                  .maybeSingle();

              final prevSec = current?['total_session_seconds'] as int? ?? 0;
              await supabase
                  .from('guest_analytics')
                  .update({'total_session_seconds': prevSec + durationSec})
                  .eq('device_id', _deviceId!);
            });
      }
    } catch (e) {
      debugPrint('Error logging page view: $e');
    }
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _screenTimer?.cancel();
    _presenceChannel?.unsubscribe();
  }
}
