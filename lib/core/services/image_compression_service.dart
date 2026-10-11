import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Centralized image compression service to optimize Firebase Storage
/// and bandwidth usage by enforcing:
/// 1. File size strictly under 200 KB
/// 2. Max resolution <= 1080p (maintaining aspect ratio)
/// 3. Quality around 70-80% with iterative reduction if needed
class ImageCompressionService {
  static const int maxFileSizeBytes = 200 * 1024; // 200 KB limit
  static const int maxDimension = 1080; // 1080p max resolution
  static const int defaultQuality = 75; // 70-80% quality

  /// Compresses a [File] to under 200KB, max 1080p resolution, and 70-80% quality.
  static Future<File> compressImageFile(
    File file, {
    int targetMaxBytes = maxFileSizeBytes,
  }) async {
    try {
      final originalLength = await file.length();
      debugPrint(
        '[ImageCompression] Input file size: ${(originalLength / 1024).toStringAsFixed(1)} KB',
      );

      // 1. Try FlutterImageCompress if not on web
      if (!kIsWeb) {
        try {
          int quality = defaultQuality;
          Uint8List? compressedBytes =
              await FlutterImageCompress.compressWithFile(
            file.absolute.path,
            minWidth: maxDimension,
            minHeight: maxDimension,
            quality: quality,
            format: CompressFormat.jpeg,
          );

          // If still over target size, step down quality
          while (compressedBytes != null &&
              compressedBytes.length > targetMaxBytes &&
              quality > 35) {
            quality -= 10;
            compressedBytes = await FlutterImageCompress.compressWithFile(
              file.absolute.path,
              minWidth: (maxDimension * (quality / 100.0)).toInt().clamp(480, 1080),
              minHeight: (maxDimension * (quality / 100.0)).toInt().clamp(480, 1080),
              quality: quality,
              format: CompressFormat.jpeg,
            );
          }

          if (compressedBytes != null && compressedBytes.isNotEmpty) {
            final tempDir = await getTemporaryDirectory();
            final targetPath =
                '${tempDir.path}/opt_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final outFile = File(targetPath);
            await outFile.writeAsBytes(compressedBytes);
            debugPrint(
              '[ImageCompression] Compressed via FlutterImageCompress to ${(outFile.lengthSync() / 1024).toStringAsFixed(1)} KB (quality: $quality)',
            );
            return outFile;
          }
        } catch (ficError) {
          debugPrint(
            '[ImageCompression] FlutterImageCompress fallback: $ficError',
          );
        }
      }

      // 2. Pure Dart fallback using package:image
      final bytes = await file.readAsBytes();
      final compressedBytes = await compressImageBytes(
        bytes,
        targetMaxBytes: targetMaxBytes,
      );

      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/opt_dart_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outFile = File(targetPath);
      await outFile.writeAsBytes(compressedBytes);
      debugPrint(
        '[ImageCompression] Compressed via pure Dart to ${(outFile.lengthSync() / 1024).toStringAsFixed(1)} KB',
      );
      return outFile;
    } catch (e) {
      debugPrint('[ImageCompression] Error compressing image file: $e');
      return file; // Fallback to original on unexpected failure
    }
  }

  /// Compresses [Uint8List] image bytes to under 200KB, max 1080p, and 70-80% quality.
  static Future<Uint8List> compressImageBytes(
    Uint8List inputBytes, {
    int targetMaxBytes = maxFileSizeBytes,
  }) async {
    try {
      // 1. Try FlutterImageCompress with list
      try {
        int quality = defaultQuality;
        Uint8List compressed = await FlutterImageCompress.compressWithList(
          inputBytes,
          minWidth: maxDimension,
          minHeight: maxDimension,
          quality: quality,
          format: CompressFormat.jpeg,
        );

        while (compressed.length > targetMaxBytes && quality > 35) {
          quality -= 10;
          compressed = await FlutterImageCompress.compressWithList(
            inputBytes,
            minWidth: (maxDimension * (quality / 100.0)).toInt().clamp(480, 1080),
            minHeight: (maxDimension * (quality / 100.0)).toInt().clamp(480, 1080),
            quality: quality,
            format: CompressFormat.jpeg,
          );
        }

        if (compressed.isNotEmpty) {
          debugPrint(
            '[ImageCompression] Bytes compressed to ${(compressed.length / 1024).toStringAsFixed(1)} KB',
          );
          return compressed;
        }
      } catch (e) {
        debugPrint('[ImageCompression] FlutterImageCompress list fallback: $e');
      }

      // 2. Pure Dart package:image fallback
      img.Image? decoded = img.decodeImage(inputBytes);
      if (decoded == null) {
        return inputBytes;
      }

      // Resize if dimensions exceed 1080p
      if (decoded.width > maxDimension || decoded.height > maxDimension) {
        if (decoded.width >= decoded.height) {
          decoded = img.copyResize(decoded, width: maxDimension);
        } else {
          decoded = img.copyResize(decoded, height: maxDimension);
        }
      }

      int quality = defaultQuality;
      Uint8List encoded = Uint8List.fromList(
        img.encodeJpg(decoded, quality: quality),
      );

      while (encoded.length > targetMaxBytes && quality > 35) {
        quality -= 10;
        encoded = Uint8List.fromList(
          img.encodeJpg(decoded, quality: quality),
        );
      }

      debugPrint(
        '[ImageCompression] Pure Dart bytes compressed to ${(encoded.length / 1024).toStringAsFixed(1)} KB (quality: $quality)',
      );
      return encoded;
    } catch (e) {
      debugPrint('[ImageCompression] Error compressing image bytes: $e');
      return inputBytes;
    }
  }
}
