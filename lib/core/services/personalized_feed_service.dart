import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Personalized Recommendation Engine (Instagram-Style)
///
/// Tracks user preferences from liked profiles in both logged-in and guest mode
/// via [SharedPreferences] and in-memory caches.
///
/// Relevance Scoring Formula:
/// - +3 points: Profession matches user's top liked professions/jobs
/// - +2 points: District/Location matches user's top liked locations
/// - +1 point: Education matches user's top liked education levels
///
/// Feeds are sorted by `relevanceScore` descending, then by `createdAt` descending.
/// If no likes are tracked yet, falls back smoothly to recent profiles order.
class PersonalizedFeedService extends ChangeNotifier {
  static final PersonalizedFeedService _instance =
      PersonalizedFeedService._internal();
  static PersonalizedFeedService get instance => _instance;

  PersonalizedFeedService._internal() {
    init();
  }

  static const String _kProfessionsKey = 'feed_pref_liked_professions';
  static const String _kLocationsKey = 'feed_pref_liked_locations';
  static const String _kEducationsKey = 'feed_pref_liked_educations';
  static const String _kFeatureFreqKey = 'feed_pref_feature_frequencies';

  final Set<String> _dominantProfessions = {};
  final Set<String> _dominantLocations = {};
  final Set<String> _dominantEducations = {};

  final Map<String, int> _professionFreq = {};
  final Map<String, int> _locationFreq = {};
  final Map<String, int> _educationFreq = {};

  bool _isInitialized = false;

  Set<String> get dominantProfessions => Set.unmodifiable(_dominantProfessions);
  Set<String> get dominantLocations => Set.unmodifiable(_dominantLocations);
  Set<String> get dominantEducations => Set.unmodifiable(_dominantEducations);

  bool get hasPreferences =>
      _dominantProfessions.isNotEmpty ||
      _dominantLocations.isNotEmpty ||
      _dominantEducations.isNotEmpty;

  bool get isInitialized => _isInitialized;

  /// Loads stored preferences from SharedPreferences.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final profs = prefs.getStringList(_kProfessionsKey);
      if (profs != null) _dominantProfessions.addAll(profs);

      final locs = prefs.getStringList(_kLocationsKey);
      if (locs != null) _dominantLocations.addAll(locs);

      final edus = prefs.getStringList(_kEducationsKey);
      if (edus != null) _dominantEducations.addAll(edus);

