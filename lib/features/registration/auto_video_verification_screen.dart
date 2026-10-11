import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/supabase_flexible_helper.dart';

/// Fully Automated Video Verification Screen with 3-2-1 Countdown,
/// 5-second Auto-Recording, and Auto-Upload to Supabase Storage.
class AutoVideoVerificationScreen extends StatefulWidget {
  final String userId;

  const AutoVideoVerificationScreen({super.key, required this.userId});

  static Future<void> start(
    BuildContext context, {
    required String userId,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AutoVideoVerificationScreen(userId: userId),
      ),
    );
  }

  @override
  State<AutoVideoVerificationScreen> createState() =>
      _AutoVideoVerificationScreenState();
}

class _AutoVideoVerificationScreenState
    extends State<AutoVideoVerificationScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  // Countdown & Recording states
  bool _isCountingDown = true;
  int _countdownSeconds = 3;
  Timer? _countdownTimer;

  bool _isRecording = false;
  int _recordingRemainingSeconds = 5;
  double _recordingProgress = 0.0;
  Timer? _recordingTimer;

  bool _isUploading = false;
  String _statusMessage = 'à´•àµà´¯à´¾à´®à´± à´±àµ†à´¡à´¿à´¯à´¾à´•àµà´¨àµà´¨àµ... (Initializing Camera...)';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAutoRecordingSequence();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized)
  { return; }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraController?.dispose();
      _cameraController = null;
      setState(() {
        _isCameraInitialized = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      _startAutoRecordingSequence();
    }
  }

  /// 1. Initialize front camera & launch 3-2-1 countdown
  Future<void> _startAutoRecordingSequence() async {
    if (_cameraController != null) {
      try {
        await _cameraController!.dispose();
      } catch (_) {}
      _cameraController = null;
    }

    try {
      // Request Camera and Microphone permissions
      await Permission.camera.request();
      await Permission.microphone.request();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _statusMessage = 'à´•àµà´¯à´¾à´®à´± à´²à´­àµà´¯à´®à´²àµà´² (No Camera Available)';
          });
        }
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _statusMessage = 'à´µàµ€à´¡à´¿à´¯àµ‹ à´±àµ†à´•àµà´•àµ‹àµ¼à´¡à´¿à´‚à´—àµ à´†à´°à´‚à´­à´¿à´•àµà´•à´¾àµ» à´ªàµ‹à´•àµà´¨àµà´¨àµ...';
      });

      // Start 3-2-1 Countdown
      _runCountdown();
    } catch (e) {
      debugPrint('[AUTO_VIDEO] Camera init error: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'à´•àµà´¯à´¾à´®à´± à´†à´°à´‚à´­à´¿à´•àµà´•àµà´¨àµà´¨à´¤à´¿àµ½ à´¤à´Ÿà´¸àµà´¸à´‚ à´¨àµ‡à´°à´¿à´Ÿàµà´Ÿàµ: $e';
        });
      }
    }
  }

  /// 2. Run 3-2-1 Countdown Overlay
  void _runCountdown() {
    _countdownSeconds = 3;
    _isCountingDown = true;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _isCountingDown = false;
        });
        _beginRecording();
      } else {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  /// 3. Begin 5-Second Video Recording
  Future<void> _beginRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
  { return; }

    try {
      await _cameraController!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _recordingRemainingSeconds = 5;
        _recordingProgress = 0.0;
        _statusMessage =
            'à´¤à´² à´ªà´¤àµà´•àµà´•àµ† à´‡à´°àµà´µà´¶à´™àµà´™à´³à´¿à´²àµ‡à´•àµà´•àµà´‚ à´¤à´¿à´°à´¿à´•àµà´•àµà´•...\n(Blink & turn head slowly...)';
      });

      const int totalSteps = 50; // 5 seconds * 10 steps per sec
      int currentStep = 0;

      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) async {
        if (!mounted) {
          timer.cancel();
          return;
        }

        currentStep++;
        setState(() {
          _recordingProgress = currentStep / totalSteps;
          _recordingRemainingSeconds = (5 - (currentStep / 10)).ceil();
        });

        if (currentStep >= totalSteps) {
          timer.cancel();
          await _stopAndUploadRecording();
        }
      });
    } catch (e) {
      debugPrint('[AUTO_VIDEO] Start recording error: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _statusMessage = 'à´±àµ†à´•àµà´•àµ‹àµ¼à´¡à´¿à´‚à´—àµ à´†à´°à´‚à´­à´¿à´•àµà´•à´¾àµ» à´¸à´¾à´§à´¿à´šàµà´šà´¿à´²àµà´²: $e';
        });
      }
    }
  }

  /// 4. Auto-Stop Recording and Upload to Supabase Storage & Profile Table
  Future<void> _stopAndUploadRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo)
  { return; }

    try {
      final XFile videoFile = await _cameraController!.stopVideoRecording();

      setState(() {
        _isRecording = false;
        _isUploading = true;
        _statusMessage =
            'à´µàµ†à´°à´¿à´«à´¿à´•àµà´•àµ‡à´·àµ» à´µàµ€à´¡à´¿à´¯àµ‹ à´¸à´®àµ¼à´ªàµà´ªà´¿à´•àµà´•àµà´¨àµà´¨àµ...\n(Uploading Verification Video...)';
      });

      final supabase = Supabase.instance.client;
      final userId = widget.userId.isNotEmpty
          ? widget.userId
          : (supabase.auth.currentUser?.id ?? 'guest');
      final videoUrl = await uploadLivenessVideo(videoFile.path, userId) ?? '';

      // Update User Profile status in Supabase table with flexible schema fallback
      try {
        await supabase.updateFlexibleProfile(
          table: 'kurichiyar_profiles',
          userId: userId,
          payload: {
            'verification_video_url': videoUrl,
            'verification_status': 'pending_review',
          },
        );
      } catch (dbErr) {
        debugPrint('[AUTO_VIDEO] DB update notice: $dbErr');
      }

      // Update Firestore documents across users and kurichiyar_profiles
      try {
        final fsPayload = {
          'video_kyc_status': 'submitted',
          'video_kyc_required': false,
          'video_kyc_url': videoUrl,
          'video_kyc_submitted_at': FieldValue.serverTimestamp(),
          'force_screen_override': FieldValue.delete(),
        };
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set(fsPayload, SetOptions(merge: true));
        await FirebaseFirestore.instance
            .collection('kurichiyar_profiles')
            .doc(userId)
            .set(fsPayload, SetOptions(merge: true));
      } catch (fsErr) {
        debugPrint('[AUTO_VIDEO] Firestore update notice: ');
      }

      // Cleanup memory & navigate back with success feedback
      await _cameraController?.dispose();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'à´µàµ†à´°à´¿à´«à´¿à´•àµà´•àµ‡à´·àµ» à´µàµ€à´¡à´¿à´¯àµ‹ à´µà´¿à´œà´¯à´•à´°à´®à´¾à´¯à´¿ à´¸à´®àµ¼à´ªàµà´ªà´¿à´šàµà´šàµ!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      debugPrint('[AUTO_VIDEO] Upload error: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
          _statusMessage = 'à´µàµ€à´¡à´¿à´¯àµ‹ à´…à´ªàµâ€Œà´²àµ‹à´¡à´¿à´‚à´—à´¿àµ½ à´¤à´Ÿà´¸àµà´¸à´‚ à´¨àµ‡à´°à´¿à´Ÿàµà´Ÿàµ: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isUploading && !_isRecording,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _cameraController?.dispose();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Stack(
            children: [
              // Main Layout
              Column(
                children: [
                  // Top Header Navigation Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (!_isUploading && !_isRecording && mounted) {
                              _cameraController?.dispose();
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/home');
                              }
                            }
                          },
                        ),
                        const Text(
                          'à´µàµ€à´¡à´¿à´¯àµ‹ à´¸àµà´¥à´¿à´°àµ€à´•à´°à´£à´‚',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance close icon space
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Circular Camera Frame Preview with Animated Border
                  Center(
                    child: Container(
                      width: 290,
                      height: 290,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isRecording
                              ? Colors.redAccent
                              : (_isCountingDown
                                    ? Colors.amberAccent
                                    : Colors.greenAccent),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isRecording
                                        ? Colors.redAccent
                                        : Colors.amberAccent)
                                    .withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _isCameraInitialized && _cameraController != null
                            ? CameraPreview(_cameraController!)
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.amberAccent,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dynamic Instructions / Status Box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isRecording
                              ? Colors.amberAccent
                              : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Linear Progress Bar During 5s Recording
                  if (_isRecording)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _recordingProgress,
                              minHeight: 8,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.redAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'à´±àµ†à´•àµà´•àµ‹àµ¼à´¡à´¿à´‚à´—àµ à´•à´´à´¿à´¯à´¾àµ»: ${_recordingRemainingSeconds}s',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),
                ],
              ),

              // 3-2-1 Countdown Big Overlay
              if (_isCameraInitialized && _isCountingDown)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.65),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber.shade800.withValues(
                                alpha: 0.85,
                              ),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.amber,
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Text(
                              '$_countdownSeconds',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'à´±àµ†à´•àµà´•àµ‹àµ¼à´¡à´¿à´‚à´—àµ à´†à´°à´‚à´­à´¿à´•àµà´•àµà´¨àµà´¨àµ...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Uploading Spinner Overlay
              if (_isUploading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.8),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.greenAccent,
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'à´µàµ†à´°à´¿à´«à´¿à´•àµà´•àµ‡à´·àµ» à´µàµ€à´¡à´¿à´¯àµ‹ à´¸à´®àµ¼à´ªàµà´ªà´¿à´•àµà´•àµà´¨àµà´¨àµ...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'à´¦à´¯à´µà´¾à´¯à´¿ à´•à´¾à´¤àµà´¤à´¿à´°à´¿à´•àµà´•àµà´• (Uploading Video...)',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
