import 'notification_manager.dart';

/// Legacy compatibility layer for NotificationService.
/// Forwards all operations to NotificationManager.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  NotificationManager get _manager => NotificationManager.instance;

  Future<void> init() => NotificationManager.instance.init();

  Future<void> showNotification({
    required String title,
    required String body,
    String? type,
    String? payload,
    int? id,
  }) {
    return NotificationManager.showNotification(
      title: title,
      body: body,
      type: type,
      payload: payload,
      id: id,
    );
  }

  Future<Map<String, dynamic>> sendPush({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    return NotificationManager.instance.sendPush(
      tokens: tokens,
      title: title,
      body: body,
      data: data,
    );
  }

  Future<String?> sendTopicPush({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    return NotificationManager.instance.sendTopicPush(
      topic: topic,
      title: title,
      body: body,
      data: data,
    );
  }

  Future<bool> sendTestNotification({
    String? token,
    String? title,
    String? body,
  }) {
    return _manager.sendTestNotification(
      token: token,
      title: title,
      body: body,
    );
  }

  Future<void> sendAdminBroadcast(
    String message, [
    Map<String, dynamic>? data,
  ]) {
    return _manager.sendAdminBroadcast(message, data);
  }

  Future<void> sendPushNotification(
    String title,
    String body,
    String token, {
    Map<String, dynamic>? data,
  }) {
    return _manager.sendPushNotification(title, body, token, data: data);
  }

  Future<void> notifyAdminNewRegistration({
    required String userName,
    required String userPhone,
    required String userId,
  }) {
    return _manager.notifyAdminNewRegistration(
      userName: userName,
      userPhone: userPhone,
      userId: userId,
    );
  }

  Future<void> sendTargetedTestNotification({
    required String target,
    required String title,
    required String body,
    String? imageUrl,
  }) {
    return _manager.sendTargetedTestNotification(
      target: target,
      title: title,
      body: body,
      imageUrl: imageUrl,
    );
  }

  Future<bool> registerFCMToken(String userId) {
    return _manager.registerFCMToken(userId);
  }

  void subscribeToUserNotifications(String userId) {
    _manager.subscribeToUserNotifications(userId);
  }
}
