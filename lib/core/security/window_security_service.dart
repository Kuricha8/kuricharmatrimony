import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'flutter_window_manager.dart';
import '../utils/mock_data.dart';

export 'flutter_window_manager.dart';

/// Service to protect sensitive application views against unauthorized screen capture,
/// screen recording, and task switcher previews using [FlutterWindowManager].
/// Dynamically updates window security flags (FLAG_SECURE) based on the current user's
/// Firestore document stream in real time.
class WindowSecurityService {
  static bool _isSecure = false;
  static bool _currentUserAllowsScreenshots = false;
  static String? _currentListenedUserId;

  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _screenshotSubscription;
  static StreamSubscription<AuthState>? _supabaseAuthSub;
  static StreamSubscription<fb.User?>? _firebaseAuthSub;

  /// Returns whether screen capture protection is currently active.
  static bool get isSecure => _isSecure;

  /// Returns whether the active user allows screenshots.
  static bool get currentUserAllowsScreenshots => _currentUserAllowsScreenshots;

  /// Enables FLAG_SECURE across the window using FlutterWindowManager.
  /// Strictly blocks screenshots and screen recordings globally.
  static Future<void> enableSecureScreen() async {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    _isSecure = true;
    debugPrint(
      '[WindowSecurityService] Screen capture protection ENABLED (FLAG_SECURE)',
    );
  }

  /// Disables FLAG_SECURE on the current window using FlutterWindowManager.
  static Future<void> disableSecureScreen() async {
    await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    _isSecure = false;
    debugPrint(
      '[WindowSecurityService] Screen capture protection DISABLED (FLAG_SECURE cleared)',
    );
  }

  /// Re-applies the active user's persistent screenshot permission.
  /// Used when popping off screens that temporarily enforced FLAG_SECURE.
  static Future<void> reapplyCurrentUserSecurity() async {
    if (_currentUserAllowsScreenshots) {
      await disableSecureScreen();
    } else {
      await enableSecureScreen();
    }
  }

  /// Parses `allow_screenshot`, `screenshot_blocked`, or `allowScreenshot`
  /// from Firestore document data.
  static bool parseAllowScreenshot(Map<String, dynamic>? data) {
    if (data == null) return false;
    if (data.containsKey('allow_screenshot')) {
      return data['allow_screenshot'] == true;
    }
    if (data.containsKey('screenshot_blocked')) {
      return data['screenshot_blocked'] == false;
    }
    if (data.containsKey('allowScreenshot')) {
      return data['allowScreenshot'] == true;
    }
    return false;
  }

  /// Starts real-time listening to the current user's Firestore document stream
  /// for dynamic screenshot security flag toggling.
  static void startRealtimeScreenshotListener([String? explicitUserId]) {
    final userId = explicitUserId ?? resolveCurrentUserId();
    if (userId == null || userId.isEmpty || userId == 'guest') {
      stopScreenshotListener();
      // Unauthenticated or guest users must ALWAYS be blocked from screenshots
      FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      _isSecure = true;
      _currentUserAllowsScreenshots = false;
      return;
    }

    if (_currentListenedUserId == userId && _screenshotSubscription != null) {
      return;
    }

    stopScreenshotListener();
    _currentListenedUserId = userId;

    try {
      _screenshotSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots()
          .listen(
        (snapshot) async {
          final data = snapshot.data();
          final bool allowScreenshot = parseAllowScreenshot(data);
          _currentUserAllowsScreenshots = allowScreenshot;

          debugPrint(
            '[WindowSecurityService] Realtime Firestore screenshot stream for $userId: '
            'allow_screenshot=$allowScreenshot',
          );

          if (allowScreenshot) {
            await FlutterWindowManager.clearFlags(
              FlutterWindowManager.FLAG_SECURE,
            );
            _isSecure = false;
            debugPrint(
              '[WindowSecurityService] FLAG_SECURE cleared dynamically: screenshots allowed.',
            );
          } else {
            await FlutterWindowManager.addFlags(
              FlutterWindowManager.FLAG_SECURE,
            );
            _isSecure = true;
            debugPrint(
              '[WindowSecurityService] FLAG_SECURE added dynamically: screenshots blocked.',
            );
          }

          // Sync with MockData to ensure Settings UI switch stays in sync in real time
          final currentMock = MockData().currentUser;
          if (currentMock != null && currentMock.id == userId) {
            if (currentMock.allowScreenshot != allowScreenshot) {
              MockData().setCurrentUser(
                currentMock.copyWith(allowScreenshot: allowScreenshot),
              );
            }
          }
        },
        onError: (e) {
          debugPrint(
            '[WindowSecurityService] Screenshot stream listener error: $e',
          );
        },
      );
    } catch (e) {
      debugPrint('[WindowSecurityService] Failed to bind screenshot stream: $e');
    }
  }

