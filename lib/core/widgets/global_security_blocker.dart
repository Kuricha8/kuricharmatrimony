import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GlobalSecurityBlocker extends StatefulWidget {
  final Widget child;

  const GlobalSecurityBlocker({super.key, required this.child});

  @override
  State<GlobalSecurityBlocker> createState() => _GlobalSecurityBlockerState();
}

class _GlobalSecurityBlockerState extends State<GlobalSecurityBlocker> {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription;
  Timer? _pollTimer;

  bool _isBanned = false;
  bool _requiresLiveness = false;
  bool _isPendingLiveness = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _checkAndSubscribe();

    // Also listen to auth state changes in case user logs in/out
    _authSub = _supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        _checkAndSubscribe();
      }
    });
  }

  void _checkAndSubscribe() {
    _initiateFetchAndSubscribe();
  }

  Future<void> _initiateFetchAndSubscribe() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _cancelSubscription();
      _pollTimer?.cancel();
      _pollTimer = null;
      if (mounted) {
        setState(() {
          _isBanned = false;
          _requiresLiveness = false;
          _isPendingLiveness = false;
        });
      }
      return;
    }

    // 1. Force an immediate re-fetch of the user profile from Supabase upon initialization
    try {
      final profileRes = await _supabase
          .from('kurichiyar_profiles')
          .select(
            'is_banned, registration_status, status, force_video_verification, video_verification_status, role, is_liveness_verified, liveness_status',
          )
          .eq('id', user.id)
          .maybeSingle();

      if (profileRes != null && mounted) {
        final dbStatus = profileRes['status']?.toString().toUpperCase();
        final isBanned =
            (profileRes['is_banned'] == true ||
                profileRes['registration_status'] == 'banned') &&
            dbStatus != 'LIVE' &&
            dbStatus != 'APPROVED';

        final isAdmin =
            user.email?.toLowerCase() == 'kuricha8@gmail.com' ||
            profileRes['role'] == 'super_admin';
        final isApprovedUser =
            dbStatus == 'APPROVED' ||
            dbStatus == 'LIVE' ||
            profileRes['is_approved'] == true ||
            profileRes['is_liveness_verified'] == true ||
            profileRes['video_verification_status'] == 'approved';
        final requiresLiveness =
            !isAdmin &&
            !isApprovedUser &&
            profileRes['force_video_verification'] == true &&
            (profileRes['video_verification_status'] == null ||
                profileRes['video_verification_status'] == 'required' ||
                profileRes['video_verification_status'] == 'rejected');
        final isPendingLiveness =
            !isAdmin &&
            !isApprovedUser &&
            profileRes['force_video_verification'] == true &&
            profileRes['video_verification_status'] == 'pending';

        setState(() {
          _isBanned = isBanned;
          _requiresLiveness = requiresLiveness;
          _isPendingLiveness = isPendingLiveness;
        });
      }
    } on SocketException catch (netErr) {
      debugPrint('GlobalSecurityBlocker network unreachable: $netErr');
    } catch (e) {
      debugPrint('GlobalSecurityBlocker initial fetch error: $e');
    }

    // 2. Stream profile changes
    _profileSubscription?.cancel();
    _profileSubscription = _supabase
        .from('kurichiyar_profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .listen(
          (data) {
            if (data.isNotEmpty && mounted) {
              final profile = data.first;
              final dbStatus = profile['status']?.toString().toUpperCase();

              final isBanned =
                  (profile['is_banned'] == true ||
                      profile['registration_status'] == 'banned') &&
                  dbStatus != 'LIVE' &&
                  dbStatus != 'APPROVED';

              // Only force liveness if they aren't admin (so admins don't get locked out randomly)
              final isAdmin =
                  user.email?.toLowerCase() == 'kuricha8@gmail.com' ||
                  profile['role'] == 'super_admin';
              final isApprovedUser =
                  dbStatus == 'APPROVED' ||
                  dbStatus == 'LIVE' ||
                  profile['is_approved'] == true ||
                  profile['is_liveness_verified'] == true ||
                  profile['video_verification_status'] == 'approved';

              final requiresLiveness =
                  !isAdmin &&
                  !isApprovedUser &&
                  profile['force_video_verification'] == true &&
                  (profile['video_verification_status'] == null ||
                      profile['video_verification_status'] == 'required' ||
                      profile['video_verification_status'] == 'rejected');
              final isPendingLiveness =
                  !isAdmin &&
                  !isApprovedUser &&
                  profile['force_video_verification'] == true &&
                  profile['video_verification_status'] == 'pending';

              setState(() {
                _isBanned = isBanned;
                _requiresLiveness = requiresLiveness;
                _isPendingLiveness = isPendingLiveness;
              });
            }
          },
          onError: (err) {
            debugPrint('GlobalSecurityBlocker stream error: $err');
          },
        );

    // Start robust polling fallback
    _pollTimer?.cancel();
    int errorCount = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        timer.cancel();
        return;
      }
      try {
        final profileRes = await _supabase
            .from('kurichiyar_profiles')
            .select(
              'is_banned, registration_status, status, force_video_verification, video_verification_status, role, is_liveness_verified, liveness_status',
            )
            .eq('id', currentUser.id)
            .maybeSingle();

        if (profileRes != null && mounted) {
          final dbStatus = profileRes['status']?.toString().toUpperCase();
          final isBanned =
              (profileRes['is_banned'] == true ||
                  profileRes['registration_status'] == 'banned') &&
              dbStatus != 'LIVE' &&
              dbStatus != 'APPROVED';

          final isAdmin =
              currentUser.email?.toLowerCase() == 'kuricha8@gmail.com' ||
              profileRes['role'] == 'super_admin';
          final isApprovedUser =
              dbStatus == 'APPROVED' ||
              dbStatus == 'LIVE' ||
              profileRes['is_approved'] == true ||
              profileRes['is_liveness_verified'] == true ||
              profileRes['video_verification_status'] == 'approved';
          final requiresLiveness =
              !isAdmin &&
              !isApprovedUser &&
              profileRes['force_video_verification'] == true &&
              (profileRes['video_verification_status'] == null ||
                  profileRes['video_verification_status'] == 'required' ||
                  profileRes['video_verification_status'] == 'rejected');
          final isPendingLiveness =
              !isAdmin &&
              !isApprovedUser &&
              profileRes['force_video_verification'] == true &&
              profileRes['video_verification_status'] == 'pending';

          if (isBanned != _isBanned ||
              requiresLiveness != _requiresLiveness ||
              isPendingLiveness != _isPendingLiveness) {
            setState(() {
              _isBanned = isBanned;
              _requiresLiveness = requiresLiveness;
              _isPendingLiveness = isPendingLiveness;
            });
          }
          errorCount = 0; // Reset errors on success
        }
      } on SocketException catch (netErr) {
        debugPrint('GlobalSecurityBlocker network unreachable: $netErr');
      } catch (e) {
        debugPrint('GlobalSecurityBlocker poll error: $e');
        errorCount++;
        // If we hit consecutive errors while banned, force a session refresh to fetch new JWT claims
        if (errorCount % 6 == 0) {
          // Approx. every 30 seconds of errors
          try {
            debugPrint(
              'GlobalSecurityBlocker: Fetch failing. Force refreshing Supabase session...',
            );
            await _supabase.auth.refreshSession();
          } catch (refreshErr) {
            debugPrint('Failed to auto-refresh session: $refreshErr');
          }
        }
      }
    });
  }

  void _cancelSubscription() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _authSub?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscription();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Return main app tree directly without blocking normal app usage.
    // Admin will independently review videos from the admin panel.
    return widget.child;
  }
}
