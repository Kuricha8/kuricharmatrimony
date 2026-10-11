import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart' show appNavigatorKey;
import 'notification_manager.dart';

/// Realtime In-App Update Service (Telegram-Style Non-Blocking Banner)
///
/// Listens to Admin App updates from Firestore (app_updates/latest, app_config/version_info,
/// or app_config/version_control). When a new version is published:
/// 1. Fires a high-importance local notification on channel 'app_updates'.
/// 2. Displays a sleek, non-blocking, dismissible Telegram-style Bottom Sheet or Floating Card.
class InAppUpdateService {
  static final InAppUpdateService instance = InAppUpdateService._internal();
  InAppUpdateService._internal();

  // Firestore stream subscriptions
  StreamSubscription<DocumentSnapshot>? _latestDocSubscription;
  StreamSubscription<DocumentSnapshot>? _versionInfoSubscription;
  StreamSubscription<DocumentSnapshot>? _versionControlSubscription;

  // Track currently active prompt & user dismissals
  int? _currentlyShowingVersionCode;
  int? _dismissedVersionCode;
  String? _dismissedVersionName;

  static const String defaultStoreUrl =
      'https://play.google.com/store/apps/details?id=com.example.kurichiyar_matrimony';

  /// Initializes real-time Firestore listeners for Admin App updates.
  /// Should be called on app startup in main.dart / KurichiyarMatrimonyApp.
  void initRealtimeUpdateListener() async {
    try {
      final packageInfo = await _getPackageInfo();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 1;
      final currentVersionName = packageInfo.version;

      debugPrint(
        'InAppUpdateService: Initializing real-time listener... '
        'Current App Code: $currentVersionCode, Version: $currentVersionName',
      );

      // 1. Primary: collection 'app_updates' -> doc 'latest'
      _latestDocSubscription?.cancel();
      _latestDocSubscription = FirebaseFirestore.instance
          .collection('app_updates')
          .doc('latest')
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists && snapshot.data() != null) {
                _processUpdateData(
                  snapshot.data()!,
                  currentVersionCode: currentVersionCode,
                  currentVersionName: currentVersionName,
                  source: 'app_updates/latest',
                );
              }
            },
            onError: (e) {
              debugPrint('InAppUpdateService: app_updates/latest stream error: $e');
            },
          );

      // 2. Secondary: collection 'app_config' -> doc 'version_info'
      _versionInfoSubscription?.cancel();
      _versionInfoSubscription = FirebaseFirestore.instance
          .collection('app_config')
          .doc('version_info')
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists && snapshot.data() != null) {
                _processUpdateData(
                  snapshot.data()!,
                  currentVersionCode: currentVersionCode,
                  currentVersionName: currentVersionName,
                  source: 'app_config/version_info',
                );
              }
            },
            onError: (e) {
              debugPrint('InAppUpdateService: app_config/version_info stream error: $e');
            },
          );

      // 3. Fallback: collection 'app_config' -> doc 'version_control'
      _versionControlSubscription?.cancel();
      _versionControlSubscription = FirebaseFirestore.instance
          .collection('app_config')
          .doc('version_control')
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists && snapshot.data() != null) {
                _processUpdateData(
                  snapshot.data()!,
                  currentVersionCode: currentVersionCode,
                  currentVersionName: currentVersionName,
                  source: 'app_config/version_control',
                );
              }
            },
            onError: (e) {
              debugPrint('InAppUpdateService: app_config/version_control stream error: $e');
            },
          );
    } catch (e) {
      debugPrint('InAppUpdateService: initRealtimeUpdateListener failed: $e');
    }
  }

  /// Cancels all active Firestore listeners.
  void dispose() {
    _latestDocSubscription?.cancel();
    _versionInfoSubscription?.cancel();
    _versionControlSubscription?.cancel();
  }

  /// One-off manual or startup check.
  Future<void> checkForUpdates(
    BuildContext context, {
    bool forceCheck = false,
    bool showNoUpdateToast = false,
  }) async {
    try {
      final updateData = await fetchRemoteVersionInfo();
      if (updateData == null) {
        if (showNoUpdateToast && context.mounted) {
          _showToast(context, 'നിലവിൽ അപ്ഡേറ്റുകൾ ലഭ്യമല്ല.');
        }
        return;
      }

      final latestVersion = updateData['latest_version'] as String;
      final latestVersionCode = updateData['latest_version_code'] as int;
      final apkUrl = updateData['apk_url'] as String;
      final releaseNotes = updateData['release_notes'] as String;

      final packageInfo = await _getPackageInfo();
      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final isNewer = _isVersionNewer(
        latestVersion: latestVersion,
        latestVersionCode: latestVersionCode,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      );

      debugPrint(
        'InAppUpdateService: Manual check -> Current: v$currentVersion ($currentBuild), '
        'Remote: v$latestVersion ($latestVersionCode), HasUpdate: $isNewer',
      );

      if (isNewer) {
        if (!forceCheck &&
            (_dismissedVersionCode == latestVersionCode ||
                (_dismissedVersionName != null &&
                    _dismissedVersionName == latestVersion))) {
          debugPrint('InAppUpdateService: Update v$latestVersionCode already dismissed by user.');
          return;
        }

        // Fire high-importance local notification on channel 'app_updates'
        await NotificationManager.showUpdateNotification(
          latestVersion: latestVersion.isNotEmpty ? latestVersion : 'v$latestVersionCode',
          apkUrl: apkUrl.isNotEmpty ? apkUrl : defaultStoreUrl,
          releaseNotes: releaseNotes,
        );

        if (context.mounted) {
          showTelegramStyleUpdateSheet(
            context,
            latestVersion: latestVersion.isNotEmpty ? latestVersion : 'v$latestVersionCode',
            currentVersion: currentVersion,
            apkUrl: apkUrl.isNotEmpty ? apkUrl : defaultStoreUrl,
            releaseNotes: releaseNotes,
            versionCode: latestVersionCode,
          );
        }
      } else if (showNoUpdateToast && context.mounted) {
        _showToast(context, 'നിങ്ങൾ ഏറ്റവും പുതിയ പതിപ്പാണ് ഉപയോഗിക്കുന്നത് (v$currentVersion).');
      }
    } catch (e) {
      debugPrint('InAppUpdateService: checkForUpdates error: $e');
    }
  }

  /// Processes live snapshot data received from Admin App Firestore update.
  void _processUpdateData(
    Map<String, dynamic> data, {
    required int currentVersionCode,
    required String currentVersionName,
    required String source,
  }) {
    final parsed = _parseVersionData(data);
    final firestoreVersionCode = parsed['latest_version_code'] as int;
    final firestoreVersionName = parsed['latest_version'] as String;
    final apkUrl = parsed['apk_url'] as String;
    final releaseNotes = parsed['release_notes'] as String;

    debugPrint(
      'InAppUpdateService [$source]: Received Firestore update config -> '
      'Remote Code: $firestoreVersionCode, Version: $firestoreVersionName',
    );

    final isNewer = _isVersionNewer(
      latestVersion: firestoreVersionName,
      latestVersionCode: firestoreVersionCode,
      currentVersion: currentVersionName,
      currentBuild: currentVersionCode,
    );

    if (!isNewer) return;

    // Avoid showing duplicate dialog for the same version
    if (_currentlyShowingVersionCode == firestoreVersionCode) return;
    if (_dismissedVersionCode == firestoreVersionCode ||
        (_dismissedVersionName != null &&
            _dismissedVersionName == firestoreVersionName)) {
      debugPrint('InAppUpdateService: Update v$firestoreVersionCode already dismissed by user.');
      return;
    }

    // Trigger Android Notification on channel 'app_updates'
    NotificationManager.showUpdateNotification(
      latestVersion: firestoreVersionName.isNotEmpty ? firestoreVersionName : 'v$firestoreVersionCode',
      apkUrl: apkUrl.isNotEmpty ? apkUrl : defaultStoreUrl,
      releaseNotes: releaseNotes,
    );

    // Present non-blocking Telegram-style UI on current context
    void presentBanner(BuildContext ctx) {
      if (!ctx.mounted) return;
      _currentlyShowingVersionCode = firestoreVersionCode;

      showTelegramStyleUpdateSheet(
        ctx,
        latestVersion: firestoreVersionName.isNotEmpty ? firestoreVersionName : 'v$firestoreVersionCode',
        currentVersion: currentVersionName,
        apkUrl: apkUrl.isNotEmpty ? apkUrl : defaultStoreUrl,
        releaseNotes: releaseNotes,
        versionCode: firestoreVersionCode,
      );
    }

    final context = appNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      presentBanner(context);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final delayedCtx = appNavigatorKey.currentContext;
        if (delayedCtx != null && delayedCtx.mounted) {
          presentBanner(delayedCtx);
        }
      });
    }
  }

  /// Fetches version info from Firestore documents.
  Future<Map<String, dynamic>?> fetchRemoteVersionInfo() async {
    try {
      // 1. Primary: collection 'app_updates' -> doc 'latest'
      try {
        final doc = await FirebaseFirestore.instance
            .collection('app_updates')
            .doc('latest')
            .get(const GetOptions(source: Source.serverAndCache));

        if (doc.exists && doc.data() != null) {
          return _parseVersionData(doc.data()!);
        }
      } catch (e) {
        debugPrint('InAppUpdateService: fetch app_updates/latest error: $e');
      }

      // 2. Secondary: collection 'app_config' -> doc 'version_info'
      try {
        final doc = await FirebaseFirestore.instance
            .collection('app_config')
            .doc('version_info')
            .get(const GetOptions(source: Source.serverAndCache));

        if (doc.exists && doc.data() != null) {
          return _parseVersionData(doc.data()!);
        }
      } catch (e) {
        debugPrint('InAppUpdateService: fetch app_config/version_info error: $e');
      }

      // 3. Fallback: collection 'app_config' -> doc 'version_control'
      try {
        final doc = await FirebaseFirestore.instance
            .collection('app_config')
            .doc('version_control')
            .get(const GetOptions(source: Source.serverAndCache));

        if (doc.exists && doc.data() != null) {
          return _parseVersionData(doc.data()!);
        }
      } catch (e) {
        debugPrint('InAppUpdateService: fetch app_config/version_control error: $e');
      }

      // 4. Fallback: collection 'app_updates' (most recent entry)
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('app_updates')
            .orderBy('id', descending: true)
            .limit(1)
            .get(const GetOptions(source: Source.serverAndCache));

        if (snapshot.docs.isNotEmpty) {
          return _parseVersionData(snapshot.docs.first.data());
        }
      } catch (e) {
        debugPrint('InAppUpdateService: fetch app_updates collection error: $e');
      }
    } catch (e) {
      debugPrint('InAppUpdateService: fetchRemoteVersionInfo general error: $e');
    }
    return null;
  }

  Map<String, dynamic> _parseVersionData(Map<String, dynamic> data) {
    final latestVersion = (data['version_name'] ??
            data['latest_version'] ??
            data['latest_version_name'] ??
            data['latestVersionName'] ??
            data['version'] ??
            '')
        .toString()
        .trim();

    final rawCode = data['version_code'] ??
        data['latest_version_code'] ??
        data['latestVersionCode'] ??
        data['versionCode'] ??
        data['build_number'] ??
        0;

    int latestVersionCode = 0;
    if (rawCode is num) {
      latestVersionCode = rawCode.toInt();
    } else if (rawCode != null) {
      latestVersionCode = int.tryParse(rawCode.toString()) ?? 0;
    }

    final apkUrl = (data['apk_url'] ??
            data['apkDownloadUrl'] ??
            data['apk_download_url'] ??
            data['playstore_url'] ??
            data['download_url'] ??
            data['url'] ??
            '')
        .toString()
        .trim();

    final releaseNotes = (data['release_notes'] ??
            data['releaseNotes'] ??
            data['notes'] ??
            data['whats_new'] ??
            data['changelog'] ??
            'പുതിയ ഫീച്ചറുകളും മെച്ചപ്പെട്ട പ്രകടനവും ഈ പതിപ്പിൽ ലഭ്യമാണ്.')
        .toString()
        .trim();

    return {
      'latest_version': latestVersion,
      'latest_version_code': latestVersionCode,
      'apk_url': apkUrl,
      'release_notes': releaseNotes,
    };
  }

  Future<PackageInfo> _getPackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return PackageInfo(
        appName: 'Kurichiyar Matrimony',
        packageName: 'com.example.kurichiyar_matrimony',
        version: '1.0.1',
        buildNumber: '2',
      );
    }
  }

  bool _isVersionNewer({
    required String latestVersion,
    required int latestVersionCode,
    required String currentVersion,
    required int currentBuild,
  }) {
    if (latestVersion.isEmpty && latestVersionCode <= 0) return false;

    // 1. Direct version_code comparison
    if (latestVersionCode > 0 && currentBuild > 0) {
      if (latestVersionCode > currentBuild) return true;
      if (latestVersionCode < currentBuild) return false;
    }

    // 2. Semantic version comparison
    try {
      final cleanLatest = latestVersion.split('+').first.trim();
      final cleanCurrent = currentVersion.split('+').first.trim();

      final latestParts = cleanLatest
          .split('.')
          .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
          .toList();
      final currentParts = cleanCurrent
          .split('.')
          .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
          .toList();

      final maxLen =
          latestParts.length > currentParts.length ? latestParts.length : currentParts.length;

      for (int i = 0; i < maxLen; i++) {
        final l = i < latestParts.length ? latestParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Telegram-Style Non-Blocking, Dismissible Bottom Sheet
  void showTelegramStyleUpdateSheet(
    BuildContext context, {
    required String latestVersion,
    required String currentVersion,
    required String apkUrl,
    required String releaseNotes,
    int? versionCode,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final isDark = theme.brightness == Brightness.dark;
        final primaryColor = theme.primaryColor;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E232A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(sheetContext).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle Pill
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 2. Telegram-Style Header & Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.system_update_alt_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'പുതിയ അപ്ഡേറ്റ് ലഭ്യമാണ്',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'പതിപ്പ്: $latestVersion (നിലവിലെ: v$currentVersion)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Release Notes Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262C36) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 15,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'പുതിയ മാറ്റങ്ങൾ (What\'s New)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      releaseNotes,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Action Buttons (Telegram Style):
              // Primary Button: "ഡൗൺലോഡ് / ഇൻസ്റ്റാൾ ചെയ്യുക"
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    _currentlyShowingVersionCode = null;
                    await _launchUpdateUrl(apkUrl);
                  },
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: const Text(
                    'ഡൗൺലോഡ് / ഇൻസ്റ്റാൾ ചെയ്യുക',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Dismiss Button: "പിന്നീട്" - Non-blocking
              SizedBox(
                width: double.infinity,
                height: 42,
                child: TextButton(
                  onPressed: () {
                    if (versionCode != null) {
                      _dismissedVersionCode = versionCode;
                    }
                    _dismissedVersionName = latestVersion;
                    _currentlyShowingVersionCode = null;
                    Navigator.of(sheetContext).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white60 : Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'പിന്നീട്',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      _currentlyShowingVersionCode = null;
    });
  }

  /// Telegram-Style Floating Card / SnackBar Alternative
  void showTelegramStyleFloatingBanner(
    BuildContext context, {
    required String latestVersion,
    required String apkUrl,
    required String releaseNotes,
    int? versionCode,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        elevation: 6,
        backgroundColor: const Color(0xFF1E232A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 15),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.system_update_rounded,
                color: primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'പുതിയ അപ്ഡേറ്റ് ലഭ്യമാണ്',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  Text(
                    releaseNotes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Dismiss action: "പിന്നീട്"
            GestureDetector(
              onTap: () {
                if (versionCode != null) {
                  _dismissedVersionCode = versionCode;
                }
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'പിന്നീട്',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Primary action: "ഡൗൺലോഡ് / ഇൻസ്റ്റാൾ ചെയ്യുക"
            ElevatedButton(
              onPressed: () async {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                await _launchUpdateUrl(apkUrl);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'ഇൻസ്റ്റാൾ ചെയ്യുക',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _launchUpdateUrl(String url) async {
    final target = url.isNotEmpty ? url : defaultStoreUrl;
    try {
      final uri = Uri.parse(target);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('InAppUpdateService: Could not launch $target');
      }
    } catch (e) {
      debugPrint('InAppUpdateService: URL launch error: $e');
    }
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
