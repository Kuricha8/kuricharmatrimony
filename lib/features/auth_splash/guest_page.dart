import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../moiety_checker/checker_screen.dart';
import '../../core/services/in_app_update_service.dart';
import '../../core/services/registration_route_helper.dart';
import 'widgets/guest_public_hub_tab.dart';
import 'widgets/guest_direct_ads_tab.dart';
import 'widgets/guest_auth_bottom_sheet.dart';
import '../../core/widgets/notification_bell_icon.dart';
import '../settings/guest_settings_screen.dart';
import '../../core/services/biometric_auth_service.dart';

export 'widgets/guest_auth_bottom_sheet.dart';
export 'widgets/guest_public_hub_tab.dart';
export 'widgets/guest_direct_ads_tab.dart';

class GuestScreen extends StatefulWidget {
  final bool isForced;
  final bool isMalayalam;

  const GuestScreen({
    super.key,
    this.isForced = false,
    this.isMalayalam = false,
  });

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  int _selectedIndex = 0;
  bool _isMaintenance = false;
  bool _isPendingApproval = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _checkMaintenance();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        InAppUpdateService.instance.checkForUpdates(context);
      }
    });

    final session = Supabase.instance.client.auth.currentSession;
    _checkPendingStatus(session?.user.id);

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (mounted) {
        _checkPendingStatus(session?.user.id);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _checkPendingStatus(String? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localSubmitted = prefs.getBool('registration_submitted') ?? false;

      if (userId != null && userId.isNotEmpty) {
        final res = await Supabase.instance.client
            .from('kurichiyar_profiles')
            .select('status, approval_status')
            .eq('id', userId)
            .maybeSingle();
        if (res != null) {
          final status = res['status']?.toString().toLowerCase() ?? 'pending';
          final approvalStatus =
              res['approval_status']?.toString().toLowerCase() ?? 'pending';
          debugPrint(
            'GUEST SCREEN PENDING CHECK: status=$status, approvalStatus=$approvalStatus',
          );
          if (mounted) {
            setState(() {
              _isPendingApproval =
                  localSubmitted ||
                  (status == 'pending' || approvalStatus == 'pending');
            });
          }
          return;
        }
      }
      if (mounted) {
        setState(() {
          _isPendingApproval = localSubmitted;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkMaintenance() async {
    try {
      final res = await Supabase.instance.client
          .from('app_config')
          .select('config_value')
          .eq('config_key', 'maintenance_mode')
          .maybeSingle();
      if (res != null && res['config_value'] == 'true') {
        final session = Supabase.instance.client.auth.currentSession;
        bool isAdmin = false;
        if (session != null) {
          final email = session.user.email?.toLowerCase();
          if (email == 'kuricha8@gmail.com') {
            isAdmin = true;
          } else {
            final adminRecord = await Supabase.instance.client
                .from('admin_users')
                .select()
                .eq('id', session.user.id)
                .maybeSingle();
            if (adminRecord != null) isAdmin = true;
          }
        }

        if (!isAdmin && mounted) {
          setState(() {
            _isMaintenance = true;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _showRegistrationBottomSheet() async {
    final isRegistered = await RegistrationRouteHelper.isUserRegisteredOrPending();
    if (!mounted) return;

    if (isRegistered) {
      Navigator.pushNamed(context, '/verification_pending');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          const GuestAuthBottomSheet(isSignUpMode: true, isMalayalam: true),
    );
  }

  Future<void> _openGuestSettings(BuildContext context) async {
    final isLockEnabled = await BiometricAuthService.instance.isAppLockEnabled();
    if (isLockEnabled) {
      final authenticated = await BiometricAuthService.instance.authenticate(
        localizedReason: 'തുടരാൻ ഫോൺ ലോക്ക് അല്ലെങ്കിൽ വിരലടയാളം ഉപയോഗിക്കുക',
      );
      if (!authenticated) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ആധികാരികത ഉറപ്പാക്കൽ പരാജയപ്പെട്ടു (Authentication failed).'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const GuestSettingsScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isMaintenance) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          color: const Color(0xFF000080),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.build_circle_outlined,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 24),
              const Text(
                'അറ്റകുറ്റപ്പണി നടക്കുന്നു (Under Maintenance)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'സിസ്റ്റം മെച്ചപ്പെടുത്തുന്നതിനായി ആപ്പ് താത്കാലികമായി നിർത്തിവെച്ചിരിക്കുന്നു. ദയവായി കുറച്ചു സമയം കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കുക.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _checkMaintenance(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                child: const Text('വീണ്ടും ശ്രമിക്കുക (Refresh)'),
              ),
            ],
          ),
        ),
      );
    }

    final pages = [
      GuestPublicHubFeedTab(
        onNavigateToChecker: () => setState(() => _selectedIndex = 1),
        isPendingApproval: _isPendingApproval,
      ),
      const MoietyCheckerScreen(isGuest: true),
      const GuestDirectAdsTab(),
    ];

    final titles = [
      'പൊതു ഹബ്ബ് (Public Hub Feed)',
      'തറവാട് പൊരുത്തം (Moiety Checker)',
      'പരസ്യങ്ങൾ & ഓഫറുകൾ (Direct Ads)',
    ];

    DateTime? lastBackPressTime;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return;
        }

        final now = DateTime.now();
        if (lastBackPressTime == null ||
            now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
          lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit Kurichiyar Matrimony'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF000080),
            ),
          );
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              titles[_selectedIndex],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          backgroundColor: const Color(0xFF000080),
          elevation: 2,
          actions: [
            const NotificationBellIcon(),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              tooltip: 'ക്രമീകരണങ്ങൾ (Settings)',
              onPressed: () => _openGuestSettings(context),
            ),
            IconButton(
              icon: const Icon(Icons.person_add_alt_1, color: Colors.amber),
              tooltip: 'Register',
              onPressed: _showRegistrationBottomSheet,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: IndexedStack(index: _selectedIndex, children: pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: const Color(0xFF000080),
          unselectedItemColor: const Color(0xFF718096),
          type: BottomNavigationBarType.fixed,
          iconSize: 22,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: -0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 10,
            letterSpacing: -0.2,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.hub_outlined),
              activeIcon: Icon(Icons.hub),
              label: 'Public Hub',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Checker',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign),
              label: 'Direct Ads',
            ),
          ],
        ),
      ),
    );
  }
}

class GuestClanFeedPreviewTab extends StatelessWidget {
  const GuestClanFeedPreviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const GuestPublicHubFeedTab();
  }
}

class GuestPreviewFeedTab extends StatelessWidget {
  const GuestPreviewFeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const GuestPublicHubFeedTab();
  }
}
