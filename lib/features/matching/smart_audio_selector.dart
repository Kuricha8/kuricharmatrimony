import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmartAudioSelector {
  static const String _historyKey = 'played_audio_history';
  static const int _cooldownHours = 2; // 2 മണിക്കൂർ റിപ്പീറ്റ് ചെയ്യില്ല

  /// Tracks the title of the last selected audio dialogue
  static String? lastSelectedTitle;

  // Spark Plan In-Memory Cache (avoids redundant reads on rapid clicks)
  static final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _memoryCache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheDuration = Duration(minutes: 30);

  /// പൊരുത്തമനുസരിച്ച് (Success / No Match) റാൻഡമായി പുതിയ ഓഡിയോ എടുക്കുന്നു
  static Future<String?> getNextAudioUrl({
    required bool isMatch,
    bool forceRefresh = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. മുൻപ് കേട്ട ഓഡിയോകളുടെ ഹിസ്റ്ററി എടുക്കുന്നു
      List<String> rawHistory = prefs.getStringList(_historyKey) ?? [];
      Map<String, int> playHistory = {};

      for (var item in rawHistory) {
        final parts = item.split('|');
        if (parts.length == 2) {
          final id = parts[0];
          final time = int.tryParse(parts[1]) ?? 0;
          // 2 മണിക്കൂർ കഴിയാത്തവ മാത്രം നിലനിർത്തുന്നു
          if (now - time < _cooldownHours * 60 * 60 * 1000) {
            playHistory[id] = time;
          }
        }
      }

      // 2. അഡ്മിൻ ആഡ് ചെയ്ത ആക്ടീവ് ഓഡിയോകൾ ഫയർബേസിൽ നിന്ന് എടുക്കുന്നു
      final queryType = isMatch ? 'success' : 'no_match';
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];

      final cached = _memoryCache[queryType];
      final cachedAt = _cacheTime[queryType];
      final isMemoryFresh = !forceRefresh &&
          cached != null &&
          cached.isNotEmpty &&
          cachedAt != null &&
          DateTime.now().difference(cachedAt) < _cacheDuration;

      if (isMemoryFresh) {
        docs = cached;
        debugPrint(
          '[SmartAudioSelector] Using ${docs.length} cached "$queryType" voice tracks.',
        );
      } else {
        debugPrint(
          '[SmartAudioSelector] Querying Firestore collection "match_audio_pool" for active dialogues (type: "$queryType")...',
        );

        try {
          // Primary query: Active Malayalam voice tracks matching type
          final snapshot = await FirebaseFirestore.instance
              .collection('match_audio_pool')
              .where('type', isEqualTo: queryType)
              .where('is_active', isEqualTo: true)
              .limit(20)
              .get();

          docs = snapshot.docs;
          debugPrint(
            '[SmartAudioSelector] Primary query found ${docs.length} active documents for "$queryType"',
          );
        } catch (queryErr) {
          debugPrint(
            '[SmartAudioSelector] Primary query notice ($queryErr). Attempting fallback query...',
          );
        }

        // Fallback 1: Query by type only (in case is_active composite index is absent or non-boolean)
        if (docs.isEmpty) {
          try {
            final snapshot = await FirebaseFirestore.instance
                .collection('match_audio_pool')
                .where('type', isEqualTo: queryType)
                .limit(20)
                .get();

            docs = snapshot.docs.where((doc) {
              final active = doc.data()['is_active'];
              return active == null ||
                  active == true ||
                  active.toString().toLowerCase() == 'true';
            }).toList();
            debugPrint(
              '[SmartAudioSelector] Fallback type-only query found ${docs.length} items.',
            );
          } catch (e) {
            debugPrint(
              '[SmartAudioSelector] Fallback type query failed: $e',
            );
          }
        }

        // Fallback 2: Collection-wide query with in-memory matching
        if (docs.isEmpty) {
          try {
            final snapshot = await FirebaseFirestore.instance
                .collection('match_audio_pool')
                .limit(50)
                .get();

            docs = snapshot.docs.where((doc) {
              final data = doc.data();
              final rawType =
                  (data['type'] as String?)?.trim().toLowerCase() ?? '';
              final active = data['is_active'];
              final isActive = active == null ||
                  active == true ||
                  active.toString().toLowerCase() == 'true';

              final isMatchItem = (rawType == 'success' ||
                  rawType == 'match' ||
                  rawType == 'true');
              final isNoMatchItem = (rawType == 'no_match' ||
                  rawType == 'nomatch' ||
                  rawType == 'no-match' ||
                  rawType == 'restriction' ||
                  rawType == 'false');

              final matchesType = isMatch ? isMatchItem : isNoMatchItem;
              return isActive && matchesType;
            }).toList();
            debugPrint(
              '[SmartAudioSelector] Broad collection scan found ${docs.length} items for "$queryType".',
            );
          } catch (e) {
            debugPrint(
              '[SmartAudioSelector] Broad collection query failed: $e',
            );
          }
        }

        if (docs.isNotEmpty) {
          _memoryCache[queryType] = docs;
          _cacheTime[queryType] = DateTime.now();
        }
      }

      if (docs.isEmpty) {
        debugPrint(
          '[SmartAudioSelector] Warning: No documents found in `match_audio_pool` for "$queryType"',
        );
        return null;
      }

      // 3. കഴിഞ്ഞ 2 മണിക്കൂറിനുള്ളിൽ കേൾക്കാത്ത ഓഡിയോകൾ ഫിൽട്ടർ ചെയ്യുന്നു (2-hr cooldown)
      List<QueryDocumentSnapshot<Map<String, dynamic>>> eligibleAudios = docs
          .where((doc) => !playHistory.containsKey(doc.id))
          .toList();

      debugPrint(
        '[SmartAudioSelector] Eligible audios after 2-hour cooldown: ${eligibleAudios.length}/${docs.length}',
      );

      // എല്ലാ ഓഡിയോകളും ഇതിനകം കേട്ടുകഴിഞ്ഞെങ്കിൽ ലിസ്റ്റ് റീസെറ്റ് ചെയ്യുന്നു
      if (eligibleAudios.isEmpty) {
        debugPrint(
          '[SmartAudioSelector] All audios played within cooldown. Resetting cycle.',
        );
        eligibleAudios = docs;
        playHistory.clear();
      }

      // 4. റാൻഡമായി ഒരെണ്ണം തിരഞ്ഞെടുക്കുന്നു (20 ഫോണിലും വ്യത്യസ്ത ശബ്ദം വരാൻ)
      final random = Random();
      final selectedDoc =
          eligibleAudios[random.nextInt(eligibleAudios.length)];
      final selectedId = selectedDoc.id;
      final data = selectedDoc.data();
      final audioUrl =
          (data['audio_url'] ?? data['audioUrl'] ?? data['url']) as String?;
      final trimmedUrl = audioUrl?.trim();
      lastSelectedTitle = data['title']?.toString();

      debugPrint(
        '[SmartAudioSelector] Selected dialogue [ID: $selectedId, Title: "${data['title']}"]: $trimmedUrl',
      );

      if (trimmedUrl == null || trimmedUrl.isEmpty) {
        debugPrint(
          '[SmartAudioSelector] Selected track has empty audio URL.',
        );
        return null;
      }

      // 5. പുതിയ ഓഡിയോ കേട്ട സമയം സേവ് ചെയ്യുന്നു
      playHistory[selectedId] = now;
      List<String> updatedHistory = playHistory.entries
          .map((e) => '${e.key}|${e.value}')
          .toList();
      await prefs.setStringList(_historyKey, updatedHistory);

      return trimmedUrl;
    } catch (e, stack) {
      debugPrint('[SmartAudioSelector] Error selecting audio: $e');
      debugPrint('[SmartAudioSelector] Stack trace: $stack');
      return null;
    }
  }

  /// Clears in-memory cache to force next request to check Firestore cache/server
  static void clearMemoryCache() {
    _memoryCache.clear();
    _cacheTime.clear();
  }
}
