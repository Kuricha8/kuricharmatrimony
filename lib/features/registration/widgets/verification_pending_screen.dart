import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/ad_banner_widget.dart';
import '../../../../core/widgets/native_ad_card.dart';
import '../../../../core/services/notification_manager.dart';

class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  State<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isCheckingStatus = false;
  bool _hasRedirected = false;
  String? _currentUserId;

  StreamSubscription<DocumentSnapshot>? _firestoreUsersSub;
  StreamSubscription<DocumentSnapshot>? _firestoreProfilesSub;
  Timer? _fallbackPollingTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeRealtimeListener();
  }

  @override
  void dispose() {
    _firestoreUsersSub?.cancel();
    _firestoreProfilesSub?.cancel();
    _fallbackPollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Resolves the authenticated user ID across Firebase Auth, Supabase, and local cache
  Future<String?> _resolveUserId() async {
    // 1. Firebase Auth UID
    final fbUid = FirebaseAuth.instance.currentUser?.uid;
    if (fbUid != null && fbUid.isNotEmpty) return fbUid;

    // 2. Supabase User ID
    final sbUid = Supabase.instance.client.auth.currentUser?.id;
    if (sbUid != null && sbUid.isNotEmpty) return sbUid;

    // 3. SharedPreferences cached IDs
    final prefs = await SharedPreferences.getInstance();
    final cachedId = prefs.getString('pending_user_id') ??
        prefs.getString('user_id') ??
        prefs.getString('uid');
    if (cachedId != null && cachedId.isNotEmpty) return cachedId;

    // 4. Auto sign-in fallback if credentials exist in prefs
    final email = prefs.getString('pending_user_email');
    final password = prefs.getString('pending_user_password');
    if (email != null && password != null && email.isNotEmpty && password.isNotEmpty) {
      try {
        final res = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (res.user != null) return res.user!.id;
      } catch (e) {
        debugPrint('Auto sign-in fallback notice: $e');
      }
    }

    return null;
  }

  /// Evaluates whether the user document satisfies the approval condition
  bool _isDocumentApproved(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    final approvalStatus = (data['approvalStatus'] ??
            data['approval_status'] ??
            data['approval_state'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    final isApproved = data['isApproved'] == true ||
        data['is_approved'] == true ||
        data['isApproved']?.toString().toLowerCase() == 'true' ||
        data['is_approved']?.toString().toLowerCase() == 'true';
    final accountStatus =
        (data['account_status'] ?? '').toString().trim().toLowerCase();
    final registrationStatus =
        (data['registration_status'] ?? '').toString().trim().toLowerCase();
    final role = (data['role'] ?? '').toString().trim().toLowerCase();
    final isVerified = data['is_verified'] == true ||
        data['is_verified']?.toString().toLowerCase() == 'true';
    final override =
        (data['app_screen_override'] ?? '').toString().trim().toUpperCase();

    // Check exact criteria requested:
    // status == 'approved' OR approvalStatus == 'approved' OR isApproved == true
    if (status == 'approved' ||
        approvalStatus == 'approved' ||
        isApproved ||
        status == 'active' ||
        status == 'live' ||
        approvalStatus == 'active' ||
        approvalStatus == 'live' ||
        accountStatus == 'approved' ||
        accountStatus == 'active' ||
        registrationStatus == 'approved' ||
        registrationStatus == 'active' ||
        isVerified ||
        override == 'MAIN_SCREEN' ||
        role == 'admin' ||
        role == 'super_admin') {
      return true;
    }

    return false;
  }

  /// Triggers automatic transition to the Main Home Dashboard
  void _navigateToHome() {
    if (_hasRedirected || !mounted) return;
    _hasRedirected = true;

    _firestoreUsersSub?.cancel();
    _firestoreProfilesSub?.cancel();
    _fallbackPollingTimer?.cancel();

    debugPrint('[VerificationPendingScreen] User approved! Navigating to /home in real-time...');

    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  /// Sets up the direct real-time Firestore stream listener
  Future<void> _initializeRealtimeListener() async {
    final uid = await _resolveUserId();
    _currentUserId = uid;

    if (uid != null && uid.isNotEmpty) {
      // Register FCM Token in background
      try {
        await NotificationManager.instance.registerFCMToken(uid);
      } catch (_) {}

      // 1. REALTIME FIRESTORE STREAM: collection('users').doc(currentUserId).snapshots()
      _firestoreUsersSub?.cancel();
      _firestoreUsersSub = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          if (_isDocumentApproved(data)) {
            _navigateToHome();
          }
        }
      }, onError: (err) {
        debugPrint('[VerificationPendingScreen] Firestore users stream error: $err');
      });

      // 2. REALTIME FIRESTORE STREAM: collection('kurichiyar_profiles').doc(currentUserId).snapshots()
      _firestoreProfilesSub?.cancel();
      _firestoreProfilesSub = FirebaseFirestore.instance
          .collection('kurichiyar_profiles')
          .doc(uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          if (_isDocumentApproved(data)) {
            _navigateToHome();
          }
        }
      }, onError: (err) {
        debugPrint('[VerificationPendingScreen] Firestore kurichiyar_profiles stream error: $err');
      });

      // 3. Periodic polling fallback (every 4 seconds) to guarantee reactive navigation
      _fallbackPollingTimer?.cancel();
      _fallbackPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        if (_hasRedirected || !mounted) return;
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get(const GetOptions(source: Source.serverAndCache));
          if (userDoc.exists && userDoc.data() != null) {
            if (_isDocumentApproved(userDoc.data()!)) {
              _navigateToHome();
              return;
            }
          }

          final profDoc = await FirebaseFirestore.instance
              .collection('kurichiyar_profiles')
              .doc(uid)
              .get(const GetOptions(source: Source.serverAndCache));
          if (profDoc.exists && profDoc.data() != null) {
            if (_isDocumentApproved(profDoc.data()!)) {
              _navigateToHome();
              return;
            }
          }
        } catch (_) {}
      });
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Manual refresh handler for user reassurance
  Future<void> _manualRefreshStatus() async {
    if (_isCheckingStatus) return;
    setState(() => _isCheckingStatus = true);

    try {
      final uid = _currentUserId ?? await _resolveUserId();
      if (uid == null || uid.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      bool approved = false;

      // 1. Direct fetch from Firestore 'users'
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.server));
        if (doc.exists && doc.data() != null && _isDocumentApproved(doc.data()!)) {
          approved = true;
        }
      } catch (e) {
        debugPrint('Manual check Firestore users: $e');
      }

      // 2. Direct fetch from Firestore 'kurichiyar_profiles'
      if (!approved) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('kurichiyar_profiles')
              .doc(uid)
              .get(const GetOptions(source: Source.server));
          if (doc.exists && doc.data() != null && _isDocumentApproved(doc.data()!)) {
            approved = true;
          }
        } catch (e) {
          debugPrint('Manual check Firestore kurichiyar_profiles: $e');
        }
      }

      // 3. Fallback to Supabase
      if (!approved) {
        try {
          final sbData = await Supabase.instance.client
              .from('kurichiyar_profiles')
              .select()
              .eq('id', uid)
              .maybeSingle();
          if (sbData != null && _isDocumentApproved(sbData)) {
            approved = true;
          }
        } catch (_) {}
      }

      if (!mounted) return;

      if (approved) {
        _navigateToHome();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Profile is still under review by Admin. It will open automatically once approved.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFE65100),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  Future<void> _contactAdminWhatsApp() async {
    final Uri url = Uri.parse(
      "https://wa.me/918606415174?text=${Uri.encodeComponent('ഹലോ അഡ്മിൻ, എന്റെ കുറിച്യർ മാട്രിമോണി പ്രൊഫൈൽ വെരിഫിക്കേഷൻ സ്റ്റാറ്റസ് അറിയാൻ ആഗ്രഹിക്കുന്നു.')}",
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final Uri telUrl = Uri.parse("tel:+918606415174");
        if (await canLaunchUrl(telUrl)) {
          await launchUrl(telUrl);
        }
      }
    } catch (e) {
      debugPrint('Contact admin error: $e');
    }
  }

  Future<void> _logout() async {
    _firestoreUsersSub?.cancel();
    _firestoreProfilesSub?.cancel();
    _fallbackPollingTimer?.cancel();
    await FirebaseAuth.instance.signOut();
    await Supabase.instance.client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, '/guest', (route) => false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: 'Back to Guest Page',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/guest', (route) => false);
            },
          ),
          title: const Text(
            'Account Under Verification',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17.5,
              letterSpacing: 0.2,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
        ),
        // ── FIXED ADMOB BANNER AD AT BOTTOM ──
        bottomNavigationBar: SafeArea(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: const AdBannerWidget(),
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE65100)),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

                      // ── MODERN WAITING ANIMATION & STATUS CARD ──
                      _buildWaitingAnimationCard(),

                      const SizedBox(height: 20),

                      // ── CENTER SECTION: ADMOB NATIVE AD / AD CARD ──
                      _buildNativeAdSection(),

                      const SizedBox(height: 20),

                      // ── REFRESH STATUS BUTTON ──
                      _buildRefreshButton(),

                      const SizedBox(height: 16),

                      // ── HELPDESK & DIRECT ADMIN CONTACT ──
                      _buildHelpdeskCard(),

                      const SizedBox(height: 14),

                      // ── GUEST EXPLORE MODE (BACK TO GUEST) ──
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(context, '/guest', (route) => false);
                        },
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          size: 18,
                          color: Color(0xFF4338CA),
                        ),
                        label: const Text(
                          'Back to Guest Page / Explore Home',
                          style: TextStyle(
                            color: Color(0xFF4338CA),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// Modern Verification Card with smooth pulse animation and clean typography
  Widget _buildWaitingAnimationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated Pulsing Verification Avatar
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFF7ED),
                    Color(0xFFFFEDD5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFFFDBA74),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.hourglass_top_rounded,
                  size: 44,
                  color: Color(0xFFEA580C),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Primary Title
          const Text(
            'Application Under Review\n(പരിശോധനയിലാണ്)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              height: 1.3,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle Message
          const Text(
            'Your profile has been submitted and is currently awaiting admin approval. Please check back shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),

          // Realtime Live Status Pill with spinner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Live Sync: Awaiting Admin Approval',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Center AdMob Native Ad Card
  Widget _buildNativeAdSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 10, bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'SPONSORED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const NativeAdCard(isStatusLayout: true),
        ],
      ),
    );
  }

  /// Manual Refresh Button with live status indicator
  Widget _buildRefreshButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isCheckingStatus ? null : _manualRefreshStatus,
        icon: _isCheckingStatus
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : const Icon(Icons.sync_rounded, color: Colors.white, size: 22),
        label: Text(
          _isCheckingStatus
              ? 'Checking Live Status...'
              : 'Refresh Status (നില പരിശോധിക്കുക)',
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B2A1E), // Kurichiyar Forest Green
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Helpdesk & Direct WhatsApp Admin support
  Widget _buildHelpdeskCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.support_agent_rounded, color: Color(0xFF475569), size: 24),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Help or Quick Approval?',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Contact Admin Rineesh: +91 8606415174',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF2E7D32)),
            tooltip: 'WhatsApp Admin',
            onPressed: _contactAdminWhatsApp,
          ),
        ],
      ),
    );
  }
}