  /// Cancels the real-time screenshot listener.
  static void stopScreenshotListener() {
    _screenshotSubscription?.cancel();
    _screenshotSubscription = null;
    _currentListenedUserId = null;
  }

  /// Resolves the current logged in user ID across all auth providers.
  static String? resolveCurrentUserId() {
    try {
      final supaUid = Supabase.instance.client.auth.currentUser?.id;
      if (supaUid != null && supaUid.isNotEmpty) return supaUid;
    } catch (_) {}

    try {
      final fbUid = fb.FirebaseAuth.instance.currentUser?.uid;
      if (fbUid != null && fbUid.isNotEmpty) return fbUid;
    } catch (_) {}

    try {
      final mockUid = MockData().currentUser?.id;
      if (mockUid != null && mockUid.isNotEmpty && mockUid != 'guest') {
        return mockUid;
      }
    } catch (_) {}

    return null;
  }

  /// Initializes global window security and attaches auth listeners so the
  /// Firestore document stream is continuously monitored throughout app lifecycle.
  static void initializeGlobalSecurity() {
    // 1. Initial check
    final initialId = resolveCurrentUserId();
    if (initialId != null && initialId.isNotEmpty && initialId != 'guest') {
      startRealtimeScreenshotListener(initialId);
    } else {
      // Default startup: strictly enable FLAG_SECURE
      FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      _isSecure = true;
    }

    // 2. Supabase auth listener
    try {
      _supabaseAuthSub?.cancel();
      _supabaseAuthSub = Supabase.instance.client.auth.onAuthStateChange.listen(
        (data) {
          final user =
              data.session?.user ?? Supabase.instance.client.auth.currentUser;
          if (user != null && !user.isAnonymous) {
            startRealtimeScreenshotListener(user.id);
          } else if (data.event == AuthChangeEvent.signedOut) {
            final remainingId = resolveCurrentUserId();
            if (remainingId != null && remainingId != 'guest') {
              startRealtimeScreenshotListener(remainingId);
            } else {
              stopScreenshotListener();
              FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
              _isSecure = true;
              _currentUserAllowsScreenshots = false;
            }
          }
        },
      );
    } catch (e) {
      debugPrint(
        '[WindowSecurityService] Supabase onAuthStateChange setup error: $e',
      );
    }

    // 3. Firebase auth listener
    try {
      _firebaseAuthSub?.cancel();
      _firebaseAuthSub = fb.FirebaseAuth.instance.authStateChanges().listen((
        fbUser,
      ) {
        if (fbUser != null && fbUser.uid.isNotEmpty) {
          startRealtimeScreenshotListener(fbUser.uid);
        } else {
          final remainingId = resolveCurrentUserId();
          if (remainingId != null && remainingId != 'guest') {
            startRealtimeScreenshotListener(remainingId);
          } else {
            stopScreenshotListener();
            FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
            _isSecure = true;
            _currentUserAllowsScreenshots = false;
          }
        }
      });
    } catch (e) {
      debugPrint(
        '[WindowSecurityService] FirebaseAuth authStateChanges setup error: $e',
      );
    }
  }

  /// Disposes all listeners.
  static void dispose() {
    stopScreenshotListener();
    _supabaseAuthSub?.cancel();
    _supabaseAuthSub = null;
    _firebaseAuthSub?.cancel();
    _firebaseAuthSub = null;
  }

  /// Executes an asynchronous block within a secure screen context,
  /// guaranteeing that screen security returns to previous state after the block finishes.
  static Future<T> secureScope<T>(Future<T> Function() block) async {
    await enableSecureScreen();
    try {
      return await block();
    } finally {
      await reapplyCurrentUserSecurity();
    }
  }
}
