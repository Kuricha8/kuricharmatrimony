import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class MediaConversionService {
  /// Converts HEIC, HEIF, and WEBP images to standard JPEG format to ensure compatibility
  /// with ML Kit, dart:ui, and all web platforms without throwing decoding exceptions.
  /// If the file is already a standard format, returns the original path.
  static Future<String> ensureStandardImageFormat(String filePath) async {
    final extension = path.extension(filePath).toLowerCase();

    if (extension == '.heic' || extension == '.heif' || extension == '.webp') {
      try {
        final dir = await getTemporaryDirectory();
        final targetPath = path.join(
          dir.path,
          '${DateTime.now().millisecondsSinceEpoch}_converted.jpg',
        );

        final file = File(filePath);
        if (!await file.exists()) return filePath;

        final bytes = await file.readAsBytes();

        // Process decoding and encoding in background isolate to keep UI smooth
        final jpegBytes = await compute(_convertToJpegBytes, bytes);

        if (jpegBytes != null) {
          final targetFile = File(targetPath);
          await targetFile.writeAsBytes(jpegBytes);
          return targetPath;
        }
      } catch (e) {
        debugPrint('Error converting image format: $e');
      }
    }

    return filePath;
  }

  static List<int>? _convertToJpegBytes(Uint8List bytes) {
    try {
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage != null) {
        return img.encodeJpg(decodedImage, quality: 90);
      }
    } catch (e) {
      debugPrint('Isolate error converting image: $e');
    }
    return null;
  }
}
