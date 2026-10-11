import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PunchlineCacheService {
  static const String _cacheKey = 'cached_match_punchlines';
  static const String _cooldownKey = 'punchline_cooldowns';

  /// Fetches all punchlines from Supabase and saves them to local SharedPreferences.
  /// Should be called asynchronously during app startup.
  static Future<void> syncPunchlines() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('match_punchlines').select();

      if (response.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(response);
        await prefs.setString(_cacheKey, jsonString);
        debugPrint('Successfully synced  punchlines to local cache.');
      }
    } catch (e) {
      debugPrint('Failed to sync punchlines to cache: ');
    }
  }

  /// Retrieves a list of dialogue IDs that were played within the last 2 hours.
  static Future<List<int>> getExcludedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cooldownString = prefs.getString(_cooldownKey);
      if (cooldownString == null || cooldownString.isEmpty) return [];

      final Map<String, dynamic> cooldowns = jsonDecode(cooldownString);
      final now = DateTime.now();
      final List<int> excludedIds = [];
      final Map<String, dynamic> validCooldowns = {};

      cooldowns.forEach((idStr, timestampStr) {
        final timestamp = DateTime.tryParse(timestampStr.toString());
        if (timestamp != null) {
          final difference = now.difference(timestamp);
          // Keep if it was played within the last 2 hours
          if (difference.inHours < 2) {
            excludedIds.add(int.parse(idStr));
            validCooldowns[idStr] = timestampStr;
          }
        }
      });

      // Save the cleaned map back to prefs to prevent it from growing indefinitely
      await prefs.setString(_cooldownKey, jsonEncode(validCooldowns));
      return excludedIds;
    } catch (e) {
      debugPrint('Error getting excluded IDs: ');
      return [];
    }
  }

  /// Marks a dialogue as played, starting its 2-hour cooldown timer.
  static Future<void> markDialogueAsPlayed(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cooldownString = prefs.getString(_cooldownKey);
      Map<String, dynamic> cooldowns = {};

      if (cooldownString != null && cooldownString.isNotEmpty) {
        cooldowns = jsonDecode(cooldownString);
      }

      cooldowns[id.toString()] = DateTime.now().toIso8601String();
      await prefs.setString(_cooldownKey, jsonEncode(cooldowns));
      debugPrint('Marked dialogue  as played for 2-hour cooldown.');
    } catch (e) {
      debugPrint('Error marking dialogue as played: ');
    }
  }

  /// Retrieves a random punchline from the local cache based on status.
  /// Returns null if the cache is empty or no match is found.
  static Future<Map<String, dynamic>?> getRandomPunchline(
    String statusParam, {
    List<int> excludedIds = const [],
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> allPunchlines = jsonDecode(jsonString);

        // Filter by status (e.g. 'SUCCESS', 'NO_MATCH') and ensure it's not in excludedIds
        final matchingPunchlines = allPunchlines.where((row) {
          final isCorrectStatus = row['status']?.toString() == statusParam;
          final id = int.tryParse(row['id']?.toString() ?? '');
          final isExcluded = id != null && excludedIds.contains(id);
          return isCorrectStatus && !isExcluded;
        }).toList();

        if (matchingPunchlines.isNotEmpty) {
          // Pick a random row
          final randomIndex = Random.secure().nextInt(
            matchingPunchlines.length,
          );
          return matchingPunchlines[randomIndex] as Map<String, dynamic>;
        } else {
          // If all valid punchlines are currently in cooldown, fallback to ignoring the cooldown locally
          final backupPunchlines = allPunchlines
              .where((row) => row['status']?.toString() == statusParam)
              .toList();
          if (backupPunchlines.isNotEmpty) {
            final randomIndex = Random.secure().nextInt(
              backupPunchlines.length,
            );
            return backupPunchlines[randomIndex] as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading punchline from local cache: ');
    }
    return null;
  }
}
