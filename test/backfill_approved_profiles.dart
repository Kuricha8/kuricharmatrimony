// ignore_for_file: avoid_print
@Timeout(Duration(minutes: 5))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kurichiyar_matrimony/features/clan_feed/tharavadu_list.dart';

void main() {
  test('Execute matrimony profile card backfill for approved profiles', () async {
    print('Starting database profile cards backfill...');
    final supabase = SupabaseClient(
      'https://noidreeslytswkmsnmcn.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vaWRyZWVzbHl0c3drbXNubWNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5NTA2ODksImV4cCI6MjA5OTUyNjY4OX0.VnpX0xjRNi89efECRAzMiu79trSQlblpRjfWZLkjMo4',
    );

    // Clean test row
    try {
      await supabase.from('tharavad_master').delete().eq('name', 'Test');
    } catch (_) {}

    // ─── STEP 0: Delete PROFILE_CARD messages for admin/anonymous senders ────
    print('Step 0: Cleaning up admin/anonymous profile cards from taravad_messages...');
    int deletedCount = 0;
    try {
      final allCards = await supabase
          .from('taravad_messages')
          .select('id, sender_name, message_type, user_id')
          .eq('message_type', 'PROFILE_CARD');

      for (final card in allCards) {
        final senderName = (card['sender_name'] ?? '').toString().trim().toLowerCase();
        final userId = (card['user_id'] ?? '').toString().trim().toLowerCase();

        final bool isAdminCard = senderName.isEmpty ||
            senderName == 'anonymous' ||
            senderName == 'admin' ||
            senderName == 'system' ||
            userId == 'system';

        if (isAdminCard) {
          print('Deleting admin/anonymous profile card id=${card['id']} sender=${card['sender_name']}');
          try {
            await supabase.from('taravad_messages').delete().eq('id', card['id']);
            deletedCount++;
          } catch (e) {
            print('Note: could not delete card ${card['id']}: $e');
          }
        } else {
          // Also verify the linked kurichiyar_profiles row is not an admin
          // by checking against known admin roles
          try {
            final allProfiles = await supabase
                .from('kurichiyar_profiles')
                .select('id, full_name, role')
                .eq('full_name', card['sender_name']);

            for (final p in allProfiles) {
              final role = (p['role'] ?? '').toString().trim().toLowerCase();
              if (role == 'admin' || role == 'moderator' || role == 'superadmin') {
                print('Deleting profile card for admin role user: ${card['sender_name']}');
                await supabase.from('taravad_messages').delete().eq('id', card['id']);
                deletedCount++;
                break;
              }
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      print('Note: cleanup step skipped or partial: $e');
    }
    print('Cleanup complete. Removed $deletedCount admin/anonymous profile cards.');

    // ─── STEP 1: Fetch approved NON-ADMIN profiles ───────────────────────────
    final profilesRes = await supabase
        .from('kurichiyar_profiles')
        .select('id, full_name, photo_url, father_clan_id, mother_clan_id, age, gender, account_status, status, role');

    final approvedProfiles = [];
    for (final r in profilesRes) {
      final name = (r['full_name'] ?? '').toString().trim().toLowerCase();
      final role = (r['role'] ?? '').toString().trim().toLowerCase();

      // Exclude admin / anonymous / system users
      if (role == 'admin' || role == 'moderator' || role == 'superadmin') continue;
      if (name.isEmpty || name == 'anonymous' || name == 'admin' || name == 'system') continue;

      final isApproved = r['account_status'].toString().toLowerCase() == 'approved' ||
          r['status'].toString().toLowerCase() == 'approved' ||
          r['account_status'].toString().toLowerCase() == 'active';

      if (isApproved) {
        approvedProfiles.add(r);
      }
    }
    print('Found ${approvedProfiles.length} approved non-admin profiles in DB.');

    // ─── STEP 2: Fetch clans or seed if empty ────────────────────────────────
    var clansRes = await supabase.from('tharavad_master').select('id, name, tharavadu_ml, group_name');
    if (clansRes.isEmpty) {
      print('tharavad_master is empty in DB. Seeding from allClans...');
      for (final clan in allClans) {
        try {
          await supabase.from('tharavad_master').insert({
            'id': clan.id,
            'name': clan.name,
            'name_ml': clan.nameMl,
            'tharavadu_ml': clan.nameMl,
            'group_name': clan.groupName,
          });
        } catch (e) {
          print('Error seeding clan ${clan.id}: $e');
        }
      }
      clansRes = await supabase.from('tharavad_master').select('id, name, tharavadu_ml, group_name');
    }
    print('Found ${clansRes.length} clans in DB.');

    // ─── STEP 3: Inject missing profile cards for compatible clans ───────────
    int backfillCount = 0;
    for (final clan in clansRes) {
      final clanId = clan['id'] as int;

      for (final profile in approvedProfiles) {
        final fClanId = (profile['father_clan_id'] as int?) ?? 0;
        final mClanId = (profile['mother_clan_id'] as int?) ?? 0;

        if (fClanId == clanId || mClanId == clanId) continue;

        bool compatible = false;
        try {
          final checkRes = await supabase.rpc('check_tharavad_compatibility', params: {
            'candidate_tharavad_id': fClanId,
            'target_chat_tharavad_id': clanId,
          });
          compatible = (checkRes == true);
        } catch (_) {
          compatible = (fClanId != clanId && mClanId != clanId);
        }

        if (!compatible) continue;

        // Skip if already injected (check by sender_name + message_type)
        bool alreadyInDb = false;
        try {
          final check = await supabase
              .from('taravad_messages')
              .select('id')
              .eq('message_type', 'PROFILE_CARD')
              .eq('sender_name', profile['full_name'] ?? '')
              .maybeSingle();
          alreadyInDb = (check != null);
        } catch (_) {}

        if (!alreadyInDb) {
          final clanName = clan['name'] ?? clan['tharavadu_ml'] ?? 'Clan';
          print('Backfilling: ${profile['full_name']} → $clanName');
          try {
            await supabase.from('taravad_messages').insert({
              'user_id': 'system',
              'sender_name': profile['full_name'] ?? 'അംഗം',
              'sender_photo': profile['photo_url'] ?? '',
              'text': 'അനുമതി നൽകിയ പുതിയ വരൻ / വധു പ്രൊഫൈൽ കാർഡ്',
              'media_url': profile['photo_url'] ?? '',
              'message_type': 'PROFILE_CARD',
              'is_profile_card': true,
            });
            backfillCount++;
          } catch (e) {
            print('Note: insert skipped: $e');
          }
        }
      }
    }

    print('Backfill complete. Injected $backfillCount profile cards.');
   });
}
