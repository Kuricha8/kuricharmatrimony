import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'fcm_http_helper.dart';
import 'matching_service.dart';
import '../models/models.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import '../../main.dart' show flutterLocalNotificationsPlugin;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("FCM_BACKGROUND: Received message: ${message.messageId}");

  final type = message.data['type']?.toString().toUpperCase();
  if (type == 'CALL' ||
      type == 'INCOMING_CALL' ||
      type == 'AUDIO_CALL' ||
      type == 'VIDEO_CALL') {
    try {
      final callId =
          message.data['call_id'] ??
          message.data['id'] ??
          'call_${DateTime.now().millisecondsSinceEpoch}';
      final callType = (message.data['call_type'] ?? message.data['type'])
          ?.toString()
          .toUpperCase();
      final isVideo = callType == 'VIDEO' || callType == 'VIDEO_CALL';

      final CallKitParams params = CallKitParams(
        id: callId,
        nameCaller:
            message.data['caller_name'] ?? 'കുറിച്ച്യർ മാട്രിമോണി (Official)',
        appName: 'Kurichiyar Matrimony',
        avatar: 'assets/images/logo_kym.png',
        handle: 'കമ്മ്യൂണിറ്റി സുരക്ഷിത കോൾ',
        type: isVideo ? 1 : 0,
        duration: 35000,
        textAccept: 'സ്വീകരിക്കുക',
        textDecline: 'കട്ട് ചെയ്യുക',
        extra: <String, dynamic>{
          'call_id': callId,
          'caller_id': message.data['caller_id'],
        },
      );

      await FlutterCallkitIncoming.showCallkitIncoming(params);
    } catch (e) {
      debugPrint('CallKit background alert error: $e');
    }
  }

  final soundName = message.data['sound_name'] ?? message.data['tone_category'];

  try {
    final player = AudioPlayer();
    if (soundName != null) {
      await player.play(AssetSource('sounds/$soundName.wav')).catchError((_) {
        player.play(AssetSource('sounds/general_notification.wav'));
      });
    } else {
      await player.play(AssetSource('sounds/general_notification.wav'));
    }
  } catch (e) {
    debugPrint("FCM_BACKGROUND Audio Error: $e");
  }

  NotificationManager.showNotification(
    title:
        message.notification?.title ?? message.data['title'] ?? 'Notification',
    body: message.notification?.body ?? message.data['body'] ?? '',
    type: message.data['type'],
    payload: message.data['sender_id'] ?? message.data['match_id'],
    soundName: soundName,
  );
}

