import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/admin_config.dart';
import 'banned_screen.dart';
import 'maintenance_screen.dart';
import '../services/security_service.dart';
import '../../features/auth_splash/terms_and_conditions_page.dart';
import '../models/models.dart';
import '../utils/mock_data.dart';
import '../../features/registration/widgets/verification_pending_screen.dart';
import '../../features/registration/widgets/account_rejected_screen.dart';
import '../services/biometric_auth_service.dart';
import '../../features/security/app_lock_screen.dart';
import '../../features/auth_splash/guest_page.dart';
import '../../features/registration/registration_wizard.dart';
import '../../features/registration/profile_completion_screen.dart';
import '../../features/agent_dashboard/agent_dashboard_shell.dart';
import '../../features/agent_dashboard/agent_waiting_screen.dart';

class AuthWrapper extends StatefulWidget {
  final Widget? child;
  const AuthWrapper({super.key, this.child});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _hasRouted = false;
  bool _termsAgreedOverride = false;
  bool _appLockUnlocked = false;

  Future<Map<String, dynamic>> _fetchAuthData(User? user) async {
    final results = await Future.wait<dynamic>([
      // Maintenance check [0]
      _supabase.from('app_config').select('config_value').eq('config_key', 'maintenance_mode').maybeSingle(),
      // Terms check [1]
      SharedPreferences.getInstance(),
      // Announcement check [2]
      _supabase.from('announcements').select().eq('target_type', 'all').order('created_at', ascending: false).limit(1).maybeSingle(),
      // Security check [3]
      SecurityService.verifyAppIntegrity(context),
      // Ad status check [4]
      MockData().syncAdStatus(),
      // App Lock check [5]
      BiometricAuthService.instance.isAppLockEnabled(),
    ]);

    final configRes = results[0] as Map<String, dynamic>?;
    final prefs = results[1] as SharedPreferences;
    final announcementRes = results[2] as Map<String, dynamic>?;
    final hasPin = results[5] as bool;

    Map<String, dynamic>? profile;
    Map<String, dynamic>? agentProfile;
    bool isAdmin = false;

    if (user != null) {
      agentProfile = await _supabase.from('agents').select().eq('id', user.id).maybeSingle();
      
      profile = await _supabase
          .from('kurichiyar_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
          
      // Check Firestore user record for isAdmin / role
      Map<String, dynamic>? firestoreUserData;
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.id).get();
        if (doc.exists) {
          firestoreUserData = doc.data();
        }
      } catch (e) {
        debugPrint('[AuthWrapper] Firestore check: $e');
      }

      final String? profilePhone = profile?['phone'] ?? profile?['guardian_phone'] ?? profile?['public_display_number'];
      final String? firestorePhone = firestoreUserData?['phone'] ?? firestoreUserData?['guardian_phone'];
      final String? role = (profile?['role'] ?? firestoreUserData?['role'])?.toString().toLowerCase().trim();

      final bool isSuperAdminByPhone = AdminConfig.isSuperAdmin(
        phone: user.phone ?? profilePhone ?? firestorePhone,
        email: user.email,
      );

      isAdmin = isSuperAdminByPhone ||
          role == 'admin' ||
          role == 'super_admin' ||
          firestoreUserData?['isAdmin'] == true;

      if (isSuperAdminByPhone || isAdmin) {
        isAdmin = true;
        // Automatically sync admin role to Firestore and Supabase
        unawaited(AdminConfig.ensureAdminRecord(
          user.id,
          phone: profilePhone ?? firestorePhone ?? user.phone,
          email: user.email,
        ));
      }
    }

