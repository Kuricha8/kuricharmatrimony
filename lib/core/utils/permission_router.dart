import 'package:permission_handler/permission_handler.dart';

class PermissionRouter {
  static Future<bool> requestEssentialPermissions() async {
    // 1. Notification Permission
    var notifStatus = await Permission.notification.status;
    if (!notifStatus.isGranted) {
      await Permission.notification.request();
    }

    // 2. Location Permission
    var locStatus = await Permission.location.status;
    if (!locStatus.isGranted) {
      await Permission.location.request();
    }

    // 3. Storage/File Access
    var storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted) {
      await Permission.storage.request();
    }

    // Graceful check - we don't block the app if they deny,
    // we just return true to proceed. Modules will handle missing perms gracefully.
    return true;
  }
}
