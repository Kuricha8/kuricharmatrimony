import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  static Future<void> requestOnboardingPermissions() async {
    if (kIsWeb) return;

    final permissions = [
      Permission.camera,
      Permission.phone,
      Permission.storage,
      Permission.photos,
      Permission.sms,
      Permission.notification,
    ];

    // Request all permissions at once
    await permissions.request();
  }
}
