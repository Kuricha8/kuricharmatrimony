import 'package:web/web.dart' as web;

void showWebNotification(String title, String body) {
  if (web.Notification.permission == 'granted') {
    final options = web.NotificationOptions(
      body: body,
      icon: '/icons/Icon-192.png',
    );
    web.Notification(title, options);
  }
}

void requestWebNotificationPermission() {
  if (web.Notification.permission != 'granted' &&
      web.Notification.permission != 'denied') {
    web.Notification.requestPermission();
  }
}
