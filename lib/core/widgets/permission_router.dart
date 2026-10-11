import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionRouter {
  static Future<void> requestEssentialPermissions() async {
    // Sequentially request permissions as per QA audit checklist requirements

    // 1. Storage/Photos
    final storageStatus = await Permission.storage.request();
    debugPrint('Storage Permission: $storageStatus');

    // 2. Notifications
    final notifStatus = await Permission.notification.request();
    debugPrint('Notification Permission: $notifStatus');

    // 3. Location (for localized ad rendering in AdMob and local matching)
    final locStatus = await Permission.location.request();
    debugPrint('Location Permission: $locStatus');
  }
}
