import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/utils/mock_data.dart';
import '../clan_feed/tharavadu_list.dart';
import 'home_tab.dart';
import '../chat/chat_tab.dart';
import 'profile_tab.dart';
import '../moiety_checker/checker_screen.dart';
import '../clan_feed/clan_feed_tab.dart';
import '../calls/incoming_call_dialog.dart';

import '../dashboard/edit_profile_sheet.dart';
import '../../core/widgets/notification_bell_icon.dart';
import '../registration/force_photo_upload_screen.dart';
import '../public/full_screen_ad_view.dart';
import '../subscriptions/subscription_page.dart';
import '../notifications/notification_center_screen.dart';
import '../../core/models/models.dart';
import '../../core/services/notification_manager.dart';
import '../support/user_support_chat_screen.dart';
import '../../core/services/notifications_unread_service.dart';
import '../../core/services/support_unread_service.dart';
import '../settings/settings_page.dart';
import '../../core/services/biometric_auth_service.dart';

import '../../core/widgets/birthday_overlay.dart';
import '../cart/my_cart_page.dart';
import '../visitors/profile_visitors_page.dart';
import '../../core/widgets/ad_banner_widget.dart';
import '../../core/widgets/coin_flip_logo.dart';
import '../../core/services/in_app_update_service.dart';
import 'package:kurichiyar_matrimony/l10n/app_localizations.dart';
import '../matching/matches_page.dart';
import '../../core/services/predictive_cache_service.dart';
import '../family_tree/family_tree.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});
  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 1;
  RealtimeChannel? _matchChannel;
  RealtimeChannel? _callListenerChannel;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkBirthday();
      _initMatchListener();
      _initIncomingCallListener();
      InAppUpdateService.instance.checkForUpdates(context);
      PredictiveCacheService.instance.prewarmApp(context);
      // Init support unread badge
      final me = MockData().currentUser;
      if (me != null) {
        final hasPhoto =
            me.photoUrl.isNotEmpty &&
            me.photoUrl != 'assets/images/default_avatar.png';
        if (!hasPhoto &&
            me.role != 'admin' &&
            me.role != 'super_admin' &&
            me.role != 'guest') {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => ForcePhotoUploadScreen(profile: me),
              ),
              (route) => false,
            );
          }
          return;
        }
        SupportUnreadService.instance.init(me.id);
        NotificationsUnreadService.instance.init(me.id);
        // FORCE FCM TOKEN SAVE
        debugPrint('critical_log: FORCING FCM TOKEN SAVE ON APP LOAD...');
        await NotificationManager.instance.registerFCMToken(me.id);
      }

      // AUTOMATIC REAL FCM TOKEN FETCH WITH EXACT DIAGNOSTICS LOGGING
      try {
        debugPrint('--- initiating real fcm token fetch ---');
        debugPrint('Firebase Apps Count: ${Firebase.apps.length}');

        NotificationSettings settings = await FirebaseMessaging.instance
            .requestPermission(alert: true, badge: true, sound: true);
        debugPrint('fcm Authorization Status: ${settings.authorizationStatus}');

        if (Platform.isIOS) {
          try {
            final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
            debugPrint('fcm APNS Status: $apnsToken');
          } catch (_) {}
        }

        String? rawToken;
        for (int retry = 0; retry < 3; retry++) {
          try {
            rawToken = await FirebaseMessaging.instance.getToken();
            if (rawToken != null && rawToken.isNotEmpty) break;
          } catch (tErr) {
            debugPrint('fcm token fetch retry ${retry + 1} failed: $tErr');
          }
          await Future.delayed(Duration(seconds: retry + 1));
        }

        if (rawToken != null) {
          debugPrint('========================================');
          debugPrint('success_real_fcm_token:');
          debugPrint(rawToken);
          debugPrint('========================================');
        } else {
          debugPrint(
            ' fcreturned null token. check google play services & google-services.json',
          );
        }
      } catch (e, stackTrace) {
        debugPrint(' criticalcm exception: $e');
        debugPrint('stack trace: $stackTrace');
      }
    });
  }

  void _initMatchListener() {
    final me = MockData().currentUser;
    if (me == null) return;

    String computeMyRoom(UserProfile user) {
      final father = getClanById(user.fatherClanId)?.type ?? '';
      final mother = getClanById(user.motherClanId)?.type ?? '';
      final isFirst = user.maritalStatus == MaritalStatus.first;

      if (father != mother && isFirst) return 'ROOM_1_FIRST_MARRIAGE';
      if (father != mother && !isFirst) return 'ROOM_2_SECOND_MARRIAGE';
      if (father == 'Panthi' && mother == 'Panthi') return 'ROOM_3_PANTHI_OUT';
      if (father == 'Bandhu' && mother == 'Bandhu') return 'ROOM_4_BANDHU_OUT';
      return 'UNKNOWN';
    }

    final myRoom = computeMyRoom(me);

    _matchChannel = Supabase.instance.client
        .channel('room:$myRoom')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'profile_matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: me.id,
          ),
          callback: (payload) {
            if (payload.newRecord['status'] == 'LIKED') {
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '🎉 പുതിയ പൊരുത്തം ലഭിച്ചു! (New Mutual Match!)',
                  ),
                ),
              );
            }
          },
        )
        .subscribe();
  }

  void _initIncomingCallListener() {
    final userId =
        Supabase.instance.client.auth.currentUser?.id ??
        MockData().currentUser?.id;
    if (userId == null || userId.isEmpty) return;

    try {
      _callListenerChannel = Supabase.instance.client
          .channel('user_calls_$userId')
          .onBroadcast(
            event: 'incoming_call_signal',
            callback: (payload) {
              final String callId = payload['call_id']?.toString() ?? '';
              final String callerId = payload['caller_id']?.toString() ?? '';
              final String callerName =
                  payload['caller_name']?.toString() ?? 'കുറിച്ച്യർ ഉപയോക്താവ്';
              final String callType =
                  payload['call_type']?.toString() ?? 'audio';

              if (callId.isNotEmpty && mounted && context.mounted) {
                IncomingCallDialog.show(
                  context,
                  callId: callId,
                  callerId: callerId,
                  callerName: callerName,
                  callType: callType,
                  currentUserId: userId,
                );
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Incoming call listener notice: $e');
    }
  }

  @override
  void dispose() {
    _matchChannel?.unsubscribe();
    _callListenerChannel?.unsubscribe();
    super.dispose();
  }

  void _showMatchesInterstitial(int targetIndex) async {
    final me = MockData().currentUser;
    if (me != null && me.isPremium) {
      setState(() => _currentIndex = targetIndex);
      return;
    }

    InterstitialAd.load(
      adUnitId:
          'ca-app-pub-3940256099942544/1033173712', // Test Interstitial ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show();
          setState(() => _currentIndex = targetIndex);
        },
        onAdFailedToLoad: (err) {
          debugPrint('Matches Interstitial failed: $err');
          setState(() => _currentIndex = targetIndex);
        },
      ),
    );
  }

  void _checkBirthday() async {
    final me = MockData().currentUser, now = DateTime.now();
    if (me?.dob == null ||
        me!.dob!.month != now.month ||
        me.dob!.day != now.day)
  { return; }
    final prefs = await SharedPreferences.getInstance(),
        key = 'hasShownBirthdayOverlay_${now.year}';
    if (!(prefs.getBool(key) ?? false)) {
      await prefs.setBool(key, true);
      if (mounted) {
        showDialog(
          context: context,
          useSafeArea: false,
          barrierDismissible: false,
          builder: (ctx) => BirthdayOverlay(
            profilePhotoUrl: me.photoUrl,
            onClose: () => Navigator.pop(ctx),
          ),
        );
      }
    }
  }

  Future<void> _openSettings(BuildContext context) async {
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
        MaterialPageRoute(builder: (_) => const SettingsPage()),
      );
    }
  }

  bool get isAdmin => MockData().currentUser?.role == 'admin';

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // Admin users bypass the approval lock
    if (isAdmin || currentUserId == null) {
      return _buildFullDashboard(context);
    }

    // ⚡ Realtime Supabase Stream: Listens to approval status in real-time
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('kurichiyar_profiles')
          .stream(primaryKey: ['id'])
          .eq('id', currentUserId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Realtime approval stream error: ${snapshot.error}');
          return _buildFullDashboard(context);
        }

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final profile = snapshot.data!.first;
          final bool isApproved =
              profile['is_approved'] == true ||
              profile['is_approved']?.toString().toLowerCase() == 'true' ||
              (profile['registration_status'] ?? '').toString().toLowerCase() ==
                  'approved' ||
              (profile['account_status'] ?? '').toString().toLowerCase() ==
                  'approved' ||
              (profile['verification_status'] ?? '').toString().toLowerCase() ==
                  'approved';

          // 🔴 If unapproved: replace entire dashboard and bottom navigation bar with FullScreenAdView
          if (!isApproved) {
            return const FullScreenAdView();
          }
        }

        // 🟢 If approved: Immediately and automatically renders full matrimony dashboard
        return _buildFullDashboard(context);
      },
    );
  }

  Widget _buildFullDashboard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titles = [
      l10n?.moietyChecker ?? 'Moiety Compatibility Checker',
      'Kurichiyar Matrimony',
      l10n?.clanFeed ?? 'Clan Feed',
      l10n?.matches ?? 'Matches',
      l10n?.chat ?? 'Inbox Messages',
      l10n?.profile ?? 'My Profile',
    ];

    return ListenableBuilder(
      listenable: MockData(),
      builder: (context, _) {
        final u = MockData().currentUser;
        if (u == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF000080)),
            ),
          );
        }

        final tabs = [
          const SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: CheckerWidget(isGuest: false),
            ),
          ),
          HomeTab(
            currentUser: u,
            onNavigateToChat: () => setState(() => _currentIndex = 4),
          ),
          const ClanFeedTab(),
          const MatchesScreen(showAppBar: false),
          const ChatTab(),
          ProfileTab(
            onLoggedOut: () async {
              await Supabase.instance.client.auth.signOut();
              await MockData().logout();
              // Routing is handled automatically by auth_wrapper/main.dart auth state listener.
            },
          ),
        ];

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_currentIndex != 1) {
              setState(() => _currentIndex = 1);
              return;
            }

            final now = DateTime.now();
            if (_lastBackPressTime == null ||
                now.difference(_lastBackPressTime!) >
                    const Duration(seconds: 2)) {
              _lastBackPressTime = now;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Press back again to exit'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            SystemNavigator.pop();
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: Row(
                children: [
                  const CoinFlipLogoWidget(size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titles[_currentIndex],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF000080),
              foregroundColor: Colors.white,
              actions: [
                const NotificationBellIcon(),
                ValueListenableBuilder<int>(
                  valueListenable: SupportUnreadService.instance.unreadCount,
                  builder: (context, count, _) {
                    return Badge(
                      isLabelVisible: count > 0,
                      label: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.red,
                      child: IconButton(
                        icon: const Icon(Icons.support_agent),
                        tooltip: l10n?.helpAndSupport ?? 'Help & Support',
                        onPressed: () {
                          final currentUserId =
                              Supabase.instance.client.auth.currentUser?.id ??
                              MockData().currentUser?.id ??
                              '';
                          final currentUserName =
                              MockData().currentUser?.name ?? 'User';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserSupportChatScreen(
                                userId: currentUserId,
                                userName: currentUserName,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => _openSettings(context),
                ),
              ],
            ),
            drawer: _buildDrawer(context, u),
            body: Column(
              children: [
                const AdBannerWidget(),
                Expanded(
                  child: IndexedStack(index: _currentIndex, children: tabs),
                ),
                const AdBannerWidget(),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (i) {
                    if (i == 3) {
                      _showMatchesInterstitial(i);
                    } else {
                      setState(() => _currentIndex = i);
                    }
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.white,
                  selectedItemColor: const Color(0xFF000080),
                  unselectedItemColor: const Color(0xFF718096),
                  iconSize: 21,
                  selectedFontSize: 11,
                  unselectedFontSize: 10,
                  showUnselectedLabels: true,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: -0.2,
                    height: 1.3,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                    letterSpacing: -0.2,
                    height: 1.3,
                  ),
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.compare_arrows),
                      label: l10n?.moietyChecker ?? 'Checker',
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home),
                      label: l10n?.home ?? 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.hub),
                      label: l10n?.clanFeed ?? 'Clan Feed',
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.favorite),
                      label: l10n?.matches ?? 'Matches',
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.chat),
                      label: l10n?.chat ?? 'Chat',
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.person),
                      label: l10n?.profile ?? 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, UserProfile u) {
    final String email = u.email.trim();
    String displaySubtitle = '';

    if (email.isNotEmpty &&
        !email.contains('@auth.kurichiyar.com') &&
        !email.contains('@kurichiyar.com')) {
      displaySubtitle = email;
    } else {
      String extractedPhone = '';
      if (email.contains('@auth.kurichiyar.com')) {
        extractedPhone = email.split('@').first.replaceAll(RegExp(r'\D'), '');
      }
      if (extractedPhone.isEmpty &&
          u.guardianPhone != null &&
          u.guardianPhone!.trim().isNotEmpty) {
        extractedPhone = u.guardianPhone!.trim();
      }
      if (extractedPhone.isEmpty &&
          u.publicDisplayNumber != null &&
          u.publicDisplayNumber!.trim().isNotEmpty) {
        extractedPhone = u.publicDisplayNumber!.trim();
      }

      if (extractedPhone.isNotEmpty) {
        displaySubtitle = extractedPhone.startsWith('+91')
            ? extractedPhone
            : '+91 $extractedPhone';
      } else {
        displaySubtitle =
            'KM-${u.id.length >= 6 ? u.id.substring(0, 6).toUpperCase() : u.id.toUpperCase()}';
      }
    }

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF000080)),
            accountName: Text(
              u.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(displaySubtitle),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage:
                  (u.photoUrl.startsWith('http')
                          ? NetworkImage(u.photoUrl)
                          : File(u.photoUrl).existsSync()
                          ? FileImage(File(u.photoUrl))
                          : const AssetImage(
                              'assets/images/default_avatar.png',
                            ))
                      as ImageProvider,
            ),
          ),
          _item(
            Icons.notifications,
            'My Alerts & Notifications',
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
            ),
          ),
          const Divider(),
          _item(
            Icons.account_tree_outlined,
            'കുടുംബമാല (Family Tree)',
            Colors.green.shade700,
            () => handleFamilyTreeNavigation(context),
          ),
          const Divider(),
          _item(
            Icons.workspace_premium,
            'Premium Packages',
            Colors.amber,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubscriptionPage(currentUser: u),
              ),
            ),
          ),
          const Divider(),
          _item(
            Icons.star,
            'My Shortlists',
            Colors.amber,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyCartPage()),
            ),
          ),
          _item(
            Icons.visibility,
            'Who Viewed My Profile',
            Colors.purple,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileVisitorsPage()),
            ),
          ),
          const Divider(),
          _item(Icons.history_edu, 'Mutual Agreements', Colors.teal, () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => EditProfileSheet(user: u),
            );
          }),

          const Divider(),
          _item(
            Icons.settings,
            'Settings',
            Colors.grey,
            () => _openSettings(context),
          ),
          const Spacer(),
          const Divider(),
          _item(Icons.logout, 'Logout', Colors.red, () {
            MockData().logout();
            Navigator.pushReplacementNamed(context, '/');
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _item(IconData i, String t, Color c, VoidCallback onTap) => ListTile(
    leading: Icon(i, color: c),
    title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
    onTap: () {
      Navigator.pop(context);
      onTap();
    },
  );

  Widget buildStatusList(List<dynamic> statusList) {
    if (statusList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'സ്റ്റാറ്റസുകൾ ലഭ്യമല്ല',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: statusList.length,
      itemBuilder: (context, index) {
        final item = statusList[index];

        // ക്രാഷ് ആവാതിരിക്കാൻ കാർഡിനെ സുരക്ഷിതമാക്കുന്നു
        try {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.amber.shade100,
                child: const Icon(Icons.person, color: Colors.amber),
              ),
              title: Text(
                item['title'] ??
                    item['name'] ??
                    item['sender_name'] ??
                    'Status',
              ),
              subtitle: Text(item['created_at']?.toString() ?? ''),
            ),
          );
        } catch (e) {
          return const SizedBox.shrink(); // ഏതെങ്കിലും കാർഡിൽ തെറ്റുണ്ടെങ്കിൽ ആപ്പ് വൈറ്റ് ആവാതെ ഒഴിവാക്കും
        }
      },
    );
  }
}
