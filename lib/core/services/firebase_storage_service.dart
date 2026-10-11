import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'image_compression_service.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads profile photo to Firebase Storage with compression (<200KB, max 1080p, quality 70-80%).
  Future<String?> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      final compressedFile =
          await ImageCompressionService.compressImageFile(imageFile);
      final ref = _storage.ref().child('users/$userId/profile_photo.jpg');
      final uploadTask = await ref.putFile(
        compressedFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile photo to Firebase Storage: $e');
      return null;
    }
  }

  /// Uploads profile photo bytes with compression (<200KB, max 1080p, quality 70-80%).
  Future<String?> uploadProfilePhotoBytes(
    String userId,
    Uint8List imageBytes,
  ) async {
    try {
      final compressedBytes =
          await ImageCompressionService.compressImageBytes(imageBytes);
      final ref = _storage.ref().child('users/$userId/profile_photo.jpg');
      final uploadTask = await ref.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile photo bytes to Firebase Storage: $e');
      return null;
    }
  }

  /// Uploads story image to Firebase Storage with compression (<200KB, max 1080p, quality 70-80%).
  Future<String?> uploadStoryImage(String userId, File imageFile) async {
    try {
      final compressedFile =
          await ImageCompressionService.compressImageFile(imageFile);
      final fileName =
          'story_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('stories/$userId/$fileName');
      final uploadTask = await ref.putFile(
        compressedFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading story image to Firebase Storage: $e');
      return null;
    }
  }

  /// Uploads story image bytes to Firebase Storage with compression (<200KB, max 1080p, quality 70-80%).
  Future<String?> uploadStoryImageBytes(
    String userId,
    Uint8List imageBytes,
  ) async {
    try {
      final compressedBytes =
          await ImageCompressionService.compressImageBytes(imageBytes);
      final fileName =
          'story_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('stories/$userId/$fileName');
      final uploadTask = await ref.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading story image bytes to Firebase Storage: $e');
      return null;
    }
  }

  Future<String?> uploadIdDocument(String userId, File documentFile) async {
    try {
      File fileToUpload = documentFile;
      final ext = documentFile.path.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        fileToUpload =
            await ImageCompressionService.compressImageFile(documentFile);
      }
      final ref = _storage.ref().child('users/$userId/id_document.jpg');
      final uploadTask = await ref.putFile(
        fileToUpload,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading ID document to Firebase Storage: $e');
      return null;
    }
  }
}
