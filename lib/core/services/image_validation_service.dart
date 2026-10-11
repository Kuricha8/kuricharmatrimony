import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'media_conversion_service.dart';
import 'photo_quality_validator_service.dart';

/// Service that provides AI-powered backend validation of profile images and IDs.
class ImageValidationService {
  /// Scans an uploaded ID document for government keywords.
  /// Returns the path to the validated image (which may have been converted to standard format).
  static Future<String> validateIdDocument(String filePath) async {
    filePath = await MediaConversionService.ensureStandardImageFormat(filePath);
    final inputImage = InputImage.fromFilePath(filePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      final String text = recognizedText.text.toUpperCase();

      final validKeywords = [
        'GOVERNMENT',
        'INDIA',
        'AADHAAR',
        'VOTER',
        'ELECTION',
        'COMMISSION',
        'PAN',
        'INCOME TAX',
        'DRIVING',
        'PASSPORT',
        'REPUBLIC',
      ];

      bool isValid = false;
      for (final keyword in validKeywords) {
        if (text.contains(keyword)) {
          isValid = true;
          break;
        }
      }

      if (!isValid) {
        throw Exception(
          'ദയവായി ഒരു സാധുവായ തിരിച്ചറിയൽ രേഖ (ID Card) അപ്‌ലോഡ് ചെയ്യുക.',
        );
      }
      return filePath;
    } finally {
      textRecognizer.close();
    }
  }

  /// Analyzes an image file to ensure exactly ONE human face is present,
  /// that it is clear and front-facing, and that it contains no contact info,
  /// social media handles, or OCR text leaks.
  /// Returns the path to the validated image.
  static Future<String> validateProfileImage(
    String filePath, {
    bool isFullLength = false,
  }) async {
    filePath = await MediaConversionService.ensureStandardImageFormat(filePath);
    final file = File(filePath);

    final validationResult = await PhotoQualityValidatorService.instance
        .validateProfilePhoto(file, isFullLength: isFullLength);

    if (!validationResult.isValid) {
      throw Exception(
        validationResult.errorMessageMl ??
            PhotoQualityValidatorService.kFaceNotClearMsg,
      );
    }

    return filePath;
  }

  static bool isImageBrightAndClear(String filePath) {
    // Placeholder for actual byte-level luminosity calculation.
    // Relies on ML Kit's face detection drops for blurriness.
    return true;
  }

  static Future<void> callServerModerationAPI(String filePath) async {
    // Stub for Supabase Edge Function / Google Cloud Vision API
    // If flagged by backend, it would throw:
    // throw Exception('ഈ ചിത്രം കമ്മ്യൂണിറ്റി മാനദണ്ഡങ്ങൾക്ക് വിരുദ്ധമാണ്. അനുയോജ്യമായ യഥാർത്ഥ ഫോട്ടോ നൽകുക.');
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
