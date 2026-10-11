import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'guest_permission_service.dart';

/// Centralized ImagePicker helper configured with optimized dimensions & compression:
/// - maxWidth: 1024 (reduces width for mobile bandwidth optimization)
/// - maxHeight: 1024 (reduces height for fast upload)
/// - imageQuality: 75 (75% quality compression, saving ~80% file size)
class AppImagePicker {
  static final ImagePicker _picker = ImagePicker();
  static ImagePicker get instance => _picker;

  /// Pick image with default 1024x1024 max dimensions and 75% quality compression.
  /// Automatically checks guest mode and blocks uploads if [context] is provided.
  static Future<XFile?> pickImage({
    BuildContext? context,
    ImageSource source = ImageSource.camera,
    double maxWidth = 1024,
    double maxHeight = 1024,
    int imageQuality = 75,
  }) async {
    if (context != null && GuestPermissionService.isGuest) {
      GuestPermissionService.showUploadRestrictedDialog(context);
      return null;
    }

    return await _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// Pick image directly from Camera (1024x1024, 75% quality)
  static Future<XFile?> pickFromCamera({
    BuildContext? context,
    double maxWidth = 1024,
    double maxHeight = 1024,
    int imageQuality = 75,
  }) async {
    return await pickImage(
      context: context,
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// Pick image directly from Gallery (1024x1024, 75% quality)
  static Future<XFile?> pickFromGallery({
    BuildContext? context,
    double maxWidth = 1024,
    double maxHeight = 1024,
    int imageQuality = 75,
  }) async {
    return await pickImage(
      context: context,
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }
}

