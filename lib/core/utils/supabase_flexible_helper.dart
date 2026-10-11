import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper function to upload video files directly as File objects without loading full bytes into RAM.
/// Prevents memory choke and connection abort errors (errno = 103).
Future<String?> uploadLivenessVideo(String videoPath, String userId) async {
  final file = File(videoPath);
  if (!await file.exists()) {
    throw Exception("വീഡിയോ ഫയൽ ലഭ്യമായില്ല (Video file not found)");
  }

  final fileName =
      'liveness_${userId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
  final supabase = Supabase.instance.client;

  String targetBucket = 'liveness_videos';
  try {
    await supabase.storage
        .from(targetBucket)
        .upload(
          fileName,
          file,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: 'video/mp4',
          ),
        );
  } catch (storageErr) {
    debugPrint(
      '[STORAGE] Bucket $targetBucket notice: $storageErr. Retrying verifications bucket...',
    );
    targetBucket = 'verifications';
    await supabase.storage
        .from(targetBucket)
        .upload(
          fileName,
          file,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: 'video/mp4',
          ),
        );
  }

  final publicUrl = supabase.storage.from(targetBucket).getPublicUrl(fileName);
  return publicUrl;
}

/// Extension on SupabaseClient providing Firebase-like flexible dynamic updates.
/// If strict Postgres schema checking throws PostgrestException for missing columns,
/// it safely falls back key-by-key and stores dynamic attributes in raw_data/metadata JSONB.
extension SupabaseFlexibleUpdate on SupabaseClient {
  Future<void> updateFlexibleProfile({
    required String table,
    required String userId,
    required Map<String, dynamic> payload,
    String idColumn = 'id',
  }) async {
    if (userId.isEmpty || payload.isEmpty) return;

    // 1. Attempt complete payload update
    try {
      await from(table).update(payload).eq(idColumn, userId);
      return;
    } on PostgrestException catch (pgErr) {
      debugPrint(
        '[SUPABASE_FLEX] Full update notice ($pgErr). Attempting key-by-key fallback...',
      );
    } catch (e) {
      debugPrint('[SUPABASE_FLEX] Full update error: $e');
    }

    // 2. Fallback: Update column by column to skip missing schema fields gracefully
    final Map<String, dynamic> successfulFields = {};
    for (final entry in payload.entries) {
      try {
        await from(table).update({entry.key: entry.value}).eq(idColumn, userId);
        successfulFields[entry.key] = entry.value;
      } on PostgrestException catch (colErr) {
        debugPrint(
          '[SUPABASE_FLEX] Column "${entry.key}" missing in $table schema ($colErr). Skipping column.',
        );
      } catch (e) {
        debugPrint('[SUPABASE_FLEX] Error inserting key "${entry.key}": $e');
      }
    }

    // 3. Fallback: Attempt storing un-inserted payload in JSONB columns (raw_data / data / metadata)
    try {
      await from(table).update({'raw_data': payload}).eq(idColumn, userId);
    } catch (_) {
      try {
        await from(table).update({'metadata': payload}).eq(idColumn, userId);
      } catch (_) {}
    }
  }
}
