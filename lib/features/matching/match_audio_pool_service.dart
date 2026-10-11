import 'dart:math';
import 'package:audioplayers/audioplayers.dart' hide Source;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Represents a single audio entry from the `match_audio_pool` Firestore collection.
class MatchAudioPoolItem {
  final String id;
  final String type; // "success" or "no_match"
  final String title;
  final String audioUrl;
  final bool isActive;

  const MatchAudioPoolItem({
    required this.id,
    required this.type,
    required this.title,
    required this.audioUrl,
    this.isActive = true,
  });

  factory MatchAudioPoolItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return MatchAudioPoolItem(
      id: doc.id,
      type: (data['type'] as String?)?.trim().toLowerCase() ?? 'success',
      title: (data['title'] as String?)?.trim() ?? '',
      audioUrl: (data['audio_url'] as String?)?.trim() ?? '',
      isActive: data['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'audio_url': audioUrl,
      'is_active': isActive,
    };
  }
}

/// Service managing the `match_audio_pool` collection.
///
/// Spark Plan Optimizations:
/// - In-memory cache with 1-hour expiration (avoids redundant Firestore reads)
/// - Queries with `Source.serverAndCache` and `.limit(20)`
/// - Strict 2-step playback lifecycle (`stop()` before `play()`)
class MatchAudioPoolService {
  MatchAudioPoolService._();
  static final MatchAudioPoolService instance = MatchAudioPoolService._();

  List<MatchAudioPoolItem>? _cachedPool;
  DateTime? _lastFetchedAt;
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Fetch active audio items from `match_audio_pool`.
  Future<List<MatchAudioPoolItem>> getAudioPool({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedPool != null &&
        _lastFetchedAt != null &&
        now.difference(_lastFetchedAt!) < _cacheDuration) {
      return _cachedPool!;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('match_audio_pool')
          .where('is_active', isEqualTo: true)
          .limit(20)
          .get(const GetOptions(source: Source.serverAndCache));

      _cachedPool = snapshot.docs
          .map((doc) => MatchAudioPoolItem.fromFirestore(doc))
          .where((item) => item.audioUrl.isNotEmpty)
          .toList();
      _lastFetchedAt = now;
      return _cachedPool!;
    } catch (e) {
      debugPrint('[MatchAudioPoolService] Error fetching match_audio_pool: $e');
      return _cachedPool ?? const [];
    }
  }

  /// Returns a random active audio track URL for the specified type ('success' or 'no_match').
  Future<String?> getRandomAudioUrl(String type) async {
    final pool = await getAudioPool();
    final normalized = type.trim().toLowerCase();
    final matching = pool
        .where(
          (item) =>
              item.type == normalized &&
              item.audioUrl.isNotEmpty &&
              item.isActive,
        )
        .toList();

    if (matching.isEmpty) return null;
    final random = Random();
    return matching[random.nextInt(matching.length)].audioUrl;
  }

  /// Shorthand to get random success audio URL
  Future<String?> getRandomSuccessAudioUrl() => getRandomAudioUrl('success');

  /// Shorthand to get random no_match audio URL
  Future<String?> getRandomNoMatchAudioUrl() => getRandomAudioUrl('no_match');

  /// Clears in-memory cache (e.g., when admin updates pool)
  void invalidateCache() {
    _cachedPool = null;
    _lastFetchedAt = null;
  }

  /// Complete 2-step audio playback helper:
  /// 1. പഴയ ഓഡിയോ ഓടുന്നുണ്ടെങ്കിൽ പൂർണ്ണമായി നിർത്തുക
  /// 2. പുതിയ ഓഡിയോ മാത്രം വ്യക്തമായി പ്ലേ ചെയ്യുക
  Future<void> playPoolOrAssetAudio({
    required AudioPlayer player,
    required String type, // 'success' or 'no_match'
    String? fallbackAsset,
  }) async {
    try {
      // 1. പഴയ ഓഡിയോ ഓടുന്നുണ്ടെങ്കിൽ പൂർണ്ണമായി നിർത്തുക
      await player.stop();

      final remoteUrl = await getRandomAudioUrl(type);
      if (remoteUrl != null &&
          (remoteUrl.startsWith('http://') ||
              remoteUrl.startsWith('https://'))) {
        try {
          // 2. പുതിയ ഓഡിയോ മാത്രം വ്യക്തമായി പ്ലേ ചെയ്യുക (Remote UrlSource)
          await player.play(UrlSource(remoteUrl));
          return;
        } catch (e) {
          debugPrint(
            '[MatchAudioPoolService] Remote UrlSource playback note: $e',
          );
        }
      }

      // Fallback: If remote URL fails or is empty, play ZERO sounds (strictly purge legacy asset sounds)
      debugPrint(
        '[MatchAudioPoolService] Remote audio not available or failed. Zero fallback sounds played.',
      );
    } catch (e) {
      debugPrint('[MatchAudioPoolService] Playback error: $e');
    }
  }
}
