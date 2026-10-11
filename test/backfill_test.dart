// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Inspect candidate injection', () async {
    final supabase = SupabaseClient(
      'https://noidreeslytswkmsnmcn.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vaWRyZWVzbHl0c3drbXNubWNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5NTA2ODksImV4cCI6MjA5OTUyNjY4OX0.VnpX0xjRNi89efECRAzMiu79trSQlblpRjfWZLkjMo4',
    );

    final res = await supabase
        .from('kurichiyar_profiles')
        .select('id, full_name, photo_url, father_clan_id, mother_clan_id, age, gender, father_tharavadu, mother_tharavadu, account_status, status');

    print('Fetched ${res.length} profiles from database:');
    for (final r in res) {
      final isApp = r['account_status'].toString().toLowerCase() == 'approved' ||
          r['status'].toString().toLowerCase() == 'approved' ||
          r['account_status'].toString().toLowerCase() == 'active';
      print('Name: ${r['full_name']}, Status: ${r['account_status']}/${r['status']}, isApp: $isApp');
    }
  });
}
