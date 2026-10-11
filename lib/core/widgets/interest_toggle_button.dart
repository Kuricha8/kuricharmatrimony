import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'unified_interest_button.dart';

export 'unified_interest_button.dart';

class InterestToggleButton extends StatelessWidget {
  final UserProfile targetProfile;
  final VoidCallback? onStateChanged;
  final bool fullWidth;

  const InterestToggleButton({
    super.key,
    required this.targetProfile,
    this.onStateChanged,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedInterestButton(
      targetProfile: targetProfile,
      fullWidth: fullWidth,
      onStateChanged: (_) => onStateChanged?.call(),
    );
  }
}
