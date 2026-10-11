import 'package:flutter/foundation.dart';

class GlobalErrorHandler {
  /// Logs an error without blocking the UI.
  static void logError(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    debugPrint('🚨 GLOBAL ERROR: $message');
    if (error != null) {
      debugPrint('Details: ${error.toString()}');
    }
    if (stackTrace != null) {
      debugPrint('Stack Trace:\n$stackTrace');
    }
    // Future integration: Sentry, Firebase Crashlytics, etc.
  }
}
