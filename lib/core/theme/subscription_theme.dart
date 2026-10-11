import 'package:flutter/material.dart';

enum MembershipLevel { free, gold, diamond }

class SubscriptionTheme {
  final MembershipLevel level;

  const SubscriptionTheme(this.level);

  /// Helper to map a string (e.g., from DB) to the enum.
  static MembershipLevel parse(String levelString) {
    switch (levelString.toLowerCase()) {
      case 'gold':
        return MembershipLevel.gold;
      case 'diamond':
        return MembershipLevel.diamond;
      default:
        return MembershipLevel.free;
    }
  }

  /// Returns the primary accent color for the tier.
  Color get accentColor {
    switch (level) {
      case MembershipLevel.gold:
        return const Color(0xFFFFD700); // Gold
      case MembershipLevel.diamond:
        return const Color(0xFF00FFFF); // Cyan/Diamond Blue
      case MembershipLevel.free:
        return Colors.transparent; // No specific accent
    }
  }

  /// Returns the background gradient for the user's header/card.
  LinearGradient? get backgroundGradient {
    switch (level) {
      case MembershipLevel.gold:
        return const LinearGradient(
          colors: [Color(0xFFFFF3CD), Color(0xFFFFE082)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case MembershipLevel.diamond:
        return const LinearGradient(
          colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case MembershipLevel.free:
        return null; // Flat standard white/grey
    }
  }

  /// Returns the custom badge icon if premium, null if free.
  Widget? get badgeIcon {
    switch (level) {
      case MembershipLevel.gold:
        return const Icon(Icons.star, color: Color(0xFFFFD700), size: 16);
      case MembershipLevel.diamond:
        return const Icon(Icons.diamond, color: Color(0xFF00FFFF), size: 16);
      case MembershipLevel.free:
        return null;
    }
  }

  /// Wraps a profile avatar with a premium border if applicable.
  Widget wrapAvatar(Widget avatar, {double radius = 30}) {
    if (level == MembershipLevel.free) {
      return avatar;
    }

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: level == MembershipLevel.gold
              ? [const Color(0xFFFFD700), const Color(0xFFFFA000)]
              : [const Color(0xFF00FFFF), const Color(0xFF00B0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: avatar,
    );
  }
}
