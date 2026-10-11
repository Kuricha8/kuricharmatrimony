import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shake/shake.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/mock_data.dart';

/// Ring buffer storing the latest console debug logs and network errors
class LogBuffer {
  static const int _maxCapacity = 50;
  static final List<String> _logs = [];

  static void add(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final entry = '[$timestamp] $message';
    _logs.add(entry);
    if (_logs.length > _maxCapacity) {
      _logs.removeAt(0);
    }
  }

  static List<String> getLastLogs([int count = 20]) {
    if (_logs.length <= count) {
      return List<String>.from(_logs);
    }
    return _logs.sublist(_logs.length - count);
  }

  static void clear() {
    _logs.clear();
  }
}

/// NavigatorObserver that continuously records active route hierarchy (breadcrumbs)
class RouteBreadcrumbObserver extends NavigatorObserver {
  static final RouteBreadcrumbObserver instance = RouteBreadcrumbObserver._();
  RouteBreadcrumbObserver._();

  final List<String> _breadcrumbs = ['/'];

  List<String> get currentBreadcrumbs =>
      List<String>.unmodifiable(_breadcrumbs);

  String get currentRouteName =>
      _breadcrumbs.isNotEmpty ? _breadcrumbs.last : '/';

  void _updateRoute(Route<dynamic>? route, {bool isPush = true}) {
    final name =
        route?.settings.name ??
        route?.runtimeType.toString() ??
        'AnonymousRoute';
    if (isPush) {
      _breadcrumbs.add(name);
      if (_breadcrumbs.length > 15) _breadcrumbs.removeAt(0);
    } else {
      if (_breadcrumbs.isNotEmpty) _breadcrumbs.removeLast();
    }
    LogBuffer.add(
      'NAV: ${isPush ? 'Push' : 'Pop'} -> $name | Stack: ${_breadcrumbs.join(' > ')}',
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateRoute(route, isPush: true);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _updateRoute(route, isPush: false);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) _updateRoute(oldRoute, isPush: false);
    if (newRoute != null) _updateRoute(newRoute, isPush: true);
  }
}

/// Silent Shake Telemetry Service
class ShakeTelemetryService {
  ShakeTelemetryService._();
  static final ShakeTelemetryService _instance = ShakeTelemetryService._();
  static ShakeTelemetryService get instance => _instance;

  ShakeDetector? _shakeDetector;
  bool _isReporting = false;

  /// Global RepaintBoundary Key to take high-fidelity screenshots
  static final GlobalKey rootBoundaryKey = GlobalKey();

  /// Initialize shake listening
  void initialize(BuildContext context) {
    if (kIsWeb) return;
    try {
      _shakeDetector = ShakeDetector.autoStart(
        shakeThresholdGravity: 2.7,
        shakeSlopTimeMS: 800,
        shakeCountResetTime: 3000,
        onPhoneShake: (event) {
          debugPrint(
            '[ShakeTelemetry] Phone shake detected! Capturing contextual telemetry...',
          );
          triggerReport(context: context);
        },
      );
      LogBuffer.add('ShakeTelemetryService initialized.');
    } catch (e) {
      debugPrint('[ShakeTelemetry] Shake init notice: $e');
    }
  }

  /// Triggers full telemetry capture and saves to Supabase `app_issue_reports`
  Future<void> triggerReport({
    BuildContext? context,
    String? customError,
    String? pageTitle,
    bool showSnackBarNotice = true,
  }) async {
    if (_isReporting) return;
    _isReporting = true;

    try {
      // 1. Capture user profile identity
      final currentUser = MockData().currentUser;
      final session = Supabase.instance.client.auth.currentSession;
      final userId = currentUser?.id ?? session?.user.id;
      final userName =
          currentUser?.name ?? session?.user.email ?? 'Guest / Anonymous';
      final userPhone =
          currentUser?.publicDisplayNumber ?? currentUser?.guardianPhone ?? '';

      // 2. Capture Route breadcrumbs & page title
      final breadcrumbs = RouteBreadcrumbObserver.instance.currentBreadcrumbs;
      final activePage =
          pageTitle ?? RouteBreadcrumbObserver.instance.currentRouteName;

      // 3. Capture Last 20 lines of console debug logs
      final lastLogs = LogBuffer.getLastLogs(20);

      // 4. Capture Device Metadata
      final deviceInfoMap = await _getDeviceMetadata();

      // 5. Capture Screenshot (Base64)
      String? screenshotBase64;
      try {
        screenshotBase64 = await _captureScreenshotBase64();
      } catch (e) {
        debugPrint('[ShakeTelemetry] Screenshot capture error: $e');
      }

      // 6. Build debug_metadata JSONB payload
      final debugMetadata = {
        'last_20_logs': lastLogs,
        'breadcrumbs': breadcrumbs,
        'device_info': deviceInfoMap,
        'timestamp': DateTime.now().toIso8601String(),
        'active_page': activePage,
        'os': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
      };

      // 7. Insert to Supabase app_issue_reports
      final supabase = Supabase.instance.client;
      await supabase.from('app_issue_reports').insert({
        'user_id': userId,
        'user_name': userName,
        'user_phone': userPhone,
        'page_title': activePage,
        'screenshot_base64': screenshotBase64,
        'route_hierarchy': breadcrumbs,
        'error_message':
            customError ??
            (lastLogs.isNotEmpty
                ? lastLogs.last
                : 'Shake gesture user feedback'),
        'debug_metadata': debugMetadata,
        'status': 'pending',
      });

      LogBuffer.add('Issue report successfully transmitted to Supabase.');
      debugPrint(
        '[ShakeTelemetry] Issue report stored successfully with full debug metadata.',
      );

      if (showSnackBarNotice && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF000080),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.bug_report,
                  color: Colors.amberAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Issue Telemetry Captured on "$activePage" with logs & screenshot.',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[ShakeTelemetry] Failed to dispatch report: $e');
      LogBuffer.add('Failed to dispatch report: $e');
    } finally {
      _isReporting = false;
    }
  }

  Future<Map<String, dynamic>> _getDeviceMetadata() async {
    final Map<String, dynamic> info = {};
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      info['app_name'] = packageInfo.appName;
      info['package_name'] = packageInfo.packageName;
      info['version'] = packageInfo.version;
      info['build_number'] = packageInfo.buildNumber;

      final deviceInfo = DeviceInfoPlugin();
      if (!kIsWeb && Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        info['brand'] = android.brand;
        info['model'] = android.model;
        info['android_version'] = android.version.release;
        info['sdk_int'] = android.version.sdkInt;
        info['is_physical_device'] = android.isPhysicalDevice;
      } else if (!kIsWeb && Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        info['name'] = ios.name;
        info['model'] = ios.model;
        info['system_version'] = ios.systemVersion;
        info['is_physical_device'] = ios.isPhysicalDevice;
      }
    } catch (e) {
      info['error'] = e.toString();
    }
    return info;
  }

  Future<String?> _captureScreenshotBase64() async {
    try {
      final boundary =
          rootBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      return base64Encode(bytes);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _shakeDetector?.stopListening();
  }
}
