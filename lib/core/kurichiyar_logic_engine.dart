// ignore_for_file: constant_identifier_names
import 'package:flutter/foundation.dart';
import '../features/clan_feed/tharavadu_list.dart';

/// Kurichiyar Kinship & Moiety Logic Engine.
///
/// Fully dynamic: completely removed static hardcoded clan arrays.
/// All Tharavadu lineages are resolved dynamically from Supabase via TharavaduService.
class KurichiyarLogicEngine {
  static const String PANTHI = 'PANTHI';
  static const String BANDHU = 'BANDHU';

  /// Identify Moiety strictly from Tharavadu name dynamically from Supabase
  static String getMoiety(String taravadName) {
    final t = taravadName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) return BANDHU;

    // 1. Dynamic resolution against live Tharavadu list from Supabase
    final clan = getClanByName(taravadName);
    if (clan != null) {
      final isBandhu =
          clan.type.toLowerCase() == 'bandhu' ||
          clan.groupName.contains('ബന്ധു');
      final result = isBandhu ? BANDHU : PANTHI;
      debugPrint(
        "DEBUG MOIETY: $taravadName -> $result (resolved via TharavaduService)",
      );
      return result;
    }

    // 2. Dynamic lookup across all live clans from Supabase
    for (var c in TharavaduService.allClans) {
      final h = c.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (h.isNotEmpty && (t.contains(h) || h.contains(t))) {
        final isBandhu =
            c.type.toLowerCase() == 'bandhu' || c.groupName.contains('ബന്ധു');
        final result = isBandhu ? BANDHU : PANTHI;
        debugPrint("DEBUG MOIETY: $taravadName -> $result");
        return result;
      }
    }

    // 3. Fallback keyword check if clan name contains indicator
    if (t.contains('bandhu') || t.contains('ബന്ധു')) {
      debugPrint("DEBUG MOIETY: $taravadName -> BANDHU");
      return BANDHU;
    }
    if (t.contains('panthi') || t.contains('pandi') || t.contains('പന്തി')) {
      debugPrint("DEBUG MOIETY: $taravadName -> PANTHI");
      return PANTHI;
    }

    debugPrint("DEBUG MOIETY: $taravadName -> BANDHU (default)");
    return BANDHU;
  }

  /// Cross-Moiety Match: Panthi -> Bandhu, Bandhu -> Panthi
  static String getOppositeTargetMoiety(String userMotherTharavad) {
    final currentMoiety = getMoiety(userMotherTharavad);
    return (currentMoiety == PANTHI) ? BANDHU : PANTHI;
  }

  /// Dynamically returns allowed marriage houses from Supabase TharavaduService
  static List<String> getAllowedMarriageHouses(String motherTaravad) {
    final userMoiety = getMoiety(motherTaravad);
    if (userMoiety == PANTHI) {
      // Dynamic Bandhu clans from TharavaduService
      return TharavaduService.bandhuClans.map((c) => c.name).toList();
    } else {
      // Dynamic Panthi clans from TharavaduService
      return TharavaduService.pandiClans.map((c) => c.name).toList();
    }
  }
}
