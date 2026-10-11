import 'package:flutter/services.dart';

/// Centralized Haptic Feedback and Micro-Animation Helper.
class HapticHelper {
  /// Light haptic feedback for simple tap events and tab changes
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium haptic feedback for action buttons (e.g. Save, Favorite, Filter)
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy haptic feedback for major actions (e.g. Payment trigger, Delete profile)
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection feedback for picker scrolling or slider movement
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Triggered on successful actions (Match unlock, Interest sent)
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Triggered on error or validation failure
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }

  /// Triggered when contact numbers are unlocked (e.g. ₹49 payment success)
  static Future<void> contactUnlocked() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.mediumImpact();
  }

  /// Triggered on sending an interest request
  static Future<void> interestSent() async {
    await HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.lightImpact();
  }
}
