import 'package:flutter_test/flutter_test.dart';
import 'package:kurichiyar_matrimony/core/models/models.dart';
import 'package:kurichiyar_matrimony/features/clan_feed/tharavadu_list.dart';

void main() {
  group('Realtime Clan Single Source of Truth & Authoritative Name Tests', () {
    test('Clan.displayName strictly returns the single authoritative name saved by Admin', () {
      final clan = Clan.fromMap({
        'id': 101,
        'name_ml': 'പുച്ചിയേരി (ചായമൽ)',
        'name_en': 'Puchiyeri',
        'type': 'bandhu',
        'group_name': 'ബന്ധു ഗ്രൂപ്പ്',
        'is_active': true,
      });

      // Must NOT strip and duplicate parentheses or synthesize sub-branch
      expect(clan.name, 'പുച്ചിയേരി (ചായമൽ)');
      expect(clan.displayName, 'പുച്ചിയേരി (ചായമൽ)');
      expect(clan.displayLabel, 'പുച്ചിയേരി (ചായമൽ)');
    });

    test('Clan with plain name returns authoritative name without synthetic location suffixes', () {
      final clan = Clan.fromMap({
        'id': 102,
        'name': 'കാര്യമ്പത്ത്',
        'type': 'pandi',
        'group_name': 'പന്തി ഗ്രൂപ്പ്',
        'location': 'മാനന്തവാടി',
        'is_active': true,
      });

      expect(clan.name, 'കാര്യമ്പത്ത്');
      expect(clan.displayName, 'കാര്യമ്പത്ത്');
      expect(clan.displayLabel, 'കാര്യമ്പത്ത്');
    });

    test('TharavaduService reactive add, update, and delete triggers notifyListeners instantly', () {
      final service = TharavaduService.instance;
      service.resetToDefaults();

      int notifyCount = 0;
      void listener() {
        notifyCount++;
      }

      service.addListener(listener);

      // 1. Add Clan
      final newClan = Clan.fromMap({
        'id': 200,
        'name': 'ടെസ്റ്റ് തറവാട്',
        'name_ml': 'ടെസ്റ്റ് തറവാട്',
        'type': 'bandhu',
        'group_name': 'ബന്ധു ഗ്രൂപ്പ്',
        'is_active': true,
      });

      service.addOrUpdateClanLocally(newClan);
      expect(notifyCount, 1);
      expect(TharavaduService.bandhuClans.any((c) => c.id == 200), isTrue);
      expect(TharavaduService.allClans.any((c) => c.id == 200), isTrue);
      expect(getClanById(200)?.displayName, 'ടെസ്റ്റ് തറവാട്');

      // 2. Update Clan (e.g. Admin edits name)
      final updatedClan = Clan.fromMap({
        'id': 200,
        'name': 'ടെസ്റ്റ് തറവാട് എഡിറ്റ് ചെയ്തത്',
        'name_ml': 'ടെസ്റ്റ് തറവാട് എഡിറ്റ് ചെയ്തത്',
        'type': 'bandhu',
        'group_name': 'ബന്ധു ഗ്രൂപ്പ്',
        'is_active': true,
      });

      service.addOrUpdateClanLocally(updatedClan);
      expect(notifyCount, 2);
      expect(getClanById(200)?.displayName, 'ടെസ്റ്റ് തറവാട് എഡിറ്റ് ചെയ്തത്');

      // 3. Delete Clan
      service.removeClanLocally(200);
      expect(notifyCount, 3);
      expect(TharavaduService.bandhuClans.any((c) => c.id == 200), isFalse);
      expect(getClanById(200), isNull);

      service.removeListener(listener);
    });

    test('getClanByName looks up accurately without hardcoded clan-name hacks', () {
      final service = TharavaduService.instance;
      service.resetToDefaults();

      final clan = Clan.fromMap({
        'id': 301,
        'name': 'കരിമ്പിച്ചി',
        'name_ml': 'കരിമ്പിച്ചി',
        'type': 'pandi',
        'group_name': 'പന്തി ഗ്രൂപ്പ്',
        'is_active': true,
      });
      service.addOrUpdateClanLocally(clan);

      final found = getClanByName('കരിമ്പിച്ചി');
      expect(found, isNotNull);
      expect(found?.id, 301);
      expect(found?.displayName, 'കരിമ്പിച്ചി');
    });
  });
}
