// =============================================================
// KURICHIYAR MATRIMONY - 300 LOCAL THUG DIALOGUES WITH SMART GATE
// =============================================================

import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ThugDialogues {
  // 1. FALLBACK DIALOGUES (In case local cache is empty and network fails)
  static const List<String> fallbackYes = [
    'ആചാരവും നെറിയും ഒത്തുചേർന്നു, ഇനി അമ്പും വില്ലുമെടുത്ത് കല്യാണത്തിന് റെഡിയായിക്കോ!',
    'തറവാട്ടു പൊരുത്തം 100% പക്കാ! സമുദായത്തിന്റെ അന്തസ്സ് ഉയർത്തിപ്പിടിക്കുന്ന മാച്ച്.',
    'ചരിത്രം കുറിക്കാൻ പോകുന്ന പുതിയൊരു കുടുംബം ഇവിടെ പിറവിയെടുക്കുകയാണ്!',
  ];

  static const List<String> fallbackNo = [
    'മാതൃഗോത്രം ഒന്നായതിനാൽ ഒരേ ഗോത്രത്തിൽ പെട്ടവർക്ക് വിവാഹം അനുവദനീയമല്ല.',
    'ആചാരപ്രകാരം ഈ ബന്ധം അസാധുവാണ്. സമുദായ നിയമം പാലിക്കുക.',
    'ഇതൊരു ചേർച്ചയല്ല. വേറൊരു പൊരുത്തം അന്വേഷിക്കുക.',
  ];

  // 2. ASYNC FETCH & PERSISTENT CACHE (Runs quietly in background)
  static Future<void> syncDialoguesFromCloud() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // We only fetch if it's been more than 7 days, or if cache is totally empty
      final lastSyncStr = prefs.getString('thug_dialogue_last_sync');
      bool needsSync = true;
      if (lastSyncStr != null) {
        final lastSync = DateTime.parse(lastSyncStr);
        if (DateTime.now().difference(lastSync).inDays < 7) {
          needsSync = false;
        }
      }

      final hasYes = prefs.getString('thug_dialogues_yes_cache') != null;
      if (!needsSync && hasYes) return;

      debugPrint('Fetching dialogues from Supabase in background...');
      final response = await Supabase.instance.client
          .from('thug_dialogues')
          .select('category, dialogue_text');

      final List<dynamic> records = response;
      if (records.isNotEmpty) {
        List<String> yesList = [];
        List<String> noList = [];

        for (var row in records) {
          if (row['category'] == 'MATCH') {
            yesList.add(row['dialogue_text'].toString());
          } else if (row['category'] == 'NO_MATCH') {
            noList.add(row['dialogue_text'].toString());
          }
        }

        if (yesList.isNotEmpty) {
          await prefs.setString(
            'thug_dialogues_yes_cache',
            jsonEncode(yesList),
          );
        }
        if (noList.isNotEmpty) {
          await prefs.setString('thug_dialogues_no_cache', jsonEncode(noList));
        }
        await prefs.setString(
          'thug_dialogue_last_sync',
          DateTime.now().toIso8601String(),
        );
        debugPrint('Dialogues synced and cached successfully!');
      }
    } catch (e) {
      debugPrint('Background dialogue sync failed: $e');
    }
  }

  // 3. 🚨 INSTANT PER-CLICK RANDOMIZATION
  static Future<String> getDailyDialogue(
    bool isCompatible,
    String deviceId,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Read from local cache, fallback to defaults if empty
    List<String> currentPool = isCompatible ? fallbackYes : fallbackNo;
    final cacheKey = isCompatible
        ? 'thug_dialogues_yes_cache'
        : 'thug_dialogues_no_cache';
    final cachedStr = prefs.getString(cacheKey);

    if (cachedStr != null) {
      try {
        currentPool = List<String>.from(jsonDecode(cachedStr));
      } catch (e) {
        debugPrint('Error decoding cached dialogues: $e');
      }
    }

    // Ultra-randomization: Use Math.random combined with milliseconds and device ID hash
    int deviceHash = 0;
    for (int i = 0; i < deviceId.length; i++) {
      deviceHash = deviceId.codeUnitAt(i) + ((deviceHash << 5) - deviceHash);
    }
    // dynamic seed based on precise microsecond time + device hash
    int seed = DateTime.now().microsecondsSinceEpoch + deviceHash.abs();

    math.Random random = math.Random(seed);

    // Unpredictable array shuffle algorithm
    List<String> shuffledPool = List.from(currentPool);
    shuffledPool.shuffle(random);

    // Return a highly randomized dialogue text per click
    return shuffledPool.first;
  }
}
