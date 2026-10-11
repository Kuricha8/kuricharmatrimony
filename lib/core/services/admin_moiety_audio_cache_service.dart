import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'admin_moiety_prompt_service.dart';

/// Dynamic Text-Content Hash Based Audio Caching Service.
///
/// Features:
/// 1. Generates cache keys and filenames strictly based on the MD5 of the prompt text:
///    e.g., `prompt_${md5.convert(utf8.encode(promptText))}.mp3`
/// 2. If the admin updates, edits, or adds new prompt text in Firestore/Admin Panel:
///    - The text hash changes automatically.
///    - The app detects cache miss for the new text string.
///    - It fetches the new Malayalam audio stream/URL for the updated text, caches it locally, and plays it.
///    - If the text didn't change, it plays directly from the ultra-fast local cache.
/// 3. Housekeeping: Prunes obsolete cache files when Admin changes or deletes prompts.
class AdminMoietyAudioCacheService {
  AdminMoietyAudioCacheService._();
  static final AdminMoietyAudioCacheService instance =
      AdminMoietyAudioCacheService._();

  static const String _subDirectory = 'moiety_audio_cache';
  Directory? _cachedDir;

  /// Generates the MD5 hash string for any given text content.
  static String computeTextHash(String text) {
    final clean = text.trim();
    return md5.convert(utf8.encode(clean)).toString();
  }

  /// Generates the exact cached file name based on the text hash.
  static String getCacheFileName(String text) {
    final hash = computeTextHash(text);
    return 'prompt_$hash.mp3';
  }

