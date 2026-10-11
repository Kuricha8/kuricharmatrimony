import 'package:flutter/material.dart';
import '../../features/clan_feed/tharavadu_list.dart';

// ─── Universal Moiety Color System ─────────────────────────────────────────────
// BANDHU group → Green (ബന്ധു)
// PANDI  group → Red   (പന്തി)
// Unknown      → Grey
// ─────────────────────────────────────────────────────────────────────────────

/// Canonical moiety keys
const String kBandhu = 'BANDHU';
const String kPandi = 'PANDI';

class MoietyColors {
  MoietyColors._();

  // ── BANDHU ──────────────────────────────────────────────────────────────────
  static const Color bandhuBackground = Colors.white; // Clean white without tints
  static const Color bandhuText = Color(0xFF1E1E1E); // Standard dark text
  static const Color bandhuBorder = Color(0xFFE0E0E0); // Light divider border

  // ── PANDI ───────────────────────────────────────────────────────────────────
  static const Color pandiBackground = Colors.white; // Clean white without tints
  static const Color pandiText = Color(0xFF1E1E1E); // Standard dark text
  static const Color pandiBorder = Color(0xFFE0E0E0); // Light divider border

  // ── Fallback ─────────────────────────────────────────────────────────────────
  static const Color unknownBackground = Color(0xFFF5F5F5);
  static const Color unknownText = Color(0xFF757575);
  static const Color unknownBorder = Color(0xFFBDBDBD);

  // ── Lookups by clan ID ───────────────────────────────────────────────────────

  /// Returns the background color for a clan based on its ID.
  static Color backgroundForId(int id) {
    final clan = getClanById(id);
    if (clan != null) {
      return backgroundForType(
        clan.type.isNotEmpty ? clan.type : clan.groupName,
      );
    }
    return (id % 2 != 0) ? pandiBackground : bandhuBackground;
  }

  /// Returns the text/badge color for a clan based on its ID.
  static Color textForId(int id) {
    final clan = getClanById(id);
    if (clan != null)
  { return textForType(clan.type.isNotEmpty ? clan.type : clan.groupName); }
    return (id % 2 != 0) ? pandiText : bandhuText;
  }

  /// Returns the border color for a clan based on its ID.
  static Color borderForId(int id) {
    final clan = getClanById(id);
    if (clan != null)
  { return borderForType(clan.type.isNotEmpty ? clan.type : clan.groupName); }
    return (id % 2 != 0) ? pandiBorder : bandhuBorder;
  }

  // ── Lookups by type string ───────────────────────────────────────────────────

  /// Returns the background color for a group type string.
  static Color backgroundForType(String? type) {
    final t = (type ?? '').toUpperCase();
    if (t.contains('BANDHU') || t.contains('ബന്ധു')) return bandhuBackground;
    if (t.contains('PANDI') || t.contains('PANTHI') || t.contains('പന്തി'))
  { return pandiBackground; }
    return unknownBackground;
  }

  /// Returns the text color for a group type string.
  static Color textForType(String? type) {
    final t = (type ?? '').toUpperCase();
    if (t.contains('BANDHU') || t.contains('ബന്ധു')) return bandhuText;
    if (t.contains('PANDI') || t.contains('PANTHI') || t.contains('പന്തി'))
  { return pandiText; }
    return unknownText;
  }

  /// Returns the border color for a group type string.
  static Color borderForType(String? type) {
    final t = (type ?? '').toUpperCase();
    if (t.contains('BANDHU') || t.contains('ബന്ധു')) return bandhuBorder;
    if (t.contains('PANDI') || t.contains('PANTHI') || t.contains('പന്തി'))
  { return pandiBorder; }
    return unknownBorder;
  }
}

// ─── Reusable MoietyBadge widget ───────────────────────────────────────────────
/// A small colored chip showing the moiety group label.
/// Pass either [clanId] OR [groupType] — clanId takes priority.
class MoietyBadge extends StatelessWidget {
  final int? clanId;
  final String? groupType;
  final double fontSize;

  const MoietyBadge({
    super.key,
    this.clanId,
    this.groupType,
    this.fontSize = 11,
  }) : assert(
         clanId != null || groupType != null,
         'Provide at least one of clanId or groupType',
       );

  String _label() {
    if (clanId != null) {
      final clan = getClanById(clanId!);
      if (clan != null) {
        final t = clan.type.toUpperCase();
        if (t.contains('BANDHU') || clan.groupName.contains('ബന്ധു'))
  { return 'ബന്ധു'; }
        if (t.contains('PANDI') ||
            t.contains('PANTHI') ||
            clan.groupName.contains('പന്തി'))
  { return 'പന്തി'; }
      }
    }
    final t = (groupType ?? '').toUpperCase();
    if (t.contains('BANDHU') || t.contains('ബന്ധു')) return 'ബന്ധു';
    if (t.contains('PANDI') || t.contains('PANTHI') || t.contains('പന്തി'))
  { return 'പന്തി'; }
    return '?';
  }

  Color _bg() => clanId != null
      ? MoietyColors.backgroundForId(clanId!)
      : MoietyColors.backgroundForType(groupType);

  Color _text() => clanId != null
      ? MoietyColors.textForId(clanId!)
      : MoietyColors.textForType(groupType);

  Color _border() => clanId != null
      ? MoietyColors.borderForId(clanId!)
      : MoietyColors.borderForType(groupType);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg(),
        border: Border.all(color: _border(), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: _text(),
        ),
      ),
    );
  }
}

// തറവാടിന്റെ കാറ്റഗറി അനുസരിച്ച് കളർ നൽകുന്ന ലോജിക്
Color getMoietyBadgeColor(String moietyGroup) {
  if (moietyGroup == 'ബന്ധു' ||
      moietyGroup == 'Bandhu' ||
      moietyGroup.toLowerCase().contains('bandhu')) {
    return Colors.green; // ബന്ധുവിന് പച്ച
  } else if (moietyGroup == 'പന്തി' ||
      moietyGroup == 'Panthi' ||
      moietyGroup.toLowerCase().contains('pandi') ||
      moietyGroup.toLowerCase().contains('panthi')) {
    return Colors.red; // പന്തിക്ക് ചുവപ്പ്
  }
  return Colors.grey;
}
