import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../core/services/image_compression_service.dart';

class TharavaduMediaService {
  static final TharavaduMediaService instance =
      TharavaduMediaService._internal();
  TharavaduMediaService._internal();

  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  /// Pick an image from gallery
  Future<File?> pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (picked != null) {
        return File(picked.path);
      }
    } catch (e) {
      debugPrint('[TharavaduMediaService] Error picking image: $e');
    }
    return null;
  }

  /// Pick a video from gallery with max 30-min validation
  Future<({File file, String durationStr})?> pickVideo({
    required BuildContext context,
  }) async {
    try {
      final picked = await _picker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return null;

      final file = File(picked.path);

      // Validate video length (max 30 mins)
      try {
        final videoCtrl = VideoPlayerController.file(file);
        await videoCtrl.initialize();
        final dur = videoCtrl.value.duration;
        await videoCtrl.dispose();

        if (dur > const Duration(minutes: 30)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'വീഡിയോ ദൈർഘ്യം 30 മിനിറ്റിൽ കൂടരുത് (${dur.inMinutes} മിനിറ്റ്).',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return null;
        }

        final durStr =
            '${dur.inMinutes}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}';
        return (file: file, durationStr: durStr);
      } catch (e) {
        debugPrint('[TharavaduMediaService] Video duration init error: $e');
        return (file: file, durationStr: 'Video');
      }
    } catch (e) {
      debugPrint('[TharavaduMediaService] Error picking video: $e');
      return null;
    }
  }

  /// Upload bytes directly to Supabase storage (feed_media / chat_media / status_media)
  Future<String?> uploadMediaBytes({
    required Uint8List bytes,
    required String fileExt,
    required String userId,
    String? bucket,
  }) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$userId.$fileExt';
      Uint8List compressed = bytes;
      if (['jpg', 'jpeg', 'png', 'webp'].contains(fileExt.toLowerCase())) {
        compressed = await ImageCompressionService.compressImageBytes(bytes);
      }

      final targetBuckets = bucket != null
          ? [bucket, 'feed_media', 'chat_media', 'status_media']
          : ['feed_media', 'chat_media', 'status_media'];

      for (final b in targetBuckets) {
        try {
          await _supabase.storage
              .from(b)
              .uploadBinary(
                fileName,
                compressed,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: true,
                ),
              );
          final publicUrl = _supabase.storage.from(b).getPublicUrl(fileName);
          if (publicUrl.isNotEmpty) {
            debugPrint(
              '[TharavaduMediaService] Uploaded successfully to $b: $publicUrl',
            );
            return publicUrl;
          }
        } catch (uploadErr) {
          debugPrint(
            '[TharavaduMediaService] Bucket $b upload failed, trying next: $uploadErr',
          );
        }
      }

      return null;
    } catch (e) {
      debugPrint('[TharavaduMediaService] Overall upload error: $e');
      return null;
    }
  }

  /// Upload file to Supabase storage (feed_media / chat_media / status_media)
  Future<String?> uploadMediaFile({
    required File file,
    required String userId,
    String? bucket,
  }) async {
    try {
      final fileExt = file.path.split('.').last.toLowerCase();
      final bytes = await file.readAsBytes();
      final url = await uploadMediaBytes(
        bytes: bytes,
        fileExt: fileExt,
        userId: userId,
        bucket: bucket,
      );
      return url ?? file.path;
    } catch (e) {
      debugPrint('[TharavaduMediaService] Overall upload error: $e');
      return file.path;
    }
  }
}