class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  static String? currentActiveChatId;

  /// Initialize FCM permissions, Android Notification Channel, and foreground listener.
  Future<void> init() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );

      const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
        'kurichiyar_chat_channel',
        'ചാറ്റ് സന്ദേശങ്ങൾ (Chat Messages)',
        description: 'തത്സമയ ചാറ്റ് സന്ദേശങ്ങൾക്കുള്ള അറിയിപ്പുകൾ',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      const AndroidNotificationChannel matchesChannel =
          AndroidNotificationChannel(
            'kurichiyar_matches_channel',
            'പൊരുത്തങ്ങളും അംഗീകാരങ്ങളും (Matches & Approvals)',
            description: 'പുതിയ താല്പര്യങ്ങൾ, അഡ്മിൻ കണക്റ്റ് അപ്രൂവലുകൾ',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          );

      const AndroidNotificationChannel paymentsChannel =
          AndroidNotificationChannel(
            'kurichiyar_payments_channel',
            'ഇടപാടുകളും രസീതുകളും (Payments & Escrow)',
            description: 'ഫീസ് അടയ്ക്കൽ, എസ്ക്രോ രസീതുകൾ, ഇടപാട് വിവരങ്ങൾ',
            importance: Importance.defaultImportance,
            playSound: true,
            enableVibration: true,
          );

      const AndroidNotificationChannel securityChannel =
          AndroidNotificationChannel(
            'kurichiyar_security_channel',
            'സുരക്ഷാ മുന്നറിയിപ്പുകൾ (Security & Account Alerts)',
            description:
                'ആന്റി-ലീക്ക് പെനാൽറ്റി, അക്കൗണ്ട് ലോഗിൻ മുന്നറിയിപ്പുകൾ',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          );

      const AndroidNotificationChannel highImportanceChannel =
          AndroidNotificationChannel(
            'high_importance_channel',
            'പ്രധാന അറിയിപ്പുകൾ (High Importance)',
            description: 'പുതിയ ഉപയോക്താക്കൾ, അപ്രൂവലുകൾ എന്നിവയ്ക്കുള്ള ചാനൽ',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          );

      const AndroidNotificationChannel appUpdatesChannel =
          AndroidNotificationChannel(
            'app_updates',
            'App Updates (ആപ്പ് അപ്ഡേറ്റുകൾ)',
            description: 'പുതിയ ആപ്പ് അപ്ഡേറ്റുകൾക്കുള്ള അറിയിപ്പുകൾ',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          );

      const AndroidNotificationChannel generalAnnouncementsChannel =
          AndroidNotificationChannel(
            'general_announcements',
            'General Announcements (പൊതു അറിയിപ്പുകൾ)',
            description: 'കമ്മ്യൂണിറ്റി വാർത്തകളും പ്രധാന അറിയിപ്പുകളും',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          );

      const AndroidNotificationChannel announcementsChannel =
          AndroidNotificationChannel(
            'kurichiyar_announcements_channel',
            'പൊതു അറിയിപ്പുകൾ (General Announcements)',
            description: 'കമ്മ്യൂണിറ്റി വാർത്തകളും ആപ്പ് അപ്ഡേറ്റുകളും',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          );

      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(highImportanceChannel);
        await androidPlugin.createNotificationChannel(chatChannel);
        await androidPlugin.createNotificationChannel(matchesChannel);
        await androidPlugin.createNotificationChannel(paymentsChannel);
        await androidPlugin.createNotificationChannel(securityChannel);
        await androidPlugin.createNotificationChannel(announcementsChannel);
        await androidPlugin.createNotificationChannel(appUpdatesChannel);
        await androidPlugin.createNotificationChannel(generalAnnouncementsChannel);
      }

      // Enable heads-up banner display & sound when app is in foreground
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      // Listen for foreground notifications and display high-importance local alert
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          "FCM_DEBUG: Received FOREGROUND message: ${message.notification?.title}",
        );

        final senderId =
            message.data['sender_id']?.toString() ??
            message.data['userId']?.toString();
        final isCurrentChat =
            senderId != null && senderId == currentActiveChatId;

        // --- AUDIO & HAPTIC PLAYBACK FOR HEADS-UP ALERT ---
        if (!isCurrentChat) {
          try {
            final soundName =
                message.data['sound_name'] ?? message.data['tone_category'];
            final player = AudioPlayer();
            if (soundName != null) {
              player.play(AssetSource('sounds/$soundName.wav')).catchError((_) {
                player.play(AssetSource('sounds/general_notification.wav'));
              });
            } else {
              player.play(AssetSource('sounds/general_notification.wav'));
            }
            HapticFeedback.mediumImpact();
          } catch (e) {
            debugPrint("FCM_DEBUG: Audio fallback failed: $e");
          }
        }
        // ----------------------------------

        final title =
            message.notification?.title ??
            message.data['title'] ??
            'പുതിയ അറിയിപ്പ്';
        final body = message.notification?.body ?? message.data['body'] ?? '';
        final notifId =
            message.notification?.hashCode ?? message.hashCode;

        flutterLocalNotificationsPlugin.show(
          id: notifId,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              highImportanceChannel.id,
              highImportanceChannel.name,
              channelDescription: highImportanceChannel.description,
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              icon: '@mipmap/ic_launcher',
              styleInformation: BigTextStyleInformation(body, contentTitle: title),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data['sender_id'] ?? message.data['match_id'] ?? message.data['userId'],
        );
      });
      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Listen for messages opened from background (when user taps notification)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM_NOTIFICATION_TAP: ${message.notification?.title}');
        final title =
            message.notification?.title ??
            message.data['title'] ??
            'Notification';
        final body = message.notification?.body ?? message.data['body'] ?? '';
        showNotification(title: title, body: body);
      });

      // Refresh token listener
      FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) async {
        debugPrint('FCM_TOKEN_REFRESHED: $newToken');
        await registerFCMToken('');
      });

      // Auto-subscribe all users (including guests) to global broadcast topic
      await FirebaseMessaging.instance.subscribeToTopic('all_users');
      debugPrint('FCM_TOPIC_SUBSCRIPTION: Subscribed to all_users topic');

      listenForRealtimeInterests();
    } catch (e) {
      debugPrint('NotificationManager init error: $e');
    }
  }

  RealtimeChannel? _interestRealtimeChannel;

  void listenForRealtimeInterests() {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null) return;

    try {
      _interestRealtimeChannel = Supabase.instance.client.channel(
        'user_interests_$me',
      );
      _interestRealtimeChannel!
          .onBroadcast(
            event: 'incoming_interest',
            callback: (payload) async {
              final String senderName =
                  payload['sender_name'] ?? 'ഒരു ഉപയോക്താവ്';
              final String titleText = payload['type'] == 'mutual'
                  ? '🎉 പരസ്പര പൊരുത്തം!'
                  : '❤️ പുതിയ താല്പര്യം ലഭിച്ചു!';

              // 1. Cross-Device Heavy Haptic Vibration
              HapticFeedback.heavyImpact();

              // 2. Cross-Device Audio Tone Playback
              try {
                final player = AudioPlayer();
                await player
                    .play(AssetSource('sounds/general_notification.wav'))
                    .catchError((_) {});
              } catch (_) {}

              // 3. Local High Importance Notification
              showNotification(
                title: titleText,
                body: '$senderName നിങ്ങൾക്ക് താല്പര്യം അറിയിച്ചിട്ടുണ്ട്.',
                type: 'interest',
              );
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error subscribing to realtime interest channel: $e');
    }
  }

  /// Displays a high-importance local notification directly on device
  static Future<void> showNotification({
    required String title,
    required String body,
    String? type,
    String? payload,
    String? soundName,
    int? id,
  }) async {
    final isMatch = type == 'new_match' || type == 'NEW_MATCH';
    final isMessage =
        type == 'new_message' || type == 'chat' || type == 'CHAT_MESSAGE';

    List<AndroidNotificationAction>? actions;
    if (isMatch) {
      actions = [
        const AndroidNotificationAction(
          'view_match',
          'View Match',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'chat',
          'Chat',
          showsUserInterface: true,
        ),
      ];
    } else if (isMessage) {
      actions = [
        const AndroidNotificationAction(
          'quick_reply',
          'Quick Reply',
          showsUserInterface: true,
          inputs: [AndroidNotificationActionInput(label: 'Type a reply...')],
        ),
        const AndroidNotificationAction(
          'open_chat',
          'Open Chat',
          showsUserInterface: true,
        ),
      ];
    }

    final isUpdate =
        type == 'update' || type == 'app_update' || type == 'app_updates';
    final isAnnouncement =
        type == 'announcement' ||
        type == 'general' ||
        type == 'broadcast' ||
        type == 'general_announcements';
    final isPayment =
        type == 'payment' ||
        type == 'escrow' ||
        type == 'billing' ||
        type == 'account_billing';
    final isSecurity =
        type == 'security' || type == 'penalty' || type == 'alert';

    final isApprovalOrRegistration =
        type == 'approval' ||
        type == 'registration' ||
        type == 'new_user' ||
        type == 'new_registration' ||
        type == 'high_importance';

    final String channelId = isMessage
        ? 'kurichiyar_chat_channel'
        : (isMatch || type == 'interest')
        ? 'kurichiyar_matches_channel'
        : isApprovalOrRegistration
        ? 'high_importance_channel'
        : isUpdate
        ? 'app_updates'
        : isAnnouncement
        ? 'general_announcements'
        : isPayment
        ? 'kurichiyar_payments_channel'
        : isSecurity
        ? 'kurichiyar_security_channel'
        : 'high_importance_channel';

    final String channelName = isMessage
        ? 'ചാറ്റ് സന്ദേശങ്ങൾ (Chat Messages)'
        : (isMatch || type == 'interest')
        ? 'പൊരുത്തങ്ങളും അംഗീകാരങ്ങളും (Matches & Approvals)'
        : isApprovalOrRegistration
        ? 'പ്രധാന അറിയിപ്പുകൾ (High Importance)'
        : isUpdate
        ? 'App Updates (ആപ്പ് അപ്ഡേറ്റുകൾ)'
        : isAnnouncement
        ? 'General Announcements (പൊതു അറിയിപ്പുകൾ)'
        : isPayment
        ? 'ഇടപാടുകളും രസീതുകളും (Payments & Escrow)'
        : isSecurity
        ? 'സുരക്ഷാ മുന്നറിയിപ്പുകൾ (Security & Account Alerts)'
        : 'പ്രധാന അറിയിപ്പുകൾ (High Importance)';

    final Importance notificationImportance = (isMessage ||
            isApprovalOrRegistration ||
            channelId == 'high_importance_channel')
        ? Importance.max
        : (isMatch ||
                type == 'interest' ||
                isSecurity ||
                isUpdate ||
                isAnnouncement)
        ? Importance.high
        : Importance.defaultImportance;

    final Priority notificationPriority = (isMessage ||
            isApprovalOrRegistration ||
            channelId == 'high_importance_channel')
        ? Priority.high
        : (isMatch ||
                type == 'interest' ||
                isSecurity ||
                isUpdate ||
                isAnnouncement)
        ? Priority.high
        : isPayment
        ? Priority.defaultPriority
        : Priority.low;

    final soundResource = soundName != null
        ? RawResourceAndroidNotificationSound(soundName.replaceAll('.mp3', ''))
        : (isMatch
              ? const RawResourceAndroidNotificationSound('match_sound')
              : isMessage
              ? const RawResourceAndroidNotificationSound('chat_pop')
              : null);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'പുതിയ ഉപയോക്താക്കൾ, അപ്രൂവലുകൾ എന്നിവയ്ക്കുള്ള ചാനൽ',
          importance: notificationImportance,
          priority: notificationPriority,
          playSound: true,
          sound: soundResource,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          audioAttributesUsage: AudioAttributesUsage.notification,
          enableLights: true,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(body, contentTitle: title),
          actions: actions,
        );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    try {
      final notificationId =
          id ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
      await flutterLocalNotificationsPlugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  Future<Map<String, dynamic>> sendPush({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (tokens.isEmpty) return {'successCount': 0, 'failureCount': 0};

    // FCM Legacy HTTP API limits registration_ids to 1000 per request.
    // We will batch them into chunks of 500 to guarantee delivery.
    const int batchSize = 500;
    int totalSuccess = 0;
    int totalFailure = 0;

    for (var i = 0; i < tokens.length; i += batchSize) {
      final end = (i + batchSize < tokens.length)
          ? i + batchSize
          : tokens.length;
      final batch = tokens.sublist(i, end);

      final batchResult = await sendFcmViaHttp(batch, title, body, data ?? {});
      final staleTokens = batchResult['staleTokens'] as List<String>;
      totalSuccess += batchResult['successCount'] as int;
      totalFailure += batchResult['failureCount'] as int;

      if (staleTokens.isNotEmpty) {
        debugPrint(
          'FCM_MULTICAST: Found ${staleTokens.length} stale tokens. Removing them from database...',
        );
        try {
          await Supabase.instance.client
              .from('kurichiyar_profiles')
              .update({'fcm_token': null})
              .inFilter('fcm_token', staleTokens);
          debugPrint('FCM_MULTICAST: Successfully cleaned up stale tokens.');
        } catch (e) {
          debugPrint('FCM_MULTICAST: Failed to clean up stale tokens: $e');
        }
      }
      debugPrint(
        'FCM_MULTICAST: Sent batch ${i ~/ batchSize + 1} of ${(tokens.length / batchSize).ceil()}',
      );
    }
    return {'successCount': totalSuccess, 'failureCount': totalFailure};
  }

  Future<String?> sendTopicPush({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    return await sendFcmTopicViaHttp(topic, title, body, data ?? {});
  }

  Future<bool> sendTestNotification({
    String? token,
    String? title,
    String? body,
  }) async {
    final testTitle = title ?? '🔔 Test Notification';
    final testBody =
        body ?? 'Sound, vibration, and popup alert working properly!';

    List<String> targetTokens = [];

    if (token == null) {
      debugPrint(
        'sendTestNotification: Fetching active FCM tokens with timeout...',
      );
      try {
        final tokenRows = await Supabase.instance.client
            .from('kurichiyar_profiles')
            .select('fcm_token')
            .not('fcm_token', 'is', null)
            .timeout(const Duration(seconds: 3));

        targetTokens = List<Map<String, dynamic>>.from(tokenRows)
            .map((r) => r['fcm_token']?.toString() ?? '')
            .where((t) => t.isNotEmpty)
            .toList();
      } catch (e) {
        debugPrint(
          'Failed or timed out fetching tokens for test notification: $e',
        );
      }
    } else {
      targetTokens = [token];
    }

    if (targetTokens.isNotEmpty) {
      try {
        await sendPush(
          tokens: targetTokens,
          title: testTitle,
          body: testBody,
        ).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Push dispatch error/timeout: $e');
      }
    }

    return true;
  }

  // --- LEGACY WRAPPERS (to fix compilation errors across the app) ---
  Future<void> sendAdminBroadcast(
    String message, [
    Map<String, dynamic>? data,
  ]) async {
    List<String> allTokens = [];
    try {
      final tokenRows = await Supabase.instance.client
          .from('kurichiyar_profiles')
          .select('fcm_token')
          .not('fcm_token', 'is', null);

      allTokens = List<Map<String, dynamic>>.from(tokenRows)
          .map((r) => r['fcm_token']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Failed to fetch tokens for broadcast: $e');
    }

    if (allTokens.isNotEmpty) {
      await sendPush(
        tokens: allTokens,
        title: 'Admin Update',
        body: message,
        data: data,
      );
    } else {
      debugPrint('No valid FCM tokens found for broadcast.');
    }
  }

  Future<void> sendPushNotification(
    String title,
    String body,
    String token, {
    Map<String, dynamic>? data,
  }) async {
    await sendPush(tokens: [token], title: title, body: body, data: data);
  }

  Future<void> notifyAdminNewRegistration({
    required String userName,
    required String userPhone,
    required String userId,
  }) async {
    List<String> adminTokens = [];
    try {
      final adminProfiles = await Supabase.instance.client
          .from('kurichiyar_profiles')
          .select('fcm_token')
          .or('role.eq.admin,role.eq.super_admin,is_admin.eq.true')
          .not('fcm_token', 'is', null);

      adminTokens = List<Map<String, dynamic>>.from(adminProfiles)
          .map((r) => r['fcm_token']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Failed to fetch admin tokens for registration notice: $e');
    }

    if (adminTokens.isNotEmpty) {
      await sendPush(
        tokens: adminTokens,
        title: 'Kurichiyar Matrimony - പുതിയ രജിസ്ട്രേഷൻ',
        body: 'പുതിയ പ്രൊഫൈൽ അപ്രൂവലിനായി വന്നിട്ടുണ്ട്: $userName',
        data: {
          'type': 'new_registration',
          'userId': userId,
          'phone': userPhone,
          'sound': 'alert_sound',
          'sound_name': 'alert_sound',
          'channel_id': 'matrimony_alerts_channel',
          'icon': 'ic_launcher',
        },
      );
    } else {
      debugPrint('No admin tokens found for new registration notification.');
    }
  }

  /// Triggers clan/moiety filtering logic when a profile is approved by Admin,
  /// sending a Rich Push Notification to all compatible opposite-gender users.
  Future<void> notifyMatchingUsersOnApproval(String approvedUserId) async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch approved user's profile
      final approvedRow = await supabase
          .from('kurichiyar_profiles')
          .select()
          .eq('id', approvedUserId)
          .maybeSingle();

      if (approvedRow == null) {
        debugPrint(
          "notifyMatchingUsersOnApproval: Profile $approvedUserId not found.",
        );
        return;
      }

      final String name = (approvedRow['name'] ?? 'പുതിയ പൊരുത്തം')
          .toString()
          .trim();
      final String gender = (approvedRow['gender']?.toString() ?? '')
          .toLowerCase();

      // Calculate Age
      int age = 22;
      if (approvedRow['age'] != null &&
          approvedRow['age'] is int &&
          approvedRow['age'] > 0) {
        age = approvedRow['age'] as int;
      } else if (approvedRow['dob'] != null ||
          approvedRow['date_of_birth'] != null) {
        final dobStr = (approvedRow['dob'] ?? approvedRow['date_of_birth'])
            .toString();
        final dob = DateTime.tryParse(dobStr);
        if (dob != null) {
          age = DateTime.now().year - dob.year;
        }
      }

      final String familyName =
          (approvedRow['family_name'] ??
                  approvedRow['house_name'] ??
                  approvedRow['family'] ??
                  'കുടുംബം')
              .toString()
              .trim();

      final String tharavaduName =
          (approvedRow['tharavad_name'] ??
                  approvedRow['mother_clan_name'] ??
                  approvedRow['tharavadu'] ??
                  'തറവാട്')
              .toString()
              .trim();

      String photoUrl =
          (approvedRow['photo_url'] ?? approvedRow['profile_photo_url'] ?? '')
              .toString();
      if (photoUrl.isEmpty &&
          approvedRow['photos'] is List &&
          (approvedRow['photos'] as List).isNotEmpty) {
        photoUrl = (approvedRow['photos'] as List).first.toString();
      }

      // 2. Query all candidate profiles with FCM tokens
      final candidateRows = await supabase
          .from('kurichiyar_profiles')
          .select()
          .not('fcm_token', 'is', null)
          .neq('id', approvedUserId);

      if ((candidateRows as List).isEmpty) {
        debugPrint(
          "notifyMatchingUsersOnApproval: No FCM candidate users found.",
        );
        return;
      }

      final approvedUserProfile = UserProfile.fromMap(approvedRow);

      List<String> matchingTokens = [];
      List<String> matchingUserIds = [];

      for (final row in candidateRows) {
        final candGender = (row['gender']?.toString() ?? '').toLowerCase();

        // Opposite gender check
        final isMaleA = (gender == 'male' || gender == 'ആൺ' || gender == 'm');
        final isMaleB =
            (candGender == 'male' || candGender == 'ആൺ' || candGender == 'm');
        if (isMaleA == isMaleB) continue;

        final candidateUserProfile = UserProfile.fromMap(row);

        // Compatibility check using MatchingService.isMatchEligible
        final isCompatible = MatchingService.isMatchEligible(
          approvedUserProfile,
          candidateUserProfile,
        );

        if (isCompatible) {
          final token = row['fcm_token']?.toString();
          final candId = row['id']?.toString();
          if (token != null && token.isNotEmpty) {
            matchingTokens.add(token);
          }
          if (candId != null && candId.isNotEmpty) {
            matchingUserIds.add(candId);
          }
        }
      }

      if (matchingTokens.isEmpty) {
        debugPrint(
          "notifyMatchingUsersOnApproval: No compatible matching users with FCM tokens.",
        );
        return;
      }

      final String notificationTitle = 'Kurichiyar Matrimony - പുതിയ പൊരുത്തം!';
      final String notificationBody =
          '$name ($age), കുടുംബം: $familyName, തറവാട്: $tharavaduName';

      debugPrint(
        "📢 Broadcasting Match Push to ${matchingTokens.length} compatible profiles: $notificationTitle | $notificationBody",
      );

      await sendPush(
        tokens: matchingTokens,
        title: notificationTitle,
        body: notificationBody,
        data: {
          'type': 'new_match',
          'match_id': approvedUserId,
          'sender_id': approvedUserId,
          'sound': 'match_found',
          'sound_name': 'match_found',
          'channel_id': 'match_alert_channel',
          'icon': 'ic_launcher',
          if (photoUrl.isNotEmpty) 'image_url': photoUrl,
          if (photoUrl.isNotEmpty) 'image': photoUrl,
        },
      );

      // Save notification to DB for matching candidates
      for (final candId in matchingUserIds) {
        try {
          await supabase.from('notifications').insert({
            'user_id': candId,
            'title': notificationTitle,
            'body': notificationBody,
            'type': 'new_match',
            'sender_id': approvedUserId,
            'image_url': photoUrl.isNotEmpty ? photoUrl : null,
            'created_at': DateTime.now().toIso8601String(),
            'is_read': false,
          });
        } catch (dbErr) {
          debugPrint("Db notification insert error for $candId: $dbErr");
        }
      }
    } catch (e, st) {
      debugPrint("Error in notifyMatchingUsersOnApproval: $e\n$st");
    }
  }

  Future<void> sendTargetedTestNotification({
    required String target,
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    String finalToken = target;
    try {
      // Try to fetch the fcm_token assuming target might be a user ID
      final response = await Supabase.instance.client
          .from('kurichiyar_profiles')
          .select('fcm_token')
          .eq('id', target)
          .maybeSingle();

      if (response != null &&
          response['fcm_token'] != null &&
          response['fcm_token'].toString().isNotEmpty) {
        finalToken = response['fcm_token'].toString();
        debugPrint('Direct Token Fetch successful for user $target');
      }
    } catch (e) {
      debugPrint('Direct Token Fetch failed or target is not a valid UUID: $e');
    }

    await sendTestNotification(token: finalToken, title: title, body: body);
  }

  Future<bool> registerFCMToken(String userId) async {
    try {
      String? token;
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (Platform.isIOS) {
          try {
            final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
            debugPrint('FCM_APNS_TOKEN: $apnsToken');
          } catch (apnsErr) {
            debugPrint('FCM_APNS_FETCH_ERR: $apnsErr');
          }
        }

        // Retry loop up to 3 attempts with exponential delay
        for (int attempt = 0; attempt < 3; attempt++) {
          try {
            token = await FirebaseMessaging.instance.getToken();
            if (token != null && token.trim().isNotEmpty) break;
          } catch (tErr) {
            debugPrint('FCM_TOKEN_ATTEMPT_${attempt + 1}_FAILED: $tErr');
          }
          await Future.delayed(Duration(seconds: attempt + 1));
        }
      } catch (e) {
        debugPrint('FirebaseMessaging.getToken error: $e');
      }

      if (token == null || token.trim().isEmpty) {
        debugPrint('========================================');
        debugPrint(
          'CRITICAL_FCM_ERROR: Could not retrieve a real FCM token from Firebase.',
        );
        debugPrint('========================================');
        return false;
      }

      debugPrint('========================================');
      debugPrint('REAL_FCM_TOKEN_REGISTERED: $token');
      debugPrint('========================================');

      final supabase = Supabase.instance.client;
      final authUser = supabase.auth.currentUser;

      // 1. Primary: Try updating by supabase.auth.currentUser?.id first
      if (authUser != null && authUser.id.isNotEmpty) {
        debugPrint(
          'FCM_UPDATE: Attempting primary update by auth.currentUser.id: ${authUser.id}',
        );
        try {
          var updateRes = await supabase
              .from('kurichiyar_profiles')
              .update({
                'fcm_token': token,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', authUser.id)
              .select('id, fcm_token');

          debugPrint('FCM_UPDATE_RES (by auth id): $updateRes');
          if ((updateRes as List).isNotEmpty) {
            debugPrint('========================================');
            return true;
          }
        } catch (e) {
          debugPrint('FCM_UPDATE step 1 error: $e');
        }
      }

      // 2. Secondary: Try updating by passed userId (if valid UUID or string)
      if (userId.isNotEmpty) {
        debugPrint('FCM_UPDATE: Attempting update by passed userId: $userId');
        try {
          var updateRes = await supabase
              .from('kurichiyar_profiles')
              .update({
                'fcm_token': token,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', userId)
              .select('id, fcm_token');

          debugPrint('FCM_UPDATE_RES (by userId): $updateRes');
          if ((updateRes as List).isNotEmpty) {
            debugPrint('========================================');
            return true;
          }
        } catch (e) {
          debugPrint('FCM_UPDATE step 2 error: $e');
        }
      }

      // 3. Fallback: Do not register token on random profiles as it breaks target routing
      debugPrint('FCM_UPDATE: Finished attempts for current user.');
      return false;
    } catch (e, stack) {
      debugPrint('registerFCMToken ERROR: $e');
      debugPrint('STACKTRACE: $stack');
      return false;
    }
  }

  void subscribeToUserNotifications(String userId) {
    debugPrint('subscribeToUserNotifications stub called for $userId');
  }

  /// Displays a local notification when an optional or new app update is available.
  static Future<void> showUpdateNotification({
    required String latestVersion,
    String? apkUrl,
    String? releaseNotes,
  }) async {
    final title = 'പുതിയ അപ്ഡേറ്റ് ലഭ്യമാണ്! (v$latestVersion)';
    final body = releaseNotes != null && releaseNotes.trim().isNotEmpty
        ? 'പുതിയ പതിപ്പ് v$latestVersion ഇപ്പോൾ ലഭ്യമാണ്. കൂടുതൽ സൗകര്യങ്ങൾക്കായി ഇപ്പോൾ അപ്ഡേറ്റ് ചെയ്യുക.\n$releaseNotes'
        : 'കുറിച്ച്യർ മാട്രിമോണി പുതിയ പതിപ്പ് v$latestVersion ഇപ്പോൾ ലഭ്യമാണ്. കൂടുതൽ സൗകര്യങ്ങൾക്കായി ഇപ്പോൾ അപ്ഡേറ്റ് ചെയ്യുക.';

    await showNotification(
      id: 999101, // Dedicated notification ID for in-app updates
      title: title,
      body: body,
      type: 'app_update',
      payload: apkUrl ?? 'https://play.google.com/store/apps/details?id=com.example.kurichiyar_matrimony',
    );
  }
}

// Trigger IDE cache invalidation
