import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';

/// FlutterWindowManager provides a clean, unified API for managing window flags,
/// specifically [FLAG_SECURE] to dynamically toggle screenshot and screen recording blocking.
class FlutterWindowManager {
  /// Window flag: treat the content of the window as secure, preventing
  /// it from appearing in screenshots or from being viewed on non-secure displays.
  // ignore: constant_identifier_names
  static const int FLAG_SECURE = 8192;

  static const MethodChannel _channel = MethodChannel(
    'com.kurichiyar.matrimony/window_security',
  );

  /// Adds window flags. When [FLAG_SECURE] is supplied, enables secure window protection.
  static Future<bool> addFlags(int flags) async {
    if (kIsWeb) return true;
    if ((flags & FLAG_SECURE) != 0) {
      try {
        await ScreenProtector.protectDataLeakageOn();
      } catch (e) {
        debugPrint('[FlutterWindowManager] ScreenProtector protectDataLeakageOn notice: $e');
      }

      try {
        if (Platform.isAndroid) {
          await _channel.invokeMethod('enableSecureScreen');
        }
      } catch (e) {
        debugPrint('[FlutterWindowManager] Native enableSecureScreen notice: $e');
      }
      return true;
    }
    return false;
  }

  /// Clears window flags. When [FLAG_SECURE] is supplied, removes secure window protection.
  static Future<bool> clearFlags(int flags) async {
    if (kIsWeb) return true;
    if ((flags & FLAG_SECURE) != 0) {
      try {
        await ScreenProtector.protectDataLeakageOff();
      } catch (e) {
        debugPrint('[FlutterWindowManager] ScreenProtector protectDataLeakageOff notice: $e');
      }

      try {
        if (Platform.isAndroid) {
          await _channel.invokeMethod('disableSecureScreen');
        }
      } catch (e) {
        debugPrint('[FlutterWindowManager] Native disableSecureScreen notice: $e');
      }
      return true;
    }
    return false;
  }
}
