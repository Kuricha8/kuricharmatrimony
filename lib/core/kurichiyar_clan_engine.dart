// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/clan_feed/tharavadu_list.dart';

class KurichiyarClanEngine {
  static const String PANTHI = 'PANTHI';
  static const String BANDHU = 'BANDHU';

  // Identify Moiety strictly from Tharavad Name dynamically via TharavaduService
  static String getMoiety(String tharavad) {
    final t = tharavad.toLowerCase().trim();
    if (t.isEmpty) return BANDHU;

    // 1. Exact / alias lookup in live Tharavadu list
    final clan = getClanByName(tharavad);
    if (clan != null) {
      final isBandhu =
          clan.type.toLowerCase() == 'bandhu' ||
          clan.groupName.contains('ബന്ധു');
      return isBandhu ? BANDHU : PANTHI;
    }

    // 2. Partial name match in live Tharavadu list
    for (var c in TharavaduService.allClans) {
      final h = c.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (h.isNotEmpty && (t.contains(h) || h.contains(t))) {
        final isBandhu =
            c.type.toLowerCase() == 'bandhu' || c.groupName.contains('ബന്ധു');
        return isBandhu ? BANDHU : PANTHI;
      }
    }

    if (t.contains('bandhu') || t.contains('ബന്ധു')) {
      return BANDHU;
    }
    if (t.contains('panthi') || t.contains('pandi') || t.contains('പന്തി')) {
      return PANTHI;
    }

    return BANDHU;
  }

  // Alias for legacy calls
  static String extractMoiety(String tharavad) => getMoiety(tharavad);

  // Cross-Moiety Match: Panthi -> Bandhu, Bandhu -> Panthi
  static String getOppositeTargetMoiety(String userMotherTharavad) {
    final currentMoiety = getMoiety(userMotherTharavad);
    return (currentMoiety == PANTHI) ? BANDHU : PANTHI;
  }

  // Fetch compatible exogamous matrimony profiles
  static Future<List<Map<String, dynamic>>> fetchCompatibleFeedProfiles({
    required String currentUserId,
    required String currentUserMotherTharavad,
    required String currentUserFatherTharavad,
  }) async {
    // 1. Determine target opposite moiety (Panthi gets Bandhu, Bandhu gets Panthi)
    final String targetMoiety = getOppositeTargetMoiety(
      currentUserMotherTharavad,
    );

    // 2. Fetch from Supabase
    final response = await Supabase.instance.client
        .from('kurichiyar_profiles')
        .select()
        .eq('moiety', targetMoiety) // STRICT OPPOSITE MOIETY
        .neq('id', currentUserId) // Exclude own profile
        .eq('status', 'approved');

    // 3. Filter out immediate father and mother house matches
    final filteredList = (response as List).where((item) {
      final itemTharavad = (item['mother_tharavadu'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final mom = currentUserMotherTharavad.trim().toLowerCase();
      final dad = currentUserFatherTharavad.trim().toLowerCase();

      return itemTharavad != mom && itemTharavad != dad;
    }).toList();

    return List<Map<String, dynamic>>.from(filteredList);
  }

  // Sort top horizontal tharavad circles dynamically for ANY logged-in user
  static List<Map<String, dynamic>> organizeTharavadCircles({
    required List<Map<String, dynamic>> allCircles,
    required String userMotherTharavad,
  }) {
    List<Map<String, dynamic>> sortedList = List.from(allCircles);

    int userIndex = sortedList.indexWhere((circle) {
      final name = circle['name'].toString().trim().toLowerCase();
      return name.contains(userMotherTharavad.toLowerCase()) ||
          userMotherTharavad.toLowerCase().contains(name);
    });

    if (userIndex != -1) {
      final myCircle = sortedList.removeAt(userIndex);
      sortedList.insert(0, myCircle); // Pin to position 1
    }

    return sortedList;
  }

  // Colorful Decoration Provider for the User's Tharavad Circle:
  static BoxDecoration getTharavadCircleBorder(bool isMyTharavad) {
    if (isMyTharavad) {
      return const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF00E676),
            Color(0xFFFFD600),
            Color(0xFFFF3D00),
          ], // Vibrant colorful border
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    return BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white24, width: 1.5),
    );
  }
}
