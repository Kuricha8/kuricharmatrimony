import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../utils/mock_data.dart';

/// Centralized service handling Guest security, photo protection, blurring filters,
/// and guest authentication gating across the application.
class GuestSecurityService {
  /// Identifies whether the given [viewer] (or currently logged in user) is a Guest.
  /// Unauthenticated or anonymous sessions are strictly treated as Guests.
  static bool isGuest([UserProfile? viewer]) {
    // 1. Explicit viewer check if passed
    if (viewer != null) {
      if (viewer.role.toLowerCase() == 'guest' || viewer.id == 'guest') {
        return true;
      }
    }

    // 2. Check MockData currentUser
    final current = MockData().currentUser;
    if (current == null ||
        current.role.toLowerCase() == 'guest' ||
        current.id == 'guest') {
      return true;
    }

    // 3. Check Supabase auth session
    try {
      final supaUser = Supabase.instance.client.auth.currentUser;
      if (supaUser == null || supaUser.isAnonymous) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Displays the interactive modal informing the guest to login or register
  /// to view clear photos and full profile information.
  static void showGuestPhotoAccessModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull bar indicator
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 22),

              // Shield / Lock Icon Badge
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 44,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              const Text(
                'ഫോട്ടോകൾ സംരക്ഷിച്ചിരിക്കുന്നു',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Required Malayalam Prompt Message
              const Text(
                'ഫോട്ടോകൾ വ്യക്തമായി കാണാനും കൂടുതൽ വിവരങ്ങൾ അറിയാനും ദയവായി രജിസ്റ്റർ ചെയ്യുക അല്ലെങ്കിൽ ലോഗിൻ ചെയ്യുക.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF475569),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                'Please sign in or register to view clear, high-resolution candidate photos.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),

              // Action Button: Login / Register
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000080),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text(
                    'ലോഗിൻ / രജിസ്റ്റർ ചെയ്യുക (Login / Register)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushNamed('/login');
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Dismiss Button
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'പിന്നീട് ആകാം (Cancel)',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Displays the interactive modal when a guest taps a profile card to view full details.
  /// Prompt: "തറവാട് വിവരങ്ങൾ, ജോലി, മറ്റ് വിശദാംശങ്ങൾ എന്നിവ അറിയാൻ ദയവായി രജിസ്റ്റർ ചെയ്യുക അല്ലെങ്കിൽ ലോഗിൻ ചെയ്യുക."
  /// with a "Register / Login" button.
  static void showGuestProfileAccessModal(
    BuildContext context, {
    VoidCallback? onRegisterLogin,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull bar indicator
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 22),

              // Lock Badge
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                ),
                child: const Icon(
                  Icons.lock_person_outlined,
                  size: 44,
                  color: Color(0xFF1E40AF),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              const Text(
                'പൂർണ്ണ വിവരങ്ങൾ കാണാൻ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Required Malayalam Prompt Message
              const Text(
                'തറവാട് വിവരങ്ങൾ, ജോലി, മറ്റ് വിശദാംശങ്ങൾ എന്നിവ അറിയാൻ ദയവായി രജിസ്റ്റർ ചെയ്യുക അല്ലെങ്കിൽ ലോഗിൻ ചെയ്യുക.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF334155),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),

              // Action Button: Register / Login
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000080),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text(
                    'രജിസ്റ്റർ / ലോഗിൻ ചെയ്യുക (Register / Login)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (onRegisterLogin != null) {
                      onRegisterLogin();
                    } else {
                      Navigator.of(context).pushNamed('/login');
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Dismiss Button
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'പിന്നീട് ആകാം (Cancel)',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// A wrapper widget that enforces blur filter (sigma 8-10) and blocks full-screen
/// expansion, saving, and contextual long-press menus when viewed by guests.
class GuestProtectedPhotoWidget extends StatelessWidget {
  final Widget child;
  final bool isGuest;
  final double blurSigma;
  final VoidCallback? onAuthenticatedTap;
  final BorderRadius? borderRadius;

  const GuestProtectedPhotoWidget({
    super.key,
    required this.child,
    required this.isGuest,
    this.blurSigma = 9.0,
    this.onAuthenticatedTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (!isGuest) {
      if (onAuthenticatedTap != null) {
        return GestureDetector(
          onTap: onAuthenticatedTap,
          child: child,
        );
      }
      return child;
    }

    final radius = borderRadius ?? BorderRadius.zero;

    return ClipRRect(
      borderRadius: radius,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // When a guest taps on any photo, prevent full-screen expansion and show modal
        onTap: () => GuestSecurityService.showGuestPhotoAccessModal(context),
        // Disable contextual menus, saving, or long-press gestures on all photo widgets for guests
        onLongPress: () => GuestSecurityService.showGuestPhotoAccessModal(context),
        onSecondaryTap: () => GuestSecurityService.showGuestPhotoAccessModal(context),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            // Image blur filter (sigma 8-10)
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: blurSigma,
                sigmaY: blurSigma,
              ),
              child: child,
            ),
            // Privacy lock overlay for guest indication
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.16),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.68),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'രജിസ്റ്റർ ചെയ്യുക',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
