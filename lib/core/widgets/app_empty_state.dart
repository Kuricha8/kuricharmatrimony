import 'package:flutter/material.dart';

/// Production-ready Empty State Widget with custom illustrations, titles, subtitles, and CTA buttons.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Widget? customIllustration;
  final EdgeInsetsGeometry padding;

  const AppEmptyState({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.description,
    this.buttonText,
    this.onButtonPressed,
    this.customIllustration,
    this.padding = const EdgeInsets.all(24.0),
  });

  /// Factory preset for "No Matches Found"
  factory AppEmptyState.noMatches({VoidCallback? onResetFilters}) {
    return AppEmptyState(
      icon: Icons.search_off_rounded,
      iconColor: const Color(0xFF8B0000),
      title: 'പ്രൊഫൈലുകൾ ഒന്നുമില്ല (No Matches Found)',
      description:
          'നിങ്ങൾ തിരഞ്ഞെടുത്ത ഫിൽട്ടറുകൾക്ക് അനുയോജ്യമായ പ്രൊഫൈലുകൾ ഇപ്പോൾ ലഭ്യമല്ല. ഫിൽട്ടറുകൾ ലളിതമാക്കൂ.',
      buttonText: 'ഫിൽട്ടർ മാറ്റുക (Reset Filters)',
      onButtonPressed: onResetFilters,
    );
  }

  /// Factory preset for "No Messages"
  factory AppEmptyState.noMessages({VoidCallback? onStartChat}) {
    return AppEmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      iconColor: const Color(0xFF000080),
      title: 'മെസ്സേജുകൾ ഒന്നുമില്ല (No Messages)',
      description:
          'ഇതുവരെ സംഭാഷണങ്ങൾ ഒന്നും ആരംഭിച്ചിട്ടില്ല. നിങ്ങളുടെ മാച്ചുകൾക്ക് ഇന്ററസ്റ്റ് അയച്ച് സംസാരിച്ചു തുടങ്ങൂ.',
      buttonText: 'മാച്ചുകൾ കാണുക (Explore Matches)',
      onButtonPressed: onStartChat,
    );
  }

  /// Factory preset for "No Pending Approvals" (Admin)
  factory AppEmptyState.noApprovals() {
    return const AppEmptyState(
      icon: Icons.verified_user_outlined,
      iconColor: Colors.green,
      title: 'എല്ലാ പ്രൊഫൈലുകളും പരിശോധിച്ചു!',
      description:
          'നിലവിൽ അപ്പ്രൂവലിനായി പുതിയ പ്രൊഫൈലുകളോ വിവരങ്ങളോ ബാക്കിയില്ല.',
    );
  }

  /// Factory preset for "No Profile Visitors"
  factory AppEmptyState.noVisitors() {
    return const AppEmptyState(
      icon: Icons.remove_red_eye_outlined,
      iconColor: Colors.purple,
      title: 'സന്ദർശകർ ആരുമില്ല (No Visitors)',
      description:
          'അടുത്തിടെ ആരും നിങ്ങളുടെ പ്രൊഫൈൽ നോക്കിയിട്ടില്ല. പ്രൊഫൈൽ ഫോട്ടോ അപ്‌ഡേറ്റ് ചെയ്ത് കൂടുതൽ ശ്രദ്ധ നേടൂ!',
    );
  }

  /// Factory preset for "No Network / Offline"
  factory AppEmptyState.noInternet({VoidCallback? onRetry}) {
    return AppEmptyState(
      icon: Icons.wifi_off_rounded,
      iconColor: Colors.orange.shade800,
      title: 'ഇന്റർനെറ്റ് കണക്ഷൻ ഇല്ല',
      description:
          'ദയവായി നിങ്ങളുടെ മൊബൈൽ ഡാറ്റ അല്ലെങ്കിൽ വൈഫൈ ചെക്ക് ചെയ്യൂ.',
      buttonText: 'വീണ്ടും ശ്രമിക്കുക (Retry)',
      onButtonPressed: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = iconColor ?? theme.primaryColor;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            customIllustration ??
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 64, color: primaryColor),
                ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  buttonText!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
