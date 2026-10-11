import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PhotoValidationResult {
  final bool isValid;
  final String? errorMessageMl;

  const PhotoValidationResult({
    required this.isValid,
    this.errorMessageMl,
  });

  static const PhotoValidationResult success =
      PhotoValidationResult(isValid: true);

  static PhotoValidationResult failure(String messageMl) =>
      PhotoValidationResult(isValid: false, errorMessageMl: messageMl);
}

class PhotoQualityValidatorService {
  PhotoQualityValidatorService._();
  static final PhotoQualityValidatorService instance =
      PhotoQualityValidatorService._();

  static const String kTextBlockedMsg =
      'ഫോട്ടോയിൽ ഫോൺ നമ്പറോ സോഷ്യൽ മീഡിയ ഐഡികളോ ഉൾപ്പെടുത്താൻ പാടില്ല. യഥാർത്ഥ ഫോട്ടോ മാത്രം അപ്ലോഡ് ചെയ്യുക.';

  static const String kFaceNotClearMsg =
      'മുഖം വ്യക്തമായി കാണുന്നില്ല. മാസ്ക്, ഹെൽമെറ്റ് എന്നിവ ഒഴിവാക്കി നേരെ നോക്കുന്ന വ്യക്തമായ ചിത്രം നൽകുക.';

  static const String kMultipleFacesMsg =
      'ഫോട്ടോയിൽ ഒന്നിൽ കൂടുതൽ ആളുകൾ പാടില്ല. നിങ്ങളുടെ മാത്രം ചിത്രം നൽകുക.';

  static const String kFullLengthMissingMsg =
      'ഒരു ഫുൾ സൈസ് ഫോട്ടോ നിർബന്ധമാണ്. ഫുൾ ഫോട്ടോ അപ്ലോഡ് ചെയ്യാതെ പ്രൊഫൈൽ സേവ് ചെയ്യാൻ കഴിയില്ല.';

  static const String kFullLengthPoseErrorMsg =
      'ദയവായി തല മുതൽ കാൽ വരെ വ്യക്തമായി കാണുന്ന പൂർണ്ണകായ ചിത്രം അപ്ലോഡ് ചെയ്യുക.';

  /// Validates a photo for text/contact leaks and face clarity/pose before upload
  Future<PhotoValidationResult> validateProfilePhoto(
    File file, {
    bool isFullLength = false,
  }) async {
    try {
      final inputImage = InputImage.fromFile(file);

      // 1. Text & Contact Details Blocker (OCR)
      final textCheck = await _checkTextAndContacts(inputImage);
      if (!textCheck.isValid) {
        return textCheck;
      }

      if (isFullLength) {
        // Dedicated Full-Length Pose & Ratio Verification
        return await validateFullLengthPhoto(file, inputImage: inputImage);
      }

      // 2. Face Clarity, Obstruction, and Orientation Check (for Close-up)
      final faceCheck = await _checkFaceClarity(inputImage, isFullLength: false);
      if (!faceCheck.isValid) {
        return faceCheck;
      }

      return PhotoValidationResult.success;
    } catch (e) {
      debugPrint('PhotoQualityValidator note: $e');
      return PhotoValidationResult.success;
    }
  }

  /// Verifies Full-Length Photo: Vertical Portrait Ratio (3:4 or 9:16) and Pose Detection (shoulders, hips, lower body)
  Future<PhotoValidationResult> validateFullLengthPhoto(
    File file, {
    InputImage? inputImage,
  }) async {
    try {
      final image = inputImage ?? InputImage.fromFile(file);

      // 1. Aspect Ratio Verification: Ensure vertical portrait (3:4 or 9:16)
      try {
        final bytes = await file.readAsBytes();
        final decodedImage = await decodeImageFromList(bytes);
        final width = decodedImage.width;
        final height = decodedImage.height;

        // Reject landscape orientations (width >= height) or square close-ups (height/width < 1.15)
        if (width >= height || (height / width) < 1.15) {
          return PhotoValidationResult.failure(kFullLengthPoseErrorMsg);
        }
      } catch (dimErr) {
        debugPrint('Dimension check fallback note: $dimErr');
      }

      // 2. Google ML Kit Pose Detection: ensure body points (shoulders, hips, and lower body) are detected
      final poseCheck = await _checkPoseDetection(image);
      if (!poseCheck.isValid) {
        return poseCheck;
      }

      // 3. Face Clarity & Obstruction Check for full-length photo
      final faceCheck = await _checkFaceClarity(image, isFullLength: true);
      if (!faceCheck.isValid) {
        return faceCheck;
      }

      return PhotoValidationResult.success;
    } catch (e) {
      debugPrint('validateFullLengthPhoto note: $e');
      return PhotoValidationResult.success;
    }
  }