  /// Resolves the local cache directory on native platforms.
  Future<Directory?> getCacheDirectory() async {
    if (kIsWeb) return null;
    if (_cachedDir != null && await _cachedDir!.exists()) {
      return _cachedDir!;
    }
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final target = Directory('${baseDir.path}/$_subDirectory');
      if (!await target.exists()) {
        await target.create(recursive: true);
      }
      _cachedDir = target;
      return target;
    } catch (e) {
      debugPrint('[AdminMoietyAudioCacheService] Error resolving cache directory: $e');
      return null;
    }
  }

  /// Checks if a local cache file exists for the given prompt text.
  /// Returns the file path if cache HIT, or null if cache MISS.
  Future<String?> getCachedAudioPath(String text) async {
    if (kIsWeb || text.trim().isEmpty) return null;
    try {
      final dir = await getCacheDirectory();
      if (dir == null) return null;

      final fileName = getCacheFileName(text);
      final file = File('${dir.path}/$fileName');

      if (await file.exists() && await file.length() > 0) {
        debugPrint('[AdminMoietyAudioCacheService] Cache HIT for "$text" -> $fileName (${await file.length()} bytes)');
        return file.path;
      }
      debugPrint('[AdminMoietyAudioCacheService] Cache MISS for "$text" -> $fileName');
      return null;
    } catch (e) {
      debugPrint('[AdminMoietyAudioCacheService] Error checking cache: $e');
      return null;
    }
  }

  /// High-level method:
  /// Returns the cached audio path if available; otherwise fetches the new Malayalam audio stream,
  /// saves it to local cache under `prompt_${hash}.mp3`, and returns the new file path.
  Future<String?> getOrFetchCachedAudio({
    required AdminMoietyPrompt prompt,
  }) async {
    final text = prompt.text.trim();
    if (text.isEmpty || kIsWeb) return null;

    // 1. Check local cache
    final existingPath = await getCachedAudioPath(text);
    if (existingPath != null) {
      return existingPath;
    }

    // 2. Cache miss: Fetch and store new audio for updated text
    debugPrint('[AdminMoietyAudioCacheService] Fetching & caching audio for updated prompt text: "$text"');
    return await fetchAndCacheAudio(
      text: text,
      audioUrl: prompt.audioUrl,
    );
  }

  /// Fetches audio bytes from remote URL or Google Malayalam voice stream,
  /// writes to `prompt_${hash}.mp3`, and returns the cached file path.
  Future<String?> fetchAndCacheAudio({
    required String text,
    String? audioUrl,
  }) async {
    if (kIsWeb || text.trim().isEmpty) return null;

    try {
      final dir = await getCacheDirectory();
      if (dir == null) return null;

      final fileName = getCacheFileName(text);
      final targetFile = File('${dir.path}/$fileName');
      Uint8List? audioBytes;

      // Source A: Remote audio URL from Admin if present
      final trimmedUrl = audioUrl?.trim();
      if (trimmedUrl != null &&
          trimmedUrl.isNotEmpty &&
          (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://'))) {
        try {
          debugPrint('[AdminMoietyAudioCacheService] Downloading Admin audio from: $trimmedUrl');
          final response = await http.get(Uri.parse(trimmedUrl)).timeout(
                const Duration(seconds: 10),
              );
          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            audioBytes = response.bodyBytes;
            debugPrint('[AdminMoietyAudioCacheService] Successfully downloaded ${audioBytes.length} bytes from Admin URL.');
          }
        } catch (netErr) {
          debugPrint('[AdminMoietyAudioCacheService] Admin URL download note: $netErr');
        }
      }

      // Source B: Dynamic Google Malayalam Audio Stream for updated text
      if (audioBytes == null || audioBytes.isEmpty) {
        try {
          final streamUrl =
              'https://translate.google.com/translate_tts?ie=UTF-8&q=${Uri.encodeComponent(text)}&tl=ml&client=tw-ob';
          debugPrint('[AdminMoietyAudioCacheService] Fetching dynamic Malayalam stream: $streamUrl');
          final response = await http.get(
            Uri.parse(streamUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
          ).timeout(const Duration(seconds: 8));

          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            audioBytes = response.bodyBytes;
            debugPrint('[AdminMoietyAudioCacheService] Downloaded dynamic Malayalam voice stream: ${audioBytes.length} bytes.');
          }
        } catch (streamErr) {
          debugPrint('[AdminMoietyAudioCacheService] Dynamic stream fetch note: $streamErr');
        }
      }

      // Save bytes to local file
      if (audioBytes != null && audioBytes.isNotEmpty) {
        await targetFile.writeAsBytes(audioBytes, flush: true);
        debugPrint(
          '[AdminMoietyAudioCacheService] Stored audio in cache: ${targetFile.path} (${audioBytes.length} bytes)',
        );
        return targetFile.path;
      }
    } catch (e) {
      debugPrint('[AdminMoietyAudioCacheService] fetchAndCacheAudio error: $e');
    }
    return null;
  }

  /// Housekeeping: Prunes older cached audio files that are no longer present
  /// in the active Firestore admin prompt list.
  Future<void> pruneObsoleteCacheFiles(List<String> activePromptTexts) async {
    if (kIsWeb) return;
    try {
      final dir = await getCacheDirectory();
      if (dir == null || !await dir.exists()) return;

      final Set<String> activeFileNames = activePromptTexts
          .where((t) => t.trim().isNotEmpty)
          .map(getCacheFileName)
          .toSet();

      final entities = dir.listSync();
      int prunedCount = 0;

      for (final entity in entities) {
        if (entity is File) {
          final name = entity.uri.pathSegments.last;
          if (name.startsWith('prompt_') && name.endsWith('.mp3')) {
            if (!activeFileNames.contains(name)) {
              try {
                await entity.delete();
                prunedCount++;
                debugPrint('[AdminMoietyAudioCacheService] Pruned obsolete cache file: $name');
              } catch (_) {}
            }
          }
        }
      }

      if (prunedCount > 0) {
        debugPrint(
          '[AdminMoietyAudioCacheService] Housekeeping complete: Pruned $prunedCount obsolete audio files.',
        );
      }
    } catch (e) {
      debugPrint('[AdminMoietyAudioCacheService] Housekeeping error: $e');
    }
  }

  /// Clears the entire local audio cache (e.g. for testing or app reset).
  Future<void> clearAllCache() async {
    if (kIsWeb) return;
    try {
      final dir = await getCacheDirectory();
      if (dir != null && await dir.exists()) {
        await dir.delete(recursive: true);
        _cachedDir = null;
        debugPrint('[AdminMoietyAudioCacheService] Cleared entire audio cache directory.');
      }
    } catch (e) {
      debugPrint('[AdminMoietyAudioCacheService] clearAllCache error: $e');
    }
  }
}
