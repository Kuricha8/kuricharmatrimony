import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/moiety_voices.dart';
import 'admin_moiety_audio_cache_service.dart';

/// Represents a single voice prompt & dialogue entry configured in the Admin database.
class AdminMoietyPrompt {
  final String id;
  final String text; // Malayalam dialogue text / subtitle
  final String? audioUrl; // Remote audio URL (Firebase Storage / HTTPS), or null if TTS
  final bool isMatch; // true: Yes Match, false: No Match
  final bool isActive;
  final String source; // Firestore collection / document source

  const AdminMoietyPrompt({
    required this.id,
    required this.text,
    this.audioUrl,
    required this.isMatch,
    this.isActive = true,
    this.source = 'firestore',
  });

  factory AdminMoietyPrompt.fromMap(
    String docId,
    Map<String, dynamic> data, {
    String source = 'firestore',
    bool? forcedMatch,
  }) {
    // 1. Resolve Malayalam subtitle text
    final text = (data['text'] ??
            data['dialogue'] ??
            data['prompt'] ??
            data['dialogue_text'] ??
            data['text_ml'] ??
            data['malayalam_text'] ??
            data['title'] ??
            data['message'] ??
            data['subtitle'] ??
            '')
        .toString()
        .trim();

    // 2. Resolve remote audio URL (strictly ignore local asset paths)
    final rawUrl = (data['audio_url'] ??
            data['audioUrl'] ??
            data['url'] ??
            data['voice_url'] ??
            data['sound_url'])
        ?.toString()
        .trim();

    final audioUrl = (rawUrl != null &&
            rawUrl.isNotEmpty &&
            (rawUrl.startsWith('http://') ||
                rawUrl.startsWith('https://') ||
                rawUrl.startsWith('gs://')))
        ? rawUrl
        : null;

    // 3. Resolve match type (Yes Match vs No Match)
    bool isMatch = true;
    if (forcedMatch != null) {
      isMatch = forcedMatch;
    } else if (data.containsKey('is_match')) {
      final val = data['is_match'];
      if (val is bool) {
        isMatch = val;
      } else {
        isMatch = val.toString().toLowerCase() == 'true';
      }
    } else {
      final rawType = (data['type'] ??
              data['category'] ??
              data['match_type'] ??
              data['result_type'] ??
              'yes')
          .toString()
          .trim()
          .toLowerCase();

      final isNoMatch = rawType.contains('no') ||
          rawType.contains('mismatch') ||
          rawType.contains('incompatible') ||
          rawType.contains('fail') ||
          rawType.contains('restriction') ||
          rawType == 'false';

      isMatch = !isNoMatch;
    }

    // 4. Resolve active status
    final activeVal = data['is_active'] ??
        data['isActive'] ??
        data['active'] ??
        data['enabled'];
    final isActive = activeVal == null ||
        activeVal == true ||
        activeVal.toString().toLowerCase() == 'true';

    return AdminMoietyPrompt(
      id: docId,
      text: text,
      audioUrl: audioUrl,
      isMatch: isMatch,
      isActive: isActive,
      source: source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'audio_url': audioUrl,
      'is_match': isMatch,
      'is_active': isActive,
      'source': source,
    };
  }

  @override
  String toString() =>
      'AdminMoietyPrompt(id: $id, isMatch: $isMatch, text: "$text", audioUrl: $audioUrl, source: $source)';
}

/// Service that dynamically fetches, caches, and synchronizes voice prompts & Malayalam subtitles
/// directly from the Admin database in Firestore (`moiety_voice_prompts`, `system_config/moiety_dialogues`,
/// `moiety_dialogues`, and `match_audio_pool`).
///
/// Guarantees:
/// 1. Subtitle text and audio/TTS strictly match the same chosen Admin entry.
/// 2. If audio fails to load or internet is slow, the Malayalam subtitle is still displayed on screen.
/// 3. ZERO local asset sounds (beep/car-key/legacy horn/fallback audio) are played.
class AdminMoietyPromptService {
  AdminMoietyPromptService._();
  static final AdminMoietyPromptService instance = AdminMoietyPromptService._();

  static const String _historyKey = 'admin_prompt_play_history';
  static const int _cooldownHours = 2; // 2-hour rotation cooldown

  // In-memory cache to prevent redundant Firestore reads
  List<AdminMoietyPrompt>? _cachedPrompts;
  DateTime? _lastCacheTime;
  static const Duration _cacheDuration = Duration(minutes: 15);