  /// Pose Detection: verifies shoulders, hips, and lower body points
  Future<PhotoValidationResult> _checkPoseDetection(InputImage inputImage) async {
    PoseDetector? poseDetector;
    try {
      final options = PoseDetectorOptions(
        mode: PoseDetectionMode.single,
        model: PoseDetectionModel.accurate,
      );
      poseDetector = PoseDetector(options: options);
      final List<Pose> poses = await poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        return PhotoValidationResult.failure(kFullLengthPoseErrorMsg);
      }

      final pose = poses.first;
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
      final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
      final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
      final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

      // Shoulders detection
      final hasShoulder = (leftShoulder != null && leftShoulder.likelihood > 0.3) ||
          (rightShoulder != null && rightShoulder.likelihood > 0.3);

      // Hips detection
      final hasHip = (leftHip != null && leftHip.likelihood > 0.3) ||
          (rightHip != null && rightHip.likelihood > 0.3);

      // Lower body detection (knees or ankles)
      final hasLowerBody = (leftKnee != null && leftKnee.likelihood > 0.25) ||
          (rightKnee != null && rightKnee.likelihood > 0.25) ||
          (leftAnkle != null && leftAnkle.likelihood > 0.25) ||
          (rightAnkle != null && rightAnkle.likelihood > 0.25);

      if (!hasShoulder || !hasHip || !hasLowerBody) {
        return PhotoValidationResult.failure(kFullLengthPoseErrorMsg);
      }

      return PhotoValidationResult.success;
    } catch (e) {
      debugPrint('Pose detection error: $e');
      return PhotoValidationResult.success;
    } finally {
      poseDetector?.close();
    }
  }

  /// Scans for phone numbers (sequences of digits) and social media handles/links
  Future<PhotoValidationResult> _checkTextAndContacts(InputImage inputImage) async {
    TextRecognizer? textRecognizer;
    try {
      textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      final fullText = recognizedText.text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

      if (fullText.isEmpty) {
        return PhotoValidationResult.success;
      }

      // 1. Phone number check: sequences of 10 digits or phone patterns
      final digitsOnly = fullText.replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.length >= 10) {
        return PhotoValidationResult.failure(kTextBlockedMsg);
      }

      final phoneRegex = RegExp(
        r'(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,5}[-.\s]?\d{3,5}',
      );
      final rawDigitsRegex = RegExp(r'\d{10,}');
      if (rawDigitsRegex.hasMatch(fullText) ||
          (phoneRegex.hasMatch(fullText) && digitsOnly.length >= 8)) {
        return PhotoValidationResult.failure(kTextBlockedMsg);
      }

      // 2. Social media handles and keywords scan ('@', 'insta', 'fb', 'snap', 'wa.me', etc.)
      final socialKeywords = [
        '@',
        'insta',
        'instagram',
        'fb',
        'facebook',
        'snap',
        'snapchat',
        'wa.me',
        'whatsapp',
        'telegram',
        't.me',
      ];

      for (final keyword in socialKeywords) {
        if (fullText.contains(keyword)) {
          return PhotoValidationResult.failure(kTextBlockedMsg);
        }
      }

      // Check contact words
      final contactKeywords = ['phone', 'call', 'mob', 'contact'];
      for (final keyword in contactKeywords) {
        final wordRegex = RegExp('\\b$keyword\\b');
        if (wordRegex.hasMatch(fullText)) {
          return PhotoValidationResult.failure(kTextBlockedMsg);
        }
      }

      return PhotoValidationResult.success;
    } catch (e) {
      debugPrint('OCR Check exception: $e');
      return PhotoValidationResult.success;
    } finally {
      textRecognizer?.close();
    }
  }

  /// Verifies face clarity, single prominent face, head rotation within +/- 20 degrees, and unobscured landmarks
  Future<PhotoValidationResult> _checkFaceClarity(
    InputImage inputImage, {
    bool isFullLength = false,
  }) async {
    FaceDetector? faceDetector;
    try {
      final options = FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: isFullLength ? 0.05 : 0.15,
      );

      faceDetector = FaceDetector(options: options);
      final List<Face> faces = await faceDetector.processImage(inputImage);

      // Verify that exactly one human face is prominently visible
      if (faces.isEmpty) {
        if (isFullLength) {
          return PhotoValidationResult.failure(kFullLengthPoseErrorMsg);
        }
        return PhotoValidationResult.failure(kFaceNotClearMsg);
      }

      if (faces.length > 1) {
        return PhotoValidationResult.failure(kMultipleFacesMsg);
      }

      final face = faces.first;

      // Check face orientation/rotation (head Euler Y/Z angles should be within +/- 20 degrees - front-facing only)
      final double? yaw = face.headEulerAngleY; // Head turned left/right
      final double? roll = face.headEulerAngleZ; // Head tilted sideways
      final double? pitch = face.headEulerAngleX; // Head tilted up/down

      if (yaw != null && (yaw < -20.0 || yaw > 20.0)) {
        return PhotoValidationResult.failure(kFaceNotClearMsg);
      }

      if (roll != null && (roll < -20.0 || roll > 20.0)) {
        return PhotoValidationResult.failure(kFaceNotClearMsg);
      }

      if (pitch != null && (pitch < -20.0 || pitch > 20.0)) {
        return PhotoValidationResult.failure(kFaceNotClearMsg);
      }

      // Ensure facial landmarks (eyes, nose, mouth) are not obstructed by masks, helmets, or severe shadows
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];
      final noseBase = face.landmarks[FaceLandmarkType.noseBase];
      final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];

      if (leftEye == null ||
          rightEye == null ||
          noseBase == null ||
          bottomMouth == null) {
        return PhotoValidationResult.failure(kFaceNotClearMsg);
      }

      return PhotoValidationResult.success;
    } catch (e) {
      debugPrint('Face Check exception: $e');
      return PhotoValidationResult.success;
    } finally {
      faceDetector?.close();
    }
  }
}
