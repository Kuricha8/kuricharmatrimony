// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Fetch thugs', () async {
    SharedPreferences.setMockInitialValues({});
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? 'dummy',
      publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'dummy',
    );
    
    try {
      final response = await Supabase.instance.client
          .from('kurichar_matrimony_thugs')
          .select('id, dialogue')
          .timeout(const Duration(seconds: 2));
      
      print('THUGS_COUNT: ${response.length}');
      // Write to JSON for another script to read
      File('thugs_data.json').writeAsStringSync(jsonEncode(response));
    } catch(e) {
      print('THUGS_ERROR: $e');
    }
  });
}
