import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';

/// Sends a push notification directly via the FCM HTTP v1 endpoint.
/// Returns a map containing successCount, failureCount, and staleTokens.
Future<Map<String, dynamic>> sendFcmViaHttp(
  List<String> tokens,
  String title,
  String body,
  Map<String, dynamic> data,
) async {
  try {
    debugPrint(
      'FCM_HTTP_V1: Attempting to load service-account.json from assets...',
    );
    final serviceAccountJson = await rootBundle.loadString(
      'assets/service-account.json',
    );
    debugPrint('FCM_HTTP_V1: Successfully loaded service-account.json');
    final Map<String, dynamic> serviceAccountData = jsonDecode(
      serviceAccountJson,
    );
    final projectId = serviceAccountData['project_id'];

    final accountCredentials = ServiceAccountCredentials.fromJson(
      serviceAccountJson,
    );
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await clientViaServiceAccount(accountCredentials, scopes);
    final url =
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

    List<String> staleTokens = [];
    int successCount = 0;
    int failureCount = 0;

    // Chunk tokens to avoid overwhelming the device network sockets
    const int chunkSize = 50;
    for (int i = 0; i < tokens.length; i += chunkSize) {
      final end = (i + chunkSize < tokens.length)
          ? i + chunkSize
          : tokens.length;
      final tokenChunk = tokens.sublist(i, end);

      // Execute requests for this chunk concurrently
      final futures = tokenChunk.map((token) async {
        final soundVal =
            data['sound']?.toString() ??
            data['sound_name']?.toString() ??
            'default';
        final channelId =
            data['channel_id']?.toString() ??
            (soundVal.contains('match')
                ? 'match_alert_channel'
                : 'matrimony_alerts_channel');
        final iconVal = data['icon']?.toString() ?? 'ic_launcher';
        final imageUrl =
            data['image_url']?.toString() ?? data['image']?.toString();

        final payload = {
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
              if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
            },
            'data': data.map((key, value) => MapEntry(key, value.toString())),
            'android': {
              'priority': 'HIGH',
              'notification': {
                'title': title,
                'body': body,
                'sound': soundVal,
                'channel_id': channelId,
                'default_sound': soundVal == 'default',
                'default_vibrate_timings': true,
                'notification_priority': 'PRIORITY_MAX',
                'visibility': 'PUBLIC',
                'icon': iconVal,
                if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound':
                      soundVal.endsWith('.mp3') || soundVal.endsWith('.wav')
                      ? soundVal
                      : '$soundVal.mp3',
                  'content-available': 1,
                  'alert': {'title': title, 'body': body},
                },
              },
            },
          },
        };

        try {
          final response = await client.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          );

          if (response.statusCode != 200) {
            debugPrint(
              'FCM_HTTP_V1_ERROR for token $token: STATUS ${response.statusCode} | BODY: ${response.body}',
            );
            // If the token is unregistered or invalid, mark it as stale
            if (response.statusCode == 404 ||
                response.statusCode == 400 ||
                response.statusCode == 403) {
              return {'status': 'stale', 'token': token};
            }
            return {'status': 'error', 'token': token};
          } else {
            debugPrint(
              'FCM_HTTP_V1_SUCCESS for token $token: STATUS ${response.statusCode}',
            );
            return {'status': 'success', 'token': token};
          }
        } catch (e) {
          debugPrint('FCM_HTTP_V1_REQ_EXCEPTION for token $token: $e');
          return {'status': 'error', 'token': token};
        }
      });

      final results = await Future.wait(futures);
      for (var res in results) {
        if (res['status'] == 'success') {
          successCount++;
        } else {
          failureCount++;
          if (res['status'] == 'stale') {
            staleTokens.add(res['token'] as String);
          }
        }
      }
    }

    client.close();
    return {
      'successCount': successCount,
      'failureCount': failureCount,
      'staleTokens': staleTokens,
    };
  } catch (e) {
    debugPrint('FCM_HTTP_V1_EXCEPTION: $e');
    throw Exception('FCM Broadcast Error: $e');
  }
}

/// Sends a push notification to a topic via the FCM HTTP v1 endpoint.
Future<String?> sendFcmTopicViaHttp(
  String topic,
  String title,
  String body,
  Map<String, dynamic> data,
) async {
  try {
    debugPrint('FCM_HTTP_V1_TOPIC: Attempting to send to topic $topic...');
    final serviceAccountJson = await rootBundle.loadString(
      'assets/service-account.json',
    );
    final Map<String, dynamic> serviceAccountData = jsonDecode(
      serviceAccountJson,
    );
    final projectId = serviceAccountData['project_id'];
    final clientEmail = serviceAccountData['client_email'];

    debugPrint('ACTUAL_SERVICE_ACCOUNT_EMAIL: $clientEmail');
    debugPrint('ACTUAL_SERVICE_ACCOUNT_PROJECT_ID: $projectId');

    final accountCredentials = ServiceAccountCredentials.fromJson(
      serviceAccountJson,
    );
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await clientViaServiceAccount(accountCredentials, scopes);
    final url =
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

    final payload = {
      'message': {
        'topic': topic,
        'notification': {'title': title, 'body': body},
        'android': {
          'priority': 'HIGH',
          'notification': {
            'channel_id': 'clan_high_importance_channel',
            'sound': 'default',
            'default_sound': true,
            'default_vibrate_timings': true,
            'notification_priority': 'PRIORITY_MAX',
            'visibility': 'PUBLIC',
          },
        },
        'data': data.map((key, value) => MapEntry(key, value.toString())),
      },
    };

    final response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    client.close();

    if (response.statusCode != 200) {
      debugPrint('TOPIC_FCM_STATUS: ${response.statusCode}');
      debugPrint('TOPIC_FCM_BODY: ${response.body}');
      debugPrint(
        'FCM_HTTP_V1_TOPIC_ERROR: STATUS ${response.statusCode} | BODY: ${response.body}',
      );
      return 'HTTP ${response.statusCode}: ${response.body}';
    } else {
      debugPrint('FCM_HTTP_V1_TOPIC_SUCCESS: Sent to $topic');
      return null;
    }
  } catch (e) {
    debugPrint('FCM_HTTP_V1_TOPIC_EXCEPTION: $e');
    return 'Exception: $e';
  }
}