    return {
      'isMaintenance': configRes != null && configRes['config_value'] == 'true',
      'hasAgreedTerms': _termsAgreedOverride || (prefs.getBool('hasAgreedTerms') ?? false),
      'hasPin': hasPin,
      'announcementRes': announcementRes,
      'agentProfile': agentProfile,
      'profile': profile,
      'isAdmin': isAdmin,
    };
  }

  void _routeOnce(String routeName, {Object? arguments, Widget? page}) {
    if (_hasRouted) return;
    _hasRouted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (page != null) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
      } else {
        Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments);
      }
    });
  }

  void _handleUnauthenticated() async {
    MockData().logout();
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  String? _lastUserId;
  Future<Map<String, dynamic>>? _authDataFuture;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _supabase.auth.onAuthStateChange,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF000080))));
        }

        final user = authSnapshot.data?.session?.user;
        if (_authDataFuture == null || _lastUserId != user?.id) {
          _lastUserId = user?.id;
          _authDataFuture = _fetchAuthData(user);
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: _authDataFuture,
          builder: (context, dataSnapshot) {
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF000080))));
            }

            if (dataSnapshot.hasError) {
              if (dataSnapshot.error is TimeoutException) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connection timeout. Please check your network.'), backgroundColor: Colors.red),
                  );
                });
                _routeOnce('/guest');
              } else {
                _handleUnauthenticated();
              }
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.red)));
            }

            final data = dataSnapshot.data!;
            final isMaintenance = data['isMaintenance'] as bool;
            final hasAgreedTerms = data['hasAgreedTerms'] as bool;
            final hasPin = data['hasPin'] as bool;
            final isAdmin = data['isAdmin'] as bool;
            final agentProfile = data['agentProfile'] as Map<String, dynamic>?;
            final profile = data['profile'] as Map<String, dynamic>?;

            // 1. Maintenance Mode
            if (isMaintenance && !isAdmin) {
              return const MaintenanceScreen();
            }

            // 2. Terms
            if (!hasAgreedTerms && !_termsAgreedOverride) {
              return TermsAndConditionsPage(
                onAgreed: () async {
                  debugPrint('[AuthWrapper] Terms onAgreed callback received.');
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('hasAgreedTerms', true);
                  if (mounted) {
                    setState(() {
                      _termsAgreedOverride = true;
                      _authDataFuture = null; // Re-fetch clean auth data
                    });
                  }
                },
              );
            }

            // 3. Biometric / Screen Lock on Cold Start
            if (hasPin && !_appLockUnlocked) {
              return AppLockScreen(
                isSetupMode: false,
                onSuccess: () {
                  if (mounted) {
                    setState(() {
                      _appLockUnlocked = true;
                    });
                  }
                },
              );
            }

            // 4. User Route Logic
            if (user == null) {
              if (!isAdmin) {
                return GuestScreen();
              } else {
                if (widget.child != null) return widget.child!;
                return GuestScreen();
              }
            }

            // Super Admin / Admin Role Routing:
            // Bypass pending agent screens and application pending screens,
            // and redirect directly to Admin Dashboard / Controls!
            if (isAdmin) {
              if (profile != null) {
                final userProfile = UserProfile.fromMap(profile);
                MockData().registerUser(userProfile);
              }
              return const AgentDashboardShell();
            }

            if (agentProfile != null) {
              final status = agentProfile['approval_status'] ?? 'PENDING';
              return status == 'APPROVED' ? const AgentDashboardShell() : const AgentWaitingScreen();
            }

            if (profile != null) {
              if (profile['is_banned'] == true) {
                return const BannedScreen();
              }

              final userProfile = UserProfile.fromMap(profile);
              MockData().registerUser(userProfile);

              final isApprovedNow = profile['role']?.toString().toUpperCase() == 'USER' || profile['photo_approved'] == true;
              if (isApprovedNow) {
                if (widget.child != null) return widget.child!;
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              final approvalStatus = profile['approval_status'] ?? 'PENDING';
              if (approvalStatus == 'PENDING' || userProfile.registrationStatus == 'pending') {
                return const VerificationPendingScreen();
              } else if (approvalStatus == 'REJECTED') {
                return const AccountRejectedScreen();
              }

              final isAlreadyRegistered = userProfile.registrationStatus == 'live' || (userProfile.name.isNotEmpty && userProfile.name != 'Anonymous');
              if (!isAlreadyRegistered) {
                return const RegistrationWizard();
              }

              final isIncomplete = profile['status'] == 'incomplete' || profile['height_cm'] == null || profile['father_clan_id'] == null;
              if (isIncomplete) {
                return ProfileCompletionScreen(initialData: profile);
              }
            } else {
              return GuestScreen();
            }

            if (widget.child != null) return widget.child!;
            
            // Fallback
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          },
        );
      },
    );
  }
}
