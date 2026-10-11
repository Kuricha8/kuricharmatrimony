import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../core/widgets/voiceover_player.dart';
import '../../core/utils/supabase_flexible_helper.dart';

class LivenessVerificationScreen extends StatefulWidget {
  final String userId;

  const LivenessVerificationScreen({super.key, required this.userId});

  @override
  State<LivenessVerificationScreen> createState() =>
      _LivenessVerificationScreenState();
}

enum LivenessStep { lookStraight, blink, turnHead }

class _LivenessVerificationScreenState extends State<LivenessVerificationScreen>
    with WidgetsBindingObserver {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
    ),
  );

  CameraController? _cameraController;
  VideoPlayerController? _videoPreviewController;

  bool _isProcessingImage = false;
  bool _hasFaceInFrame = false;
  bool _isStepTransitioning = false;
  bool _isLivenessPassed = false;
  bool _isRecording = false;
  bool _isPreviewingVideo = false;
  bool _isUploading = false;
  String _statusMessage = "ക്യാമറ റെഡിയാകുന്നു... (Initializing Camera...)";

  List<LivenessStep> _remainingSteps = [];
  LivenessStep? _currentStep;
  Timer? _fallbackTimer;
  Timer? _recordingCountdownTimer;
  int _recordingRemainingSeconds = 5;
  double _recordingProgress = 0.0;
  bool _showManualCapture = false;

  bool _lookedLeft = false;
  bool _lookedRight = false;

  XFile? _recordedVideoFile;

  static final Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    VoiceoverPlayer.instance.init();
    _initializeLivenessSteps();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fallbackTimer?.cancel();
    _recordingCountdownTimer?.cancel();
    try {
      _cameraController?.stopImageStream();
    } catch (_) {}
    _cameraController?.dispose();
    _cameraController = null;
    _videoPreviewController?.dispose();
    _videoPreviewController = null;
    _faceDetector.close();
    VoiceoverPlayer.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isPreviewingVideo) return;
    final cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized)
  { return; }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      try {
        _cameraController?.stopImageStream();
      } catch (_) {}
      _cameraController?.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  void _initializeLivenessSteps() {
    _remainingSteps = [
      LivenessStep.lookStraight,
      LivenessStep.blink,
      LivenessStep.turnHead,
    ];
    _currentStep = _remainingSteps.first;
    _lookedLeft = false;
    _lookedRight = false;
    _isLivenessPassed = false;
    _hasFaceInFrame = false;
    _isPreviewingVideo = false;
    _isStepTransitioning = false;
    _recordedVideoFile = null;
  }

  void _startFallbackTimer() {
    _fallbackTimer?.cancel();
    _showManualCapture = false;
    _fallbackTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && !_isLivenessPassed) {
        setState(() {
          _showManualCapture = true;
        });
      }
    });
  }

  Future<void> _initializeCamera() async {
    if (_cameraController != null) {
      try {
        await _cameraController!.stopImageStream();
      } catch (_) {}
      try {
        await _cameraController!.dispose();
      } catch (_) {}
      _cameraController = null;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _statusMessage = _getStepInstruction(_currentStep!);
        });
        _cameraController!.startImageStream(_processCameraImage);
        _speakStepPrompt(_currentStep!);
        _startFallbackTimer();
      }
    } catch (e) {
      debugPrint("Camera initialize error: $e");
      if (mounted) {
        setState(() {
          _statusMessage = "ക്യാമറ ആരംഭിക്കുന്നതിൽ തടസ്സം: $e";
        });
      }
    }
  }

  void _speakStepPrompt(LivenessStep step) {
    String text = "";
    switch (step) {
      case LivenessStep.lookStraight:
        text = "നേരെ നോക്കുക";
        break;
      case LivenessStep.blink:
        text = "കണ്ണുകൾ ചിമ്മുക";
        break;
      case LivenessStep.turnHead:
        text = "തല ഇടത്തോട്ടും വലത്തോട്ടും തിരിക്കുക";
        break;
    }
    VoiceoverPlayer.instance.speak(text);
  }

  String _getStepInstruction(LivenessStep step) {
    switch (step) {
      case LivenessStep.lookStraight:
        return "നേരെ നോക്കുക\n(Look Straight at the camera)";
      case LivenessStep.blink:
        return "കണ്ണുകൾ ചിമ്മുക\n(Blink your eyes)";
      case LivenessStep.turnHead:
        return "തല ഇടത്തോട്ടും വലത്തോട്ടും തിരിക്കുക\n(Turn head left & right)";
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessingImage ||
        _isLivenessPassed ||
        _cameraController == null ||
        _isPreviewingVideo ||
        _isStepTransitioning)
  { return; }
    _isProcessingImage = true;

    try {
      final camera = _cameraController!.description;
      final sensorOrientation = camera.sensorOrientation;

      InputImageRotation? rotation;
      if (defaultTargetPlatform == TargetPlatform.android) {
        var rotationCompensation =
            _orientations[_cameraController!.value.deviceOrientation];
        if (rotationCompensation != null) {
          if (camera.lensDirection == CameraLensDirection.front) {
            rotationCompensation =
                (sensorOrientation + rotationCompensation) % 360;
          } else {
            rotationCompensation =
                (sensorOrientation - rotationCompensation + 360) % 360;
          }
          rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      }
      rotation ??=
          InputImageRotationValue.fromRawValue(sensorOrientation) ??
          InputImageRotation.rotation270deg;

      final inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21;

      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImageMetadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageMetadata,
      );
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        if (_hasFaceInFrame && mounted) {
          setState(() {
            _hasFaceInFrame = false;
          });
        }
        _setStatusMessage(
          "മുഖം വ്യക്തമായി കാണിച്ച് വൃത്തത്തിന് നടുവിലാക്കുക...",
        );
      } else {
        if (!_hasFaceInFrame && mounted) {
          setState(() {
            _hasFaceInFrame = true;
          });
        }
        final face = faces.first;
        _evaluateLiveness(face);
      }
    } on Exception catch (convErr) {
      debugPrint("Camera frame InputImageConverter notice: $convErr");
    } catch (e) {
      debugPrint("Error processing image: $e");
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      _isProcessingImage = false;
    }
  }

  void _setStatusMessage(String msg) {
    if (mounted && _statusMessage != msg) {
      setState(() {
        _statusMessage = msg;
      });
    }
  }

  Future<void> _evaluateLiveness(Face face) async {
    if (_currentStep == null || _isStepTransitioning) return;
    bool passed = false;

    switch (_currentStep!) {
      case LivenessStep.lookStraight:
        if (face.headEulerAngleY != null && face.headEulerAngleX != null) {
          if (face.headEulerAngleY!.abs() <= 10 &&
              face.headEulerAngleX!.abs() <= 10) {
            passed = true;
          }
        } else {
          passed = true; // Fallback for basic face detection
        }
        break;

      case LivenessStep.blink:
        if (face.leftEyeOpenProbability != null &&
            face.rightEyeOpenProbability != null) {
          final leftProb = face.leftEyeOpenProbability!;
          final rightProb = face.rightEyeOpenProbability!;
          if (leftProb < 0.3 || rightProb < 0.3) {
            passed = true;
          }
        }
        break;

      case LivenessStep.turnHead:
        if (face.headEulerAngleY != null) {
          if (face.headEulerAngleY! > 15) setState(() => _lookedLeft = true);
          if (face.headEulerAngleY! < -15) setState(() => _lookedRight = true);
          if (_lookedLeft || _lookedRight) {
            passed = true;
          }
        }
        break;
    }

    if (passed) {
      _isStepTransitioning = true;
      HapticFeedback.heavyImpact();

      if (mounted) {
        setState(() {
          _statusMessage = "✅ ഘട്ടം വിജയകരം! (Step Passed!)";
        });
      }

      await Future.delayed(const Duration(seconds: 1));

      if (_remainingSteps.isNotEmpty) {
        _remainingSteps.removeAt(0);
      }

      if (_remainingSteps.isEmpty) {
        _fallbackTimer?.cancel();
        _completeLivenessTracking();
      } else {
        if (mounted) {
          setState(() {
            _currentStep = _remainingSteps.first;
            _showManualCapture = false;
            _isStepTransitioning = false;
          });
          _speakStepPrompt(_currentStep!);
          _setStatusMessage(
            "നന്നായിരിക്കുന്നു! അടുത്തത്:\n${_getStepInstruction(_currentStep!)}",
          );
          _startFallbackTimer();
        }
      }
    }
  }

  Future<void> _completeLivenessTracking() async {
    setState(() {
      _isLivenessPassed = true;
      _statusMessage =
          "ലൈവ്‌നെസ്സ് സ്ഥീരീകരിച്ചു! വീഡിയോ റെക്കോർഡ് ചെയ്യുന്നു...\n(Liveness verified! Recording 5s video...)";
    });

    try {
      await _cameraController?.stopImageStream();
    } catch (e) {
      debugPrint("stopImageStream notice: $e");
    }

    await Future.delayed(const Duration(milliseconds: 300));
    await _startVideoRecordingSequence();
  }

  Future<void> _startVideoRecordingSequence() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
  { return; }

    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingRemainingSeconds = 5;
        _recordingProgress = 0.0;
      });

      const int totalSteps = 50;
      int currentStep = 0;

      _recordingCountdownTimer?.cancel();
      _recordingCountdownTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (timer) async {
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
            final XFile file = await _cameraController!.stopVideoRecording();
            setState(() {
              _isRecording = false;
              _recordedVideoFile = file;
            });

            await _initVideoPreview(file);
          }
        },
      );
    } catch (e) {
      debugPrint("Error recording video: $e");
      _setStatusMessage("വീഡിയോ റെക്കോർഡിംഗിൽ തടസ്സം നേരിട്ടു: $e");
    }
  }

  /// Initialize Video Preview Controller for Review & Retake Screen
  Future<void> _initVideoPreview(XFile file) async {
    try {
      _videoPreviewController?.dispose();
      _videoPreviewController = VideoPlayerController.file(File(file.path));
      await _videoPreviewController!.initialize();
      await _videoPreviewController!.setLooping(true);
      await _videoPreviewController!.play();

      if (mounted) {
        setState(() {
          _isPreviewingVideo = true;
          _statusMessage =
              "വീഡിയോ വിലയിരുത്തി സമർപ്പിക്കുക അഥവാ വീണ്ടും എടുക്കുക";
        });
      }
    } catch (e) {
      debugPrint("Error initializing video preview: $e");
    }
  }

  /// Retake Action: Disposes preview player, resets state, and restarts camera
  Future<void> _retakeVideo() async {
    await _videoPreviewController?.pause();
    await _videoPreviewController?.dispose();
    _videoPreviewController = null;

    setState(() {
      _isPreviewingVideo = false;
      _isLivenessPassed = false;
      _recordedVideoFile = null;
      _statusMessage = "വീണ്ടും ആരംഭിക്കുന്നു...";
    });

    _initializeLivenessSteps();
    await _initializeCamera();
  }

  /// Submit Action: Uploads video to Supabase and marks status as pending_review
  Future<void> _submitVideoVerification() async {
    if (_recordedVideoFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final videoUrl =
          await uploadLivenessVideo(_recordedVideoFile!.path, widget.userId) ??
          '';

      // 2. Update Database Record in kurichiyar_profiles with flexible schema fallback
      await supabase.updateFlexibleProfile(
        table: 'kurichiyar_profiles',
        userId: widget.userId,
        payload: {
          'verification_video_url': videoUrl,
          'liveness_video_url': videoUrl,
          'verification_status': 'pending_review',
          'video_verification_status': 'pending',
          'liveness_status': 'SUBMITTED',
          'is_liveness_verified': false,
        },
      );

      // Clean up and pop screen
      _videoPreviewController?.dispose();
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
                    'വീഡിയോ വിജയകരമായി സമർപ്പിച്ചു! അഡ്മിൻ പരിശോധന പൂർത്തിയാകുമ്പോൾ അറിയിക്കുന്നതാണ്.',
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
      debugPrint("Upload error: $e");
      if (mounted) {
        setState(() {
          _isUploading = false;
          _statusMessage = "വീഡിയോ സമർപ്പിക്കുന്നതിൽ തടസ്സം നേരിട്ടു: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _isLivenessPassed
        ? Colors.greenAccent
        : (_hasFaceInFrame ? Colors.amberAccent : Colors.redAccent);

    return PopScope(
      canPop: !_isUploading && !_isRecording,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _cameraController?.dispose();
          _videoPreviewController?.dispose();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Top Action Bar with Back/Close Button & REC Badge
                  Padding(
                    padding: const EdgeInsets.all(16.0),
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
                              _videoPreviewController?.dispose();
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
                        Row(
                          children: [
                            if (_isRecording) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.redAccent),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.fiber_manual_record,
                                      color: Colors.redAccent,
                                      size: 12,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '🔴 REC',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Text(
                              'വീഡിയോ ലൈവ്‌നെസ്സ്',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Circular Camera Frame / Video Playback Review Frame
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 290,
                          height: 290,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: borderColor.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child:
                                _isPreviewingVideo &&
                                    _videoPreviewController != null &&
                                    _videoPreviewController!.value.isInitialized
                                ? AspectRatio(
                                    aspectRatio: _videoPreviewController!
                                        .value
                                        .aspectRatio,
                                    child: VideoPlayer(
                                      _videoPreviewController!,
                                    ),
                                  )
                                : (_cameraController != null &&
                                          _cameraController!.value.isInitialized
                                      ? CameraPreview(_cameraController!)
                                      : const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.amberAccent,
                                          ),
                                        )),
                          ),
                        ),

                        // Success Checkmark Badge overlay when step completes
                        if (_isLivenessPassed && !_isPreviewingVideo)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Status Message Banner
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
                          color: _isLivenessPassed
                              ? Colors.greenAccent
                              : (_hasFaceInFrame
                                    ? Colors.white
                                    : Colors.redAccent),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Linear Recording Progress Bar
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
                          const SizedBox(height: 6),
                          Text(
                            'റെക്കോർഡിംഗ് കഴിയാൻ: ${_recordingRemainingSeconds}s',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Manual Photo Capture / Skip Step Fallback Option
                  if (_showManualCapture &&
                      !_isLivenessPassed &&
                      !_isPreviewingVideo)
                    ElevatedButton.icon(
                      onPressed: () {
                        _fallbackTimer?.cancel();
                        setState(() {
                          _showManualCapture = false;
                          if (_remainingSteps.isNotEmpty) {
                            _remainingSteps.removeAt(0);
                          }
                          if (_remainingSteps.isEmpty) {
                            _completeLivenessTracking();
                          } else {
                            _currentStep = _remainingSteps.first;
                            _speakStepPrompt(_currentStep!);
                            _statusMessage =
                                "നന്നായിരിക്കുന്നു! അടുത്തത്:\n${_getStepInstruction(_currentStep!)}";
                            _startFallbackTimer();
                          }
                        });
                      },
                      icon: const Icon(Icons.skip_next),
                      label: const Text('ഈ ഘട്ടം സ്കിപ്പ് ചെയ്യുക (Skip Step)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Review & Retake Actions (Show when recording is finished)
                  if (_isPreviewingVideo && !_isUploading)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          // Retake Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _retakeVideo,
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.amberAccent,
                              ),
                              label: const Text(
                                'വീണ്ടും എടുക്കുക',
                                style: TextStyle(
                                  color: Colors.amberAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.amberAccent,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Submit Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _submitVideoVerification,
                              icon: const Icon(
                                Icons.cloud_upload,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'സമർപ്പിക്കുക',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22C55E),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
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
                            'വെരിഫിക്കേഷൻ വീഡിയോ സമർപ്പിക്കുന്നു...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'ദയവായി കാത്തിരിക്കുക (Uploading Video...)',
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