      final freqRaw = prefs.getString(_kFeatureFreqKey);
      if (freqRaw != null) {
        final decoded = jsonDecode(freqRaw) as Map<String, dynamic>;
        if (decoded['professions'] is Map) {
          (decoded['professions'] as Map).forEach((k, v) {
            _professionFreq[k.toString()] = (v as num).toInt();
          });
        }
        if (decoded['locations'] is Map) {
          (decoded['locations'] as Map).forEach((k, v) {
            _locationFreq[k.toString()] = (v as num).toInt();
          });
        }
        if (decoded['educations'] is Map) {
          (decoded['educations'] as Map).forEach((k, v) {
            _educationFreq[k.toString()] = (v as num).toInt();
          });
        }
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('PersonalizedFeedService: Error loading preferences: $e');
    }
  }

  /// Cleans and normalizes text for robust token matching.
  static String normalize(String? text) {
    if (text == null) return '';
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\(\)\[\]\{\}\-\_\,\.\:\;\/\\\|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Records interaction when a user likes a profile.
  Future<void> recordLikedProfileFeatures({
    String? job,
    String? location,
    String? education,
  }) async {
    final normJob = normalize(job);
    final normLoc = normalize(location);
    final normEdu = normalize(education);

    bool changed = false;

    if (normJob.isNotEmpty && normJob != 'null' && normJob != 'none') {
      _professionFreq[normJob] = (_professionFreq[normJob] ?? 0) + 1;
      _dominantProfessions.add(normJob);
      changed = true;
    }

    if (normLoc.isNotEmpty && normLoc != 'null') {
      _locationFreq[normLoc] = (_locationFreq[normLoc] ?? 0) + 1;
      _dominantLocations.add(normLoc);
      changed = true;
    }

    if (normEdu.isNotEmpty && normEdu != 'null') {
      _educationFreq[normEdu] = (_educationFreq[normEdu] ?? 0) + 1;
      _dominantEducations.add(normEdu);
      changed = true;
    }

    if (changed) {
      _pruneAndPersist();
      notifyListeners();
    }
  }

  /// Rebuilds dominant feature sets from all currently liked profile objects or maps.
  Future<void> syncFromLikedProfiles(Iterable<dynamic> likedProfiles) async {
    _professionFreq.clear();
    _locationFreq.clear();
    _educationFreq.clear();
    _dominantProfessions.clear();
    _dominantLocations.clear();
    _dominantEducations.clear();

    for (final p in likedProfiles) {
      String? job;
      String? loc;
      String? edu;

      if (p is UserProfile) {
        job = p.job.isNotEmpty ? p.job : p.careerSector;
        loc = p.region.isNotEmpty ? p.region : p.familyDetails.prefDistrict;
        edu = p.educationLevel ?? p.educationOtherText;
      } else if (p is Map) {
        job = p['job']?.toString() ??
            p['occupation']?.toString() ??
            p['career_sector']?.toString();
        loc = p['region']?.toString() ??
            p['district']?.toString() ??
            p['location']?.toString() ??
            p['place']?.toString();
        edu = p['education_level']?.toString() ??
            p['education']?.toString();
      }

      final normJob = normalize(job);
      final normLoc = normalize(loc);
      final normEdu = normalize(edu);

      if (normJob.isNotEmpty && normJob != 'null') {
        _professionFreq[normJob] = (_professionFreq[normJob] ?? 0) + 1;
      }
      if (normLoc.isNotEmpty && normLoc != 'null') {
        _locationFreq[normLoc] = (_locationFreq[normLoc] ?? 0) + 1;
      }
      if (normEdu.isNotEmpty && normEdu != 'null') {
        _educationFreq[normEdu] = (_educationFreq[normEdu] ?? 0) + 1;
      }
    }

    _dominantProfessions.addAll(_getTopKeys(_professionFreq, 5));
    _dominantLocations.addAll(_getTopKeys(_locationFreq, 5));
    _dominantEducations.addAll(_getTopKeys(_educationFreq, 5));

    await _pruneAndPersist();
    notifyListeners();
  }

  List<String> _getTopKeys(Map<String, int> freq, int maxCount) {
    final entries = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(maxCount).map((e) => e.key).toList();
  }

  Future<void> _pruneAndPersist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kProfessionsKey, _dominantProfessions.toList());
      await prefs.setStringList(_kLocationsKey, _dominantLocations.toList());
      await prefs.setStringList(_kEducationsKey, _dominantEducations.toList());

      final payload = {
        'professions': _professionFreq,
        'locations': _locationFreq,
        'educations': _educationFreq,
      };
      await prefs.setString(_kFeatureFreqKey, jsonEncode(payload));
    } catch (e) {
      debugPrint('PersonalizedFeedService: Failed to persist preferences: $e');
    }
  }

  /// Calculates the relevance score for a given profile:
  /// - +3 if profession matches dominant liked professions
  /// - +2 if district/location matches dominant liked locations
  /// - +1 if education matches dominant liked education levels
  int calculateScore(dynamic profile) {
    if (!hasPreferences) return 0;

    String? job;
    String? loc;
    String? edu;

    if (profile is UserProfile) {
      job = profile.job.isNotEmpty ? profile.job : profile.careerSector;
      loc = profile.region.isNotEmpty
          ? profile.region
          : profile.familyDetails.prefDistrict;
      edu = profile.educationLevel ?? profile.educationOtherText;
    } else if (profile is Map) {
      job = profile['job']?.toString() ??
          profile['occupation']?.toString() ??
          profile['career_sector']?.toString();
      loc = profile['region']?.toString() ??
          profile['district']?.toString() ??
          profile['location']?.toString() ??
          profile['place']?.toString();
      edu = profile['education_level']?.toString() ??
          profile['education']?.toString();
    }

    int score = 0;

    final normJob = normalize(job);
    if (normJob.isNotEmpty && _matchesAny(normJob, _dominantProfessions)) {
      score += 3;
    }

    final normLoc = normalize(loc);
    if (normLoc.isNotEmpty && _matchesAny(normLoc, _dominantLocations)) {
      score += 2;
    }

    final normEdu = normalize(edu);
    if (normEdu.isNotEmpty && _matchesAny(normEdu, _dominantEducations)) {
      score += 1;
    }

    return score;
  }

  bool _matchesAny(String query, Set<String> targetSet) {
    if (query.isEmpty || targetSet.isEmpty) return false;
    if (targetSet.contains(query)) return true;

    for (final item in targetSet) {
      if (item.contains(query) || query.contains(item)) {
        return true;
      }
    }
    return false;
  }

  /// Extracts creation date for date-based sorting fallback.
  DateTime _extractCreatedAt(dynamic item) {
    if (item is UserProfile) {
      return item.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else if (item is Map) {
      final raw = item['created_at'] ?? item['createdAt'];
      if (raw is DateTime) return raw;
      if (raw != null) {
        return DateTime.tryParse(raw.toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Sorts any feed (UserProfile or Map) by:
  /// 1. `relevanceScore` descending
  /// 2. `createdAt` descending (newest first)
  ///
  /// Runs efficiently in-memory in O(N log N) time without blocking the UI thread.
  List<T> sortFeed<T>(List<T> profiles) {
    if (profiles.length <= 1) return List<T>.from(profiles);

    // Precalculate scores in O(N) pass to avoid re-evaluating during sort comparisons
    final scoreMap = <T, int>{};
    for (final p in profiles) {
      scoreMap[p] = calculateScore(p);
    }

    final sorted = List<T>.from(profiles);
    sorted.sort((a, b) {
      final scoreA = scoreMap[a] ?? 0;
      final scoreB = scoreMap[b] ?? 0;

      // 1. Relevance score descending
      if (scoreB != scoreA) {
        return scoreB.compareTo(scoreA);
      }

      // 2. Fallback to createdAt descending
      final dateA = _extractCreatedAt(a);
      final dateB = _extractCreatedAt(b);
      return dateB.compareTo(dateA);
    });

    return sorted;
  }
}
