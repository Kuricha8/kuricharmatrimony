import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsentService {
  static const String _consentKey = 'legal_consent_metadata';

  /// Captures all required consent metadata and stores it locally.
  static Future<void> captureConsent() async {
    try {
      final ipAddress = await _getPublicIp();
      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();

      final metadata = {
        'agreement_accepted': true,
        'accepted_at': DateTime.now().toIso8601String(),
        'ip_address': ipAddress,
        'device_info': deviceInfo,
        'app_version': packageInfo.version,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_consentKey, jsonEncode(metadata));
      await prefs.setBool('hasAgreedTerms', true);
      debugPrint('Consent metadata securely captured.');

      // Check if user is authenticated and upload immediately
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await uploadConsent(currentUser.id, metadata);
      }
    } catch (e) {
      debugPrint('Failed to capture consent metadata: $e');
      // Even if metadata capture partially fails (e.g., no internet for IP),
      // we still record the core consent to not block the user entirely.
      final prefs = await SharedPreferences.getInstance();
      final fallbackMetadata = {
        'agreement_accepted': true,
        'accepted_at': DateTime.now().toIso8601String(),
        'ip_address': 'unknown',
        'device_info': 'unknown',
        'app_version': 'unknown',
      };
      await prefs.setString(_consentKey, jsonEncode(fallbackMetadata));
      await prefs.setBool('hasAgreedTerms', true);

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await uploadConsent(currentUser.id, fallbackMetadata);
      }
    }
  }

  /// Uploads consent log to Supabase user_consent_logs table.
  static Future<void> uploadConsent(
    String uid,
    Map<String, dynamic> metadata,
  ) async {
    try {
      await Supabase.instance.client.from('user_consent_logs').insert({
        'user_id': uid,
        'agreement_accepted': metadata['agreement_accepted'] ?? true,
        'accepted_at':
            metadata['accepted_at'] ?? DateTime.now().toIso8601String(),
        'ip_address': metadata['ip_address'] ?? 'unknown',
        'device_info': metadata['device_info'] ?? 'unknown',
      });
      debugPrint(
        'Consent successfully uploaded to user_consent_logs for user $uid',
      );
    } catch (e) {
      debugPrint('Failed to upload consent to user_consent_logs: $e');
    }
  }

  /// Retrieves the captured consent metadata for injection into Supabase profiles.
  static Future<Map<String, dynamic>?> getConsentMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_consentKey);
    if (jsonStr != null) {
      try {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Failed to decode consent metadata: $e');
      }
    }
    return null;
  }

  static Future<String> _getPublicIp() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ip'] ?? 'unknown';
      }
    } catch (e) {
      debugPrint('IP Fetch failed: $e');
    }
    return 'unknown';
  }

  static Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return 'Web: ${webInfo.browserName.name} ${webInfo.appVersion}';
      } else {
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await deviceInfo.androidInfo;
          return 'Android: ${androidInfo.brand} ${androidInfo.model} (OS ${androidInfo.version.release})';
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await deviceInfo.iosInfo;
          return 'iOS: ${iosInfo.name} ${iosInfo.systemName} ${iosInfo.systemVersion}';
        }
      }
    } catch (e) {
      debugPrint('Device info fetch failed: $e');
    }
    return 'unknown';
  }
}
