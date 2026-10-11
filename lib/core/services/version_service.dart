import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/update_dialog.dart';

enum UpdateStatus { none, soft, critical }

class AppUpdateInfo {
  final int latestVersionCode;
  final String latestVersionName;
  final bool forceUpdate;
  final String releaseNotes;
  final String apkDownloadUrl;

  const AppUpdateInfo({
    required this.latestVersionCode,
    required this.latestVersionName,
    required this.forceUpdate,
    required this.releaseNotes,
    required this.apkDownloadUrl,
  });

  factory AppUpdateInfo.fromFirestore(Map<String, dynamic> data) {
    final rawCode = data['latestVersionCode'] ??
        data['versionCode'] ??
        data['version_code'];
    int vCode = 0;
    if (rawCode is num) {
      vCode = rawCode.toInt();
    } else if (rawCode != null) {
      vCode = int.tryParse(rawCode.toString()) ?? 0;
    }

    final isForce = data['forceUpdate'] == true ||
        data['isForceUpdate'] == true ||
        data['isCritical'] == true ||
        data['is_critical'] == true;

    return AppUpdateInfo(
      latestVersionCode: vCode,
      latestVersionName: (data['latestVersionName'] ??
              data['versionName'] ??
              data['version'] ??
              '1.0.0')
          .toString(),
      forceUpdate: isForce,
      releaseNotes: (data['releaseNotes'] ??
              data['notes'] ??
              data['changelog'] ??
              'കൂടുതൽ സുരക്ഷിതത്വത്തിനും മികച്ച സേവനത്തിനുമായി പുതിയ അപ്‌ഡേറ്റ് ഇപ്പോൾ ലഭ്യമാണ്.')
          .toString(),
      apkDownloadUrl: (data['apkDownloadUrl'] ??
              data['apkUrl'] ??
              data['downloadUrl'] ??
              data['apk_url'] ??
              '')
          .toString(),
    );
  }
}

class VersionService {
  static final VersionService instance = VersionService._internal();
  VersionService._internal();

  final ValueNotifier<double> downloadProgress = ValueNotifier<double>(0.0);

  /// Fetch remote configuration for version control from Cloud Firestore
  /// Document: app_config/version_control
  Future<AppUpdateInfo?> fetchVersionControl() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('version_control')
          .get(const GetOptions(source: Source.serverAndCache));

      if (doc.exists && doc.data() != null) {
        return AppUpdateInfo.fromFirestore(doc.data()!);
      }
    } catch (e) {
      debugPrint('VersionService: Firestore version_control fetch error: $e');
    }
    return null;
  }

  /// Automatically check for updates on launch and prompt user if a newer version is available
  Future<void> checkForUpdates({
    BuildContext? context,
    bool showNoUpdateDialog = false,
  }) async {
    try {
      // Direct APK installation applies primarily to Android
      if (kIsWeb || !Platform.isAndroid) return;

      final updateInfo = await fetchVersionControl();
      if (updateInfo == null || updateInfo.apkDownloadUrl.isEmpty) {
        if (showNoUpdateDialog && context != null && context.mounted) {
          _showUpToDateDialog(context);
        }
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 1;
      final currentVersionName = packageInfo.version;

      debugPrint(
        'VersionService Check -> Current: Build $currentVersionCode (v$currentVersionName), Latest: Build ${updateInfo.latestVersionCode} (v${updateInfo.latestVersionName})',
      );

      if (updateInfo.latestVersionCode > currentVersionCode) {
        if (context != null && context.mounted) {
          UpdateDialog.show(
            context,
            updateInfo: updateInfo,
            currentVersionName: currentVersionName,
            currentVersionCode: currentVersionCode,
          );
        }
      } else if (showNoUpdateDialog && context != null && context.mounted) {
        _showUpToDateDialog(context);
      }
    } catch (e) {
      debugPrint('VersionService.checkForUpdates exception: $e');
    }
  }

  void _showUpToDateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ആപ്പ് അപ്-ടു-ഡേറ്റ് ആണ്'),
        content: const Text(
          'നിങ്ങൾ നിലവിൽ ആപ്പിന്റെ ഏറ്റവും പുതിയ പതിപ്പാണ് ഉപയോഗിക്കുന്നത്.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ശരി'),
          ),
        ],
      ),
    );
  }

  /// Check if a new version was installed and record it in Supabase `update_logs`
  Future<void> checkAndLogInstalledVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final prefs = await SharedPreferences.getInstance();
      final lastLoggedVersion = prefs.getString(
        'last_logged_installed_version',
      );

      if (lastLoggedVersion != currentVersion) {
        await logUpdateInstallation(currentVersion);
        await prefs.setString('last_logged_installed_version', currentVersion);
      }
    } catch (e) {
      debugPrint('Error checking/logging installed version: $e');
    }
  }

  /// Inserts the user_id and version into the `update_logs` table in Supabase
  Future<void> logUpdateInstallation(String version) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final platformName = kIsWeb
          ? 'web'
          : (Platform.isAndroid
                ? 'android'
                : (Platform.isIOS ? 'ios' : 'other'));

      await Supabase.instance.client.from('update_logs').insert({
        if (user != null) 'user_id': user.id,
        'installed_version': version,
        'platform': platformName,
        'installed_at': DateTime.now().toIso8601String(),
      });
      debugPrint(
        'Update log inserted successfully into Supabase update_logs for version: $version',
      );
    } catch (e) {
      debugPrint('Failed to insert update log into update_logs: $e');
    }
  }

  Future<UpdateStatus> checkUpdateStatus() async {
    final updateInfo = await fetchVersionControl();
    if (updateInfo == null) return UpdateStatus.none;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentCode = int.tryParse(packageInfo.buildNumber) ?? 1;

    if (updateInfo.latestVersionCode > currentCode) {
      return updateInfo.forceUpdate
          ? UpdateStatus.critical
          : UpdateStatus.soft;
    }
    return UpdateStatus.none;
  }

  Future<void> downloadAndInstallUpdate() async {
    final updateInfo = await fetchVersionControl();
    if (updateInfo == null || updateInfo.apkDownloadUrl.isEmpty) return;

    downloadProgress.value = 0.01;
    try {
      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final savePath =
          '${dir.path}/update_${updateInfo.latestVersionCode}.apk';

      final dio = Dio();
      await dio.download(
        updateInfo.apkDownloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress.value = received / total;
          }
        },
      );

      downloadProgress.value = 1.0;
      await logUpdateInstallation(updateInfo.latestVersionName);
      await OpenFilex.open(savePath);
    } catch (e) {
      debugPrint('Error downloading update: $e');
      downloadProgress.value = 0.0;
    }
  }
}