  /// Clears in-memory cache
  void invalidateCache() {
    _cachedPrompts = null;
    _lastCacheTime = null;
  }

  /// Fetches all active prompts across Firestore collections where Admin entries might reside.
  Future<List<AdminMoietyPrompt>> fetchAllPrompts({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedPrompts != null &&
        _lastCacheTime != null &&
        now.difference(_lastCacheTime!) < _cacheDuration) {
      return _cachedPrompts!;
    }

    final List<AdminMoietyPrompt> aggregated = [];

    // 1. Primary Collection: `moiety_voice_prompts`
    try {
      debugPrint('[AdminMoietyPromptService] Querying Firestore `moiety_voice_prompts`...');
      final snap = await FirebaseFirestore.instance
          .collection('moiety_voice_prompts')
          .limit(100)
          .get(const GetOptions(source: Source.serverAndCache));

      for (final doc in snap.docs) {
        final prompt = AdminMoietyPrompt.fromMap(
          doc.id,
          doc.data(),
          source: 'moiety_voice_prompts',
        );
        if (prompt.isActive && prompt.text.isNotEmpty) {
          aggregated.add(prompt);
        }
      }
      debugPrint(
        '[AdminMoietyPromptService] Loaded ${aggregated.length} prompts from `moiety_voice_prompts`',
      );
    } catch (e) {
      debugPrint('[AdminMoietyPromptService] `moiety_voice_prompts` query notice: $e');
    }

    // 2. Config Document: `system_config/moiety_dialogues`
    try {
      debugPrint('[AdminMoietyPromptService] Querying `system_config/moiety_dialogues`...');
      final sysDoc = await FirebaseFirestore.instance
          .collection('system_config')
          .doc('moiety_dialogues')
          .get(const GetOptions(source: Source.serverAndCache));

      if (sysDoc.exists && sysDoc.data() != null) {
        final data = sysDoc.data()!;
        _extractPromptsFromConfigMap(sysDoc.id, data, aggregated);
      }
    } catch (e) {
      debugPrint('[AdminMoietyPromptService] `system_config/moiety_dialogues` query notice: $e');
    }

    // 3. Collection: `moiety_dialogues`
    if (aggregated.isEmpty) {
      try {
        debugPrint('[AdminMoietyPromptService] Querying `moiety_dialogues` collection...');
        final snap = await FirebaseFirestore.instance
            .collection('moiety_dialogues')
            .limit(100)
            .get(const GetOptions(source: Source.serverAndCache));

        for (final doc in snap.docs) {
          final prompt = AdminMoietyPrompt.fromMap(
            doc.id,
            doc.data(),
            source: 'moiety_dialogues',
          );
          if (prompt.isActive && prompt.text.isNotEmpty) {
            aggregated.add(prompt);
          }
        }
      } catch (e) {
        debugPrint('[AdminMoietyPromptService] `moiety_dialogues` query notice: $e');
      }
    }

    // 4. Collection: `match_audio_pool` (existing Admin voice pool)
    try {
      debugPrint('[AdminMoietyPromptService] Querying `match_audio_pool` collection...');
      final snap = await FirebaseFirestore.instance
          .collection('match_audio_pool')
          .limit(100)
          .get(const GetOptions(source: Source.serverAndCache));

      for (final doc in snap.docs) {
        final data = doc.data();
        // Avoid duplicate IDs if already captured
        if (aggregated.any((p) => p.id == doc.id)) continue;

        final prompt = AdminMoietyPrompt.fromMap(
          doc.id,
          data,
          source: 'match_audio_pool',
        );
        if (prompt.isActive && prompt.text.isNotEmpty) {
          aggregated.add(prompt);
        }
      }
      debugPrint(
        '[AdminMoietyPromptService] Total aggregated prompts from all sources: ${aggregated.length}',
      );
    } catch (e) {
      debugPrint('[AdminMoietyPromptService] `match_audio_pool` query notice: $e');
    }

    if (aggregated.isNotEmpty) {
      _cachedPrompts = aggregated;
      _lastCacheTime = now;
      // Background housekeeping: Prune cached audio files for prompts that are no longer active
      AdminMoietyAudioCacheService.instance.pruneObsoleteCacheFiles(
        aggregated.map((p) => p.text).toList(),
      );
    }

    return aggregated;
  }

