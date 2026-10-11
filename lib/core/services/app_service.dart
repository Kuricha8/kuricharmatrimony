import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'in_app_update_service.dart';

class AppService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // 1. പുഷ് നോട്ടിഫിക്കേഷൻ പെർമിഷനും ചാനൽ സബ്സ്ക്രിപ്ഷനും
  static Future<void> initializeFCM({String? tharavaduId}) async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // മുഴുവൻ ആളുകൾക്കുമുള്ള ചാനൽ
        await _messaging.subscribeToTopic('all_users');
        debugPrint("Subscribed to all_users topic successfully!");

        // ഉപയോക്താവിന്റെ പ്രത്യേക തറവാട് ചാനൽ
        if (tharavaduId != null && tharavaduId.isNotEmpty) {
          await _messaging.subscribeToTopic('clan_$tharavaduId');
          debugPrint("Subscribed to clan_$tharavaduId topic successfully!");
        }
      }
    } catch (e) {
      debugPrint("initializeFCM error: $e");
    }
  }

  // 2. അഡ്മിൻ പാനലിൽ നിന്നുള്ള പുതിയ APK ഉണ്ടോയെന്ന് നോക്കി ഇൻസ്റ്റാൾ ചെയ്യൽ (Telegram-Style Non-blocking)
  static Future<void> checkDirectUpdate(BuildContext context) async {
    try {
      await InAppUpdateService.instance.checkForUpdates(context);
    } catch (e) {
      debugPrint("Update check error: $e");
    }
  }
}
