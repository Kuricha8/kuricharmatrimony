import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_dictionary.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService instance = LocalizationService._internal();

  String _currentLanguage = 'ENGLISH';
  String get currentLanguage => _currentLanguage;

  LocalizationService._internal() {
    _initLanguage();
  }

  Future<void> _initLanguage() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('user_settings')
            .select('app_language')
            .eq('user_id', user.id)
            .maybeSingle();

        if (data != null && data['app_language'] != null) {
          _currentLanguage = data['app_language'] as String;
          notifyListeners();
        } else {
          // Create default row if it doesn't exist
          await Supabase.instance.client.from('user_settings').insert({
            'user_id': user.id,
            'app_language': 'ENGLISH',
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing language: $e');
    }
  }

  Future<void> setLanguage(String newLanguage) async {
    if (!['ENGLISH', 'MALAYALAM', 'HINDI'].contains(newLanguage)) return;
    if (_currentLanguage == newLanguage) return;

    _currentLanguage = newLanguage;
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('user_settings').upsert({
          'user_id': user.id,
          'app_language': newLanguage,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
      }
    } catch (e) {
      debugPrint('Error updating language in DB: $e');
    }
  }

  String translate(String key) {
    final languageDict =
        appDictionary[_currentLanguage] ?? appDictionary['ENGLISH']!;
    return languageDict[key] ?? key;
  }
}
