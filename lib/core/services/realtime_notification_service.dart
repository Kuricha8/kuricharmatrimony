import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'notification_manager.dart';
import '../utils/app_toast.dart';
import '../utils/haptic_helper.dart';

class RealtimeNotificationService {
  RealtimeNotificationService._();
  static final RealtimeNotificationService instance =
      RealtimeNotificationService._();

  RealtimeChannel? _userNotificationChannel;
  StreamSubscription? _dbNotificationStream;
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Starts listening for realtime user notifications from Supabase
  void startListening(String userId) {
    if (userId.isEmpty || userId == 'guest') return;

    stopListening();

    try {
      // 1. Supabase Realtime Stream for user_notifications
      _dbNotificationStream = Supabase.instance.client
          .from('user_notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen(
            (data) {
              if (data.isNotEmpty) {
                final latest = data.last;
                final isRead = latest['is_read'] == true;
                if (!isRead) {
                  _triggerNotificationAlert(latest);
                }
              }
            },
            onError: (err) {
              debugPrint('Realtime user_notifications stream error: $err');
            },
          );

      // 2. Realtime Broadcast Channel for direct instant pushes
      _userNotificationChannel = Supabase.instance.client
          .channel('realtime_user_notif_$userId')
          .onBroadcast(
            event: 'new_notification',
            callback: (payload) {
              _triggerNotificationAlert(payload);
            },
          )
          .subscribe();

      debugPrint('RealtimeNotificationService: Subscribed for user $userId');
    } catch (e) {
      debugPrint('Error starting RealtimeNotificationService: $e');
    }
  }

  void stopListening() {
    _dbNotificationStream?.cancel();
    _dbNotificationStream = null;
    if (_userNotificationChannel != null) {
      Supabase.instance.client.removeChannel(_userNotificationChannel!);
      _userNotificationChannel = null;
    }
  }

  void _triggerNotificationAlert(Map<String, dynamic> notif) {
    final String title = (notif['title'] ?? 'പുതിയ അറിയിപ്പ്').toString();
    final String body = (notif['body'] ?? notif['message'] ?? '').toString();
    final String type = (notif['type'] ?? 'general').toString().toLowerCase();

    // Sound & Vibration
    HapticHelper.heavyImpact();
    HapticFeedback.vibrate();

    try {
      _audioPlayer.stop();
      _audioPlayer
          .play(AssetSource('sounds/general_notification.wav'))
          .catchError((_) {});
    } catch (_) {}

    // Show Floating Toast Banner
    if (type.contains('approval') || type.contains('approved')) {
      AppToast.showSuccess(title, body);
    } else if (type.contains('reject')) {
      AppToast.showError(title, body);
    } else if (type.contains('match')) {
      AppToast.showSuccess('🎉 $title', body);
    } else {
      AppToast.showInfo(title, body);
    }

    // Trigger Local System Notification with max vibration pattern [0, 250, 250, 250]
    NotificationManager.showNotification(
      title: title,
      body: body,
      type: type,
      payload: notif['sender_id']?.toString() ?? notif['payload']?.toString(),
    );
  }
}
