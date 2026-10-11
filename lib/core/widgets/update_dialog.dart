import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/version_service.dart';

class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;
  final String currentVersionName;
  final int currentVersionCode;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.currentVersionName,
    required this.currentVersionCode,
  });

  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo updateInfo,
    required String currentVersionName,
    required int currentVersionCode,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (ctx) => PopScope(
        canPop: !updateInfo.forceUpdate,
        child: UpdateDialog(
          updateInfo: updateInfo,
          currentVersionName: currentVersionName,
          currentVersionCode: currentVersionCode,
        ),
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';
  String? _errorMessage;
  StreamSubscription<OtaEvent>? _otaSubscription;
  CancelToken? _dioCancelToken;

  @override
  void dispose() {
    _otaSubscription?.cancel();
    _dioCancelToken?.cancel();
    super.dispose();
  }

  Future<void> _startUpdate() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _progress = 0.01;
      _statusText = 'ഡൗൺലോഡ് തയ്യാറാക്കുന്നു... (Preparing)';
      _errorMessage = null;
    });

    try {
      // 1. Request install packages permission if needed on Android
      if (Platform.isAndroid) {
        final installStatus = await Permission.requestInstallPackages.status;
        if (!installStatus.isGranted) {
          await Permission.requestInstallPackages.request();
        }
      }

      // 2. Trigger OTA Update
      final filename =
          'kurichiyar_matrimony_${widget.updateInfo.latestVersionCode}.apk';

      _otaSubscription = OtaUpdate()
          .execute(
            widget.updateInfo.apkDownloadUrl,
            destinationFilename: filename,
          )
          .listen(
            (OtaEvent event) {
              if (!mounted) return;
              switch (event.status) {
                case OtaStatus.DOWNLOADING:
                  final parsedVal = double.tryParse(event.value ?? '0') ?? 0.0;
                  setState(() {
                    _progress = (parsedVal / 100.0).clamp(0.0, 1.0);
                    _statusText =
                        'ഡൗൺലോഡ് പുരോഗമിക്കുന്നു... ${(parsedVal).toInt()}%';
                  });
                  break;

                case OtaStatus.INSTALLING:
                  setState(() {
                    _progress = 1.0;
                    _statusText = 'ഇൻസ്റ്റാളേഷൻ ആരംഭിക്കുന്നു...';
                  });
                  break;

                case OtaStatus.ALREADY_RUNNING_ERROR:
                  setState(() {
                    _statusText = 'ഡൗൺലോഡ് ഇതിനകം പ്രവർത്തിക്കുന്നുണ്ട്.';
                  });
                  break;

                case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                  debugPrint('OTA Permission not granted, falling back to Dio');
                  _fallbackDownloadWithDio();
                  break;

                case OtaStatus.INTERNAL_ERROR:
                case OtaStatus.DOWNLOAD_ERROR:
                case OtaStatus.CHECKSUM_ERROR:
                default:
                  debugPrint('OTA Error: ${event.status}, falling back to Dio');
                  _fallbackDownloadWithDio();
                  break;
              }
            },
            onError: (err) {
              debugPrint('OTA Stream Exception: $err, falling back to Dio');
              _fallbackDownloadWithDio();
            },
          );
    } catch (e) {
      debugPrint('OTA execute failed: $e. Initiating fallback download.');
      _fallbackDownloadWithDio();
    }
  }

  /// Reliable fallback using Dio + OpenFilex if OTA Update encounters platform restrictions
  Future<void> _fallbackDownloadWithDio() async {
    _otaSubscription?.cancel();
    _otaSubscription = null;

    try {
      setState(() {
        _statusText = 'നേരിട്ട് ഡൗൺലോഡ് ചെയ്യുന്നു... (Direct Download)';
      });

      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final savePath =
          '${dir.path}/kurichiyar_matrimony_${widget.updateInfo.latestVersionCode}.apk';

      _dioCancelToken = CancelToken();
      final dio = Dio();

      await dio.download(
        widget.updateInfo.apkDownloadUrl,
        savePath,
        cancelToken: _dioCancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _progress = (received / total).clamp(0.0, 1.0);
              _statusText =
                  'ഡൗൺലോഡ് പുരോഗമിക്കുന്നു... ${(_progress * 100).toInt()}%';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _progress = 1.0;
          _statusText = 'ഇൻസ്റ്റാളർ തുറക്കുന്നു... (Opening Installer)';
        });
      }

      final result = await OpenFilex.open(savePath);
      debugPrint('OpenFilex install result: ${result.type} - ${result.message}');

      if (result.type != ResultType.done && mounted) {
        setState(() {
          _errorMessage =
              'ഇൻസ്റ്റാളർ തുറക്കാൻ കഴിഞ്ഞില്ല. ബ്രൗസറിൽ ഡൗൺലോഡ് ചെയ്യുക.';
        });
      }
    } catch (e) {
      debugPrint('Fallback Dio download failed: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'ഡൗൺലോഡ് പരാജയപ്പെട്ടു. ബ്രൗസറിൽ നേരിട്ട് തുറക്കുക.';
        });
      }
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.updateInfo.apkDownloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForce = widget.updateInfo.forceUpdate;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Badge / Icon
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF000080), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000080).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Title
            const Text(
              'പുതിയ അപ്‌ഡേറ്റ് ലഭ്യമാണ്!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 6),

            // Version Tag
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF8FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBEE3F8)),
                ),
                child: Text(
                  'v${widget.updateInfo.latestVersionName} (Build ${widget.updateInfo.latestVersionCode})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2B6CB0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Current Version info
            Text(
              'നിലവിലെ പതിപ്പ്: v${widget.currentVersionName} (Build ${widget.currentVersionCode})',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Release Notes Box
            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          size: 16,
                          color: Color(0xFF000080),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'പുതിയ മാറ്റങ്ങൾ (Release Notes):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.updateInfo.releaseNotes,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Progress or Error state
            if (_isDownloading) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _statusText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFEDF2F7),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF000080),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ഡൗൺലോഡ് പൂർത്തിയാകുമ്പോൾ ഇൻസ്റ്റാളർ തനിയെ തുറക്കും.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
            ],

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openInBrowser,
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: const Text('ബ്രൗസറിൽ ഡൗൺലോഡ് ചെയ്യുക'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF000080),
                  side: const BorderSide(color: Color(0xFF000080)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            if (!_isDownloading) ...[
              ElevatedButton.icon(
                onPressed: _startUpdate,
                icon: const Icon(Icons.download_rounded, size: 20),
                label: const Text(
                  'ഇപ്പോൾ അപ്‌ഡേറ്റ് ചെയ്യുക (Update Now)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
              if (!isForce) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'പിന്നീട് (Later)',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 10),
                Text(
                  'തുടർന്ന് ഉപയോഗിക്കാൻ ഈ അപ്‌ഡേറ്റ് നിർബന്ധമാണ് (Required)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
