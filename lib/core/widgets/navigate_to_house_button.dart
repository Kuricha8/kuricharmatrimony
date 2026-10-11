import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/mock_data.dart';
import '../security/guest_security_service.dart';
import '../services/match_status_security_service.dart';

/// Conditional "Navigate to House (Google Maps)" Button Widget
///
/// Strict Privacy Rule:
/// - Checks matchStatus == 'mutual_accepted' AND both parties have approved the proposal in Firestore.
/// - For all other states (browsing, pending, guest): KEEPS THE BUTTON AND GPS COORDINATES COMPLETELY HIDDEN.
class NavigateToHouseButton extends StatefulWidget {
  final UserProfile profile;
  final bool? isMutualAcceptedOverride;
  final EdgeInsetsGeometry? margin;
  final bool fullWidth;

  const NavigateToHouseButton({
    super.key,
    required this.profile,
    this.isMutualAcceptedOverride,
    this.margin,
    this.fullWidth = true,
  });

  @override
  State<NavigateToHouseButton> createState() => _NavigateToHouseButtonState();
}

class _NavigateToHouseButtonState extends State<NavigateToHouseButton> {
  bool _isChecking = true;
  bool _canShow = false;
  ({double lat, double lng})? _coords;

  @override
  void initState() {
    super.initState();
    _evaluateVisibility();
  }

  @override
  void didUpdateWidget(covariant NavigateToHouseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.id != widget.profile.id ||
        oldWidget.isMutualAcceptedOverride != widget.isMutualAcceptedOverride) {
      _evaluateVisibility();
    }
  }

  Future<void> _evaluateVisibility() async {
    final me = MockData().currentUser;

    // 1. Strict Guest Check: Guest users can NEVER see the button or coordinates
    if (me == null ||
        GuestSecurityService.isGuest(me) ||
        widget.profile.id == 'guest' ||
        me.id == widget.profile.id) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _canShow = false;
          _coords = null;
        });
      }
      return;
    }

    // 2. Check Match Status (Firestore matchStatus == 'mutual_accepted' and approved)
    bool isMutual = widget.isMutualAcceptedOverride ?? false;

    if (!isMutual) {
      isMutual = await MatchStatusSecurityService.isMutualAcceptedWithApproval(
        currentUserId: me.id,
        targetProfileId: widget.profile.id,
        currentUser: me,
      );
    }

    if (!isMutual) {
      // KEEP BUTTON AND GPS COORDINATES COMPLETELY HIDDEN
      if (mounted) {
        setState(() {
          _isChecking = false;
          _canShow = false;
          _coords = null;
        });
      }
      return;
    }

    // 3. Resolve Coordinates only if strictly mutual accepted
    final coords = await MatchStatusSecurityService.getHouseCoordinates(
      profile: widget.profile,
    );

    if (coords == null) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _canShow = false;
          _coords = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isChecking = false;
        _canShow = true;
        _coords = coords;
      });
    }
  }

  void _onNavigate() async {
    if (_coords == null) return;

    final success = await MatchStatusSecurityService.launchNavigationToHouse(
      homeLat: _coords!.lat,
      homeLng: _coords!.lng,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ഗൂഗിൾ മാപ്പ് തുറക്കാൻ കഴിഞ്ഞില്ല. ദയവായി പിന്നീട് ശ്രമിക്കുക.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If still checking, guest, pending, or not mutual accepted -> COMPLETELY HIDDEN
    if (_isChecking || !_canShow || _coords == null) {
      return const SizedBox.shrink();
    }

    final buttonWidget = Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _onNavigate,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pin_drop,
                    color: Color(0xFFEA4335), // Google Maps Red Pin
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Flexible(
                  child: Text(
                    'വീട്ടിലേക്കുള്ള വഴി കാണുക (Google Maps)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return buttonWidget;
  }
}