  /// Helper to extract dialogues from a config document map
  void _extractPromptsFromConfigMap(
    String parentId,
    Map<String, dynamic> data,
    List<AdminMoietyPrompt> output,
  ) {
    // Check for array fields
    void processList(dynamic list, {bool? forcedMatch}) {
      if (list is List) {
        for (int i = 0; i < list.length; i++) {
          final item = list[i];
          if (item is Map<String, dynamic>) {
            final prompt = AdminMoietyPrompt.fromMap(
              '${parentId}_item_$i',
              item,
              source: 'system_config',
              forcedMatch: forcedMatch,
            );
            if (prompt.isActive && prompt.text.isNotEmpty) {
              output.add(prompt);
            }
          } else if (item is String && item.trim().isNotEmpty) {
            output.add(AdminMoietyPrompt(
              id: '${parentId}_item_$i',
              text: item.trim(),
              audioUrl: null,
              isMatch: forcedMatch ?? true,
              source: 'system_config',
            ));
          }
        }
      }
    }

    processList(data['yes_matches'] ?? data['yes_prompts'] ?? data['yes_dialogues'], forcedMatch: true);
    processList(data['no_matches'] ?? data['no_prompts'] ?? data['no_dialogues'], forcedMatch: false);
    processList(data['dialogues'] ?? data['prompts'] ?? data['items']);
  }

  /// Picks a dynamic prompt for Yes Match or No Match strictly from the Admin database,
  /// with a 2-hour cooldown preventing repetition across clicks.
  ///
  /// If the database has no entries or internet is down, provides a Malayalam text prompt
  /// with NO audio URL (zero sounds played).
  Future<AdminMoietyPrompt> getPrompt({
    required bool isMatch,
    bool forceRefresh = false,
  }) async {
    final allPrompts = await fetchAllPrompts(forceRefresh: forceRefresh);
    final candidates = allPrompts.where((p) => p.isMatch == isMatch && p.isActive).toList();

    debugPrint(
      '[AdminMoietyPromptService] Candidate prompts found for isMatch=$isMatch: ${candidates.length}',
    );

    if (candidates.isNotEmpty) {
      final selected = await _pickWithCooldown(candidates);
      return selected;
    }

    // Fallback: If Admin database is completely empty or Firestore is offline,
    // generate a prompt from the curated Malayalam dialogue constants.
    // CRITICAL: audioUrl is strictly null so ZERO legacy/fallback sounds are played!
    final random = Random();
    final String fallbackText;
    if (isMatch) {
      fallbackText = MoietyVoices.matchVoices[random.nextInt(MoietyVoices.matchVoices.length)];
    } else {
      fallbackText = MoietyVoices.noMatchVoices[random.nextInt(MoietyVoices.noMatchVoices.length)];
    }

    debugPrint(
      '[AdminMoietyPromptService] No remote Admin prompts found. Returning synchronized Malayalam text only (zero sound).',
    );

    return AdminMoietyPrompt(
      id: 'local_ml_fallback_${DateTime.now().millisecondsSinceEpoch}',
      text: fallbackText,
      audioUrl: null, // ZERO sounds
      isMatch: isMatch,
      source: 'local_text_only',
    );
  }

  /// Selects a prompt with a 2-hour cooldown using SharedPreferences
  Future<AdminMoietyPrompt> _pickWithCooldown(List<AdminMoietyPrompt> list) async {
    final random = Random();
    if (list.length == 1) return list.first;

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final rawHistory = prefs.getStringList(_historyKey) ?? [];

      final Map<String, int> history = {};
      for (final entry in rawHistory) {
        final parts = entry.split('|');
        if (parts.length == 2) {
          final id = parts[0];
          final ts = int.tryParse(parts[1]) ?? 0;
          if (now - ts < _cooldownHours * 60 * 60 * 1000) {
            history[id] = ts;
          }
        }
      }

      // Filter eligible
      List<AdminMoietyPrompt> eligible = list.where((p) => !history.containsKey(p.id)).toList();

      if (eligible.isEmpty) {
        debugPrint('[AdminMoietyPromptService] All candidate prompts recently played. Resetting cycle.');
        eligible = list;
        history.clear();
      }

      final chosen = eligible[random.nextInt(eligible.length)];

      // Record in history
      history[chosen.id] = now;
      final updatedHistory = history.entries.map((e) => '${e.key}|${e.value}').toList();
      await prefs.setStringList(_historyKey, updatedHistory);

      return chosen;
    } catch (e) {
      debugPrint('[AdminMoietyPromptService] Cooldown error ($e). Picking random.');
      return list[random.nextInt(list.length)];
    }
  }
}
