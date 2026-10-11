import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureConfigItem {
  final String id;
  String title;
  String description;
  bool enabled;
  String iconName;
  String? imageUrl;
  int colorValue;
  bool isBuiltIn;

  FeatureConfigItem({
    required this.id,
    required this.title,
    required this.description,
    required this.enabled,
    this.iconName = 'tune',
    this.imageUrl,
    this.colorValue = 0xFF00BCD4,
    this.isBuiltIn = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'enabled': enabled,
    'icon_name': iconName,
    if (imageUrl != null) 'image_url': imageUrl,
    'color_value': colorValue,
    'is_built_in': isBuiltIn,
  };

  factory FeatureConfigItem.fromJson(Map<String, dynamic> json) =>
      FeatureConfigItem(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Untitled Feature',
        description: json['description'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
        iconName: json['icon_name'] as String? ?? 'tune',
        imageUrl: json['image_url'] as String?,
        colorValue: json['color_value'] as int? ?? 0xFF00BCD4,
        isBuiltIn: json['is_built_in'] as bool? ?? false,
      );
}

class GlobalFeaturesService extends ChangeNotifier {
  GlobalFeaturesService._();
  static final GlobalFeaturesService _instance = GlobalFeaturesService._();
  static GlobalFeaturesService get instance => _instance;

  final _supabase = Supabase.instance.client;

  List<FeatureConfigItem> _features = [];
  List<FeatureConfigItem> get features => List.unmodifiable(_features);

  // Backward compatibility getters
  bool get guestModeBlur => _getFeatureState('guestModeBlur');
  bool get panthiBandhuCheck => _getFeatureState('panthiBandhuCheck');
  bool get muraMatchSystem => _getFeatureState('muraMatchSystem');
  bool get compatibilityQuiz => _getFeatureState('compatibilityQuiz');

  bool _getFeatureState(String id) {
    try {
      final f = _features.firstWhere((item) => item.id == id);
      return f.enabled;
    } catch (_) {
      return true; // Default fallback
    }
  }

  static List<FeatureConfigItem> get _defaultFeatures => [
    FeatureConfigItem(
      id: 'guestModeBlur',
      title: 'Guest Mode Security',
      description:
          'When enabled, profile images are heavily blurred for non-registered/guest users to protect member privacy.',
      enabled: true,
      iconName: 'blur_on',
      colorValue: 0xFF00BCD4, // cyan
      isBuiltIn: true,
    ),
    FeatureConfigItem(
      id: 'panthiBandhuCheck',
      title: 'Moiety Compatibility Check',
      description:
          'Enforce traditional cross-moiety (Panthi & Bandhu) exogamy rules in calculations and the compatibility checker tool.',
      enabled: true,
      iconName: 'people_outline',
      colorValue: 0xFFFF4081, // pinkAccent
      isBuiltIn: true,
    ),
    FeatureConfigItem(
      id: 'muraMatchSystem',
      title: 'Mura Match Rules',
      description:
          'Enforce traditional age gap restrictions, marital history rules, and lineage checks in the partner matching system.',
      enabled: true,
      iconName: 'favorite_border',
      colorValue: 0xFFFFAB40, // orangeAccent
      isBuiltIn: true,
    ),
    FeatureConfigItem(
      id: 'compatibilityQuiz',
      title: 'Compatibility Quiz System',
      description:
          'Show compatibility scores and dynamic partner preference questionnaires on user profile detail pages.',
      enabled: true,
      iconName: 'question_answer_outlined',
      colorValue: 0xFFE040FB, // purpleAccent
      isBuiltIn: true,
    ),
  ];

  /// Loads settings from Supabase, or seeds defaults if missing.
  Future<void> loadSettings() async {
    try {
      final res = await _supabase
          .from('system_settings')
          .select('value')
          .eq('key', 'global_features_config')
          .maybeSingle();

      if (res != null && res['value'] != null) {
        _parseAndSetJson(res['value'] as String);
      } else {
        _features = List.from(_defaultFeatures);
        await _saveToSupabase();
      }
    } catch (e) {
      debugPrint('GlobalFeaturesService: Error loading settings: $e');
      if (_features.isEmpty) {
        _features = List.from(_defaultFeatures);
      }
    }
  }

  Future<void> toggleFeature(String id, bool value) async {
    final index = _features.indexWhere((f) => f.id == id);
    if (index != -1) {
      _features[index].enabled = value;
      notifyListeners();
      await _saveToSupabase();
    }
  }

  Future<void> addFeature(FeatureConfigItem newItem) async {
    _features.add(newItem);
    notifyListeners();
    await _saveToSupabase();
  }

  Future<void> updateFeature(FeatureConfigItem updatedItem) async {
    final index = _features.indexWhere((f) => f.id == updatedItem.id);
    if (index != -1) {
      _features[index] = updatedItem;
      notifyListeners();
      await _saveToSupabase();
    }
  }

  Future<void> deleteFeature(String id) async {
    _features.removeWhere((f) => f.id == id);
    notifyListeners();
    await _saveToSupabase();
  }

  /// Deprecated legacy updater for backwards compatibility
  Future<void> updateSettings({
    required bool guestModeBlur,
    required bool panthiBandhuCheck,
    required bool muraMatchSystem,
    required bool compatibilityQuiz,
  }) async {
    toggleFeature('guestModeBlur', guestModeBlur);
    toggleFeature('panthiBandhuCheck', panthiBandhuCheck);
    toggleFeature('muraMatchSystem', muraMatchSystem);
    toggleFeature('compatibilityQuiz', compatibilityQuiz);
  }

  Future<void> _saveToSupabase() async {
    final listJson = jsonEncode(_features.map((f) => f.toJson()).toList());
    try {
      // Primary storage in system_settings
      await _supabase.from('system_settings').upsert({
        'key': 'global_features_config',
        'value': listJson,
      });

      // Secondary sync to feature_toggles table if present
      try {
        await _supabase.from('feature_toggles').upsert({
          'key': 'global_features_config',
          'config_data': listJson,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e2) {
        debugPrint(
          'GlobalFeaturesService: feature_toggles table update note: $e2',
        );
      }
    } catch (e) {
      debugPrint(
        'GlobalFeaturesService: Error saving settings to Supabase: $e',
      );
    }
  }

  void _parseAndSetJson(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        _features = decoded
            .map(
              (item) =>
                  FeatureConfigItem.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else if (decoded is Map<String, dynamic>) {
        // Legacy format migration
        _features = List.from(_defaultFeatures);
        for (var f in _features) {
          if (f.id == 'guestModeBlur')
  { f.enabled = decoded['guest_mode_blur'] ?? true; }
          if (f.id == 'panthiBandhuCheck')
  { f.enabled = decoded['panthi_bandhu_check'] ?? true; }
          if (f.id == 'muraMatchSystem')
  { f.enabled = decoded['mura_match_system'] ?? true; }
          if (f.id == 'compatibilityQuiz')
  { f.enabled = decoded['compatibility_quiz'] ?? true; }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('GlobalFeaturesService: Error parsing settings JSON: $e');
    }
  }

  /// Subscribes to real-time updates for key = 'global_features_config'
  void initRealtimeListener() {
    try {
      _supabase
          .from('system_settings')
          .stream(primaryKey: ['key'])
          .eq('key', 'global_features_config')
          .listen(
            (data) {
              if (data.isNotEmpty) {
                final value = data.first['value'] as String?;
                if (value != null) {
                  _parseAndSetJson(value);
                }
              }
            },
            onError: (err) {
              debugPrint('GlobalFeaturesService: Realtime stream error: $err');
            },
          );
    } catch (e) {
      debugPrint(
        'GlobalFeaturesService: Failed to initialize realtime stream: $e',
      );
    }
  }
}
