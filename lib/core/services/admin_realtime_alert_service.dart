import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/app_toast.dart';
import '../utils/haptic_helper.dart';

class AdminRealtimeAlertService {
  AdminRealtimeAlertService._();
  static final AdminRealtimeAlertService instance =
      AdminRealtimeAlertService._();

  RealtimeChannel? _adminProfilesChannel;
  RealtimeChannel? _adminEditsChannel;
  RealtimeChannel? _adminPaymentsChannel;
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Starts listening for admin live activities if the current user is an admin
  void startListening(bool isAdmin) {
    if (!isAdmin) return;

    stopListening();

    try {
      final client = Supabase.instance.client;

      // 1. Listen for New Registrations & Aadhaar Uploads on kurichiyar_profiles
      _adminProfilesChannel = client
          .channel('admin_live_profiles_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'kurichiyar_profiles',
            callback: (payload) {
              final newRecord = payload.newRecord;
              final name =
                  newRecord['name'] ?? newRecord['full_name'] ?? 'പുതിയ യൂസർ';
              _triggerAdminAlert(
                '🔔 പുതിയ രജിസ്ട്രേഷൻ',
                '$name അക്കൗണ്ട് സൃഷ്ടിച്ചു. അപ്രൂവലിനായി വെയ്റ്റ് ചെയ്യുന്നു.',
              );
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'kurichiyar_profiles',
            callback: (payload) {
              final oldRec = payload.oldRecord;
              final newRec = payload.newRecord;
              if (oldRec['aadhaar_verified'] != true &&
                  newRec['aadhaar_verified'] == true) {
                final name =
                    newRec['name'] ?? newRec['full_name'] ?? 'ഉപയോക്താവ്';
                _triggerAdminAlert(
                  '📜 ആധാർ റെക്കോർഡ് അപ്‌ലോഡ്',
                  '$name ആധാർ വെരിഫിക്കേഷൻ സമർപ്പിച്ചു.',
                );
              }
            },
          )
          .subscribe();

      // 2. Listen for Profile Edit Requests
      _adminEditsChannel = client
          .channel('admin_live_edits_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'profile_edit_requests',
            callback: (payload) {
              final newRecord = payload.newRecord;
              final name = newRecord['user_name'] ?? 'അംഗം';
              _triggerAdminAlert(
                '✏️ തിരുത്തൽ അപേക്ഷ',
                '$name പ്രൊഫൈൽ വിവരങ്ങൾ തിരുത്താൻ അപേക്ഷ നൽകി.',
              );
            },
          )
          .subscribe();

      // 3. Listen for Cashfree Payments
      _adminPaymentsChannel = client
          .channel('admin_live_payments_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'user_payments',
            callback: (payload) {
              final newRecord = payload.newRecord;
              final orderId = newRecord['cashfree_order_id'] ?? 'Order';
              final amount = newRecord['amount'] ?? 29;
              _triggerAdminAlert(
                '💳 ₹$amount അടച്ചു!',
                'ഓർഡർ ID: $orderId വിജയകരമായി പൂർത്തിയായി.',
              );
            },
          )
          .subscribe();

      debugPrint(
        'AdminRealtimeAlertService: Subscribed for Admin Live Activity Alerts',
      );
    } catch (e) {
      debugPrint('Error starting AdminRealtimeAlertService: $e');
    }
  }

  void stopListening() {
    final client = Supabase.instance.client;
    if (_adminProfilesChannel != null) {
      client.removeChannel(_adminProfilesChannel!);
      _adminProfilesChannel = null;
    }
    if (_adminEditsChannel != null) {
      client.removeChannel(_adminEditsChannel!);
      _adminEditsChannel = null;
    }
    if (_adminPaymentsChannel != null) {
      client.removeChannel(_adminPaymentsChannel!);
      _adminPaymentsChannel = null;
    }
  }

  void _triggerAdminAlert(String title, String subtitle) {
    // 1. Play instant audible ping/chime sound
    try {
      _audioPlayer.stop();
      _audioPlayer.play(AssetSource('sounds/alert_sound.wav')).catchError((_) {
        _audioPlayer
            .play(AssetSource('sounds/general_notification.wav'))
            .catchError((_) {});
      });
    } catch (_) {}

    // 2. Heavy Haptic Vibration
    HapticHelper.heavyImpact();
    HapticFeedback.vibrate();

    // 3. Top Banner Toast Alert in Admin Dashboard
    AppToast.showInfo(title, subtitle);
  }
}
