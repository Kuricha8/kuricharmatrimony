import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:provider/provider.dart';
import 'core/providers/app_config_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/unlocked_contacts_provider.dart';
import 'features/auth_splash/splash_screen.dart';
import 'features/auth_splash/guest_page.dart';
import 'features/auth/login_page.dart';
import 'features/registration/registration_wizard.dart';
import 'features/agent_registration/agent_registration_screen.dart';
import 'features/registration/waiting_screen.dart';
import 'features/dashboard/dashboard_shell.dart';
import 'features/agent_dashboard/agent_dashboard_shell.dart';
import 'features/agent_dashboard/agent_waiting_screen.dart';
import 'features/agent_dashboard/agent_qr_scanner_screen.dart';
import 'features/public/public_download_page.dart';
import 'package:kurichiyar_matrimony/l10n/app_localizations.dart';
import 'core/services/community_service.dart';
import 'core/services/status_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/clan_feed/tharavadu_list.dart';
import 'core/services/local_cache_service.dart';
import 'features/profile_detail/profile_detail_page.dart';
import 'core/widgets/auth_wrapper.dart';
import 'core/widgets/auth_gate.dart';
import 'core/widgets/global_security_blocker.dart';
import 'core/widgets/global_popup_interceptor.dart';
import 'core/utils/thug_dialogues.dart';
import 'core/localization/localization_service.dart';
import 'core/utils/mock_data.dart';
import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'features/registration/profile_completion_screen.dart';
import 'features/registration/smart_tharavadu_registration_screen.dart';
import 'features/registration/correction_screen.dart';
import 'features/registration/widgets/verification_pending_screen.dart';
import 'features/registration/force_photo_upload_screen.dart';
import 'features/registration/qr_register_screen.dart';
import 'core/services/global_features_service.dart';
import 'features/verification/verification_call_listener.dart';
import 'features/settings/guest_settings_screen.dart';
import 'features/settings/settings_page.dart';
import 'features/notifications/notification_center_screen.dart';

import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'features/moiety_checker/checker_screen.dart';
import 'features/matching/matches_page.dart';
import 'core/models/models.dart';
import 'core/services/notification_manager.dart';
import 'core/security/tamper_detection_service.dart';
import 'core/services/admob_service.dart';
import 'core/security/ssl_pinning_service.dart';
import 'core/services/shake_telemetry_service.dart';
import 'core/services/in_app_update_service.dart';
import 'core/services/app_service.dart';
import 'package:screen_protector/screen_protector.dart';
import 'core/security/window_security_service.dart';
import 'core/services/kinship_service.dart';

final RouteObserver<PageRoute> globalRouteObserver = RouteObserver<PageRoute>();
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    "FCM_DEBUG: Received BACKGROUND message: ${message.notification?.title}",
  );
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _setupLocalNotifications();
  await NotificationManager.showNotification(
    title:
        message.notification?.title ?? message.data['title'] ?? 'Notification',
    body: message.notification?.body ?? message.data['body'] ?? '',
  );
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _setupLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  try {
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  } catch (e) {
    debugPrint("Local Notifications init error: $e");
  }
  const channels = [
    AndroidNotificationChannel(
      'high_importance_channel',
      'പ്രധാന അറിയിപ്പുകൾ (High Importance)',
      description: 'പുതിയ ഉപയോക്താക്കൾ, അപ്രൂവലുകൾ എന്നിവയ്ക്കുള്ള ചാനൽ',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    ),
    AndroidNotificationChannel(
      'high_importance_channel_v8',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    ),
    AndroidNotificationChannel(
      'kym_custom_sound_channel',
      'User Custom Sound Channel',
      description:
          'This channel is used for important match and message notifications.',
      importance: Importance.max,
      playSound: true,
    ),
    AndroidNotificationChannel(
      'kym_admin_alerts_channel',
      'Admin Critical Alerts',
      description: 'Realtime loud alerts for new user registrations',
      importance: Importance.max,
      playSound: true,
    ),
    AndroidNotificationChannel(
      'clan_high_importance_channel',
      'Tharavadu Clan Notifications',
      description: 'Notifications for clan status updates and chat messages',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    ),
    AndroidNotificationChannel(
      'app_updates',
      'App Updates (ആപ്പ് അപ്ഡേറ്റുകൾ)',
      description: 'Notifications for new app updates and releases',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    ),
    AndroidNotificationChannel(
      'general_announcements',
      'General Announcements (പൊതു അറിയിപ്പുകൾ)',
      description: 'Community news, general announcements, and system alerts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    ),
  ];

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  if (androidPlugin != null) {
    // Cleanup old cached channels
    await androidPlugin.deleteNotificationChannel(
      channelId: 'high_importance_channel_v3',
    );
    await androidPlugin.deleteNotificationChannel(
      channelId: 'high_importance_channel_v4',
    );
    await androidPlugin.deleteNotificationChannel(
      channelId: 'high_importance_channel_v6',
    );
    await androidPlugin.deleteNotificationChannel(
      channelId: 'high_importance_channel_v7',
    );

    for (final channel in channels) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }
}

Future<void> _logErrorToSupabase(String errorMessage) async {
  try {
    LogBuffer.add('GLOBAL_ERR: $errorMessage');
    String route = RouteBreadcrumbObserver.instance.currentRouteName;
    final user =
        Supabase.instance.client.auth.currentUser?.email ??
        Supabase.instance.client.auth.currentUser?.id ??
        'Guest';

    await Supabase.instance.client.from('app_error_logs').insert({
      'error_message': errorMessage,
      'route_name': route,
      'user_affected': user,
    });
  } catch (_) {
    // Silently fail if logging fails
  }
}

Future<void> setupFCM() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. പെർമിഷൻ ചോദിക്കുന്നു (Android 13+ & iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. എല്ലാവർക്കുമുള്ള ടോപ്പിക്ക് സബ്സ്ക്രൈബ് ചെയ്യുന്നു
      await messaging.subscribeToTopic('all_users');
      debugPrint("Subscribed to all_users topic successfully!");
    }
  } catch (e) {
    debugPrint("setupFCM error: $e");
  }
}

bool isSupabaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase first before any Firebase service, Firestore listener, or runApp
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint("Firebase initialized successfully on startup.");
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  // 2. Global Default: Block screenshots and screen recordings across the entire app on startup
  try {
    if (!kIsWeb) {
      await ScreenProtector.protectDataLeakageOn();
      await WindowSecurityService.enableSecureScreen();
    }
    SslPinningService.initialize();
  } catch (e) {
    debugPrint('[Security] Startup ScreenProtector notice: $e');
  }

  // 3. Initialize Supabase (~50ms) before mounting widget tree so Supabase.instance is valid
  try {
    const finalUrl = 'https://noidreeslytswkmsnmcn.supabase.co';
    const finalKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vaWRyZWVzbHl0c3drbXNubWNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5NTA2ODksImV4cCI6MjA5OTUyNjY4OX0.VnpX0xjRNi89efECRAzMiu79trSQlblpRjfWZLkjMo4';

    await Supabase.initialize(
      url: finalUrl,
      publishableKey: finalKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 10),
      postgrestOptions: const PostgrestClientOptions(schema: 'public'),
    ).timeout(const Duration(seconds: 3));
    isSupabaseInitialized = true;
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  // 4. Notifications & FCM (after Firebase is successfully initialized)
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _setupLocalNotifications();
    await NotificationManager.instance.init();
    await setupFCM();
    await AppService.initializeFCM();

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  } catch (e) {
    debugPrint("Notifications & FCM setup notice: $e");
  }

  // 5. Initialize saved locale before mounting widget tree
  try {
    await MockData().initLocale();
  } catch (e) {
    debugPrint('MockData initLocale error: $e');
  }

  // 6. Instantly attach UI framework window to prevent Android ANR
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppConfigProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..init()),
        ChangeNotifierProvider(create: (_) => UnlockedContactsProvider()),
      ],
      child: const KurichiyarMatrimonyApp(),
    ),
  );

  // 7. Initialize all remaining background services asynchronously in parallel
  unawaited(_initializeBackgroundServices());
}

Future<void> _initializeBackgroundServices() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _logErrorToSupabase(details.exceptionAsString());
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    _logErrorToSupabase(error.toString());
    return true;
  };

  try {
    unawaited(TamperDetectionService.runSecurityAudit());
  } catch (e) {
    debugPrint("Security audit notice: $e");
  }

  try {
    await dotenv.load(fileName: ".env").timeout(const Duration(seconds: 1));
  } catch (e) {
    debugPrint("dotenv load warning: $e");
  }

  try {
    await LocalCacheService.instance.initialize().timeout(
      const Duration(seconds: 2),
    );
    await TharavaduService.instance.loadCachedClans().timeout(
      const Duration(seconds: 2),
    );
    TharavaduService.instance.subscribeToUpdates();
  } catch (e) {
    debugPrint("Hive init warning: $e");
  }

  try {
    if (!kIsWeb) {
      await MobileAds.instance.initialize();
      AdMobService.instance.loadRewardedAd();
    }
  } catch (e) {
    debugPrint("MobileAds init warning: $e");
  }

  // Force fetch and print real FCM token on startup
  try {
    final realStartupToken = await FirebaseMessaging.instance.getToken();
    debugPrint('========================================');
    debugPrint('STARTUP_REAL_FCM_TOKEN: $realStartupToken');
    debugPrint('========================================');

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null &&
        currentUserId.isNotEmpty &&
        realStartupToken != null) {
      await NotificationManager.instance.registerFCMToken(currentUserId);
    }
  } catch (e) {
    debugPrint('fcm error: $e');
  }

  try {
    unawaited(
      MobileAds.instance
          .initialize()
          .timeout(const Duration(seconds: 1))
          .then((initStatus) {
            initStatus.adapterStatuses.forEach((key, value) {
              debugPrint('AdMob Adapter status for $key: ${value.state}');
            });
          })
          .catchError((e) {
            debugPrint("MobileAds initialization warning: $e");
          }),
    );
  } catch (e) {
    debugPrint("MobileAds try-catch warning: $e");
  }

  try {
    await GlobalFeaturesService.instance.loadSettings().timeout(
      const Duration(seconds: 2),
    );
    GlobalFeaturesService.instance.initRealtimeListener();
    TharavaduService.instance.subscribeToUpdates();
    KinshipService.instance.syncTharavadsFromFirestore();
    ThugDialogues.syncDialoguesFromCloud();
  } catch (e) {
    debugPrint("Global features init warning: $e");
  }

  // --- AUTOMATIC FCM TOKEN REGISTRATION LISTENER ---
  try {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        final userId = session.user.id;
        debugPrint(
          'critical_log: Auth session detected for user $userId. Checking FCM token...',
        );
        try {
          // Explicitly trigger permission prompt
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            await Supabase.instance.client
                .from('kurichiyar_profiles')
                .update({
                  'fcm_token': token,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', userId);
            debugPrint(
              'critical_log: FCM TOKEN UPDATED SUCCESSFULLY FOR USER: $userId',
            );
          } else {
            debugPrint(
              'critical_error: Failed to get FCM token from Firebase.',
            );
          }
        } catch (e) {
          debugPrint('critical_error: FCM token auto-registration failed: $e');
        }
      }
    });
  } catch (e) {
    debugPrint("Auth state listener init warning: $e");
  }
}

class KurichiyarMatrimonyApp extends StatefulWidget {
  static bool isTesting = false;

  const KurichiyarMatrimonyApp({super.key});

  @override
  State<KurichiyarMatrimonyApp> createState() => _KurichiyarMatrimonyAppState();
}

class _KurichiyarMatrimonyAppState extends State<KurichiyarMatrimonyApp> {
  // late AppLifecycleReactor _appLifecycleReactor;
  late StreamSubscription<AuthState> _globalAuthSubscription;

  @override
  void initState() {
    super.initState();
    // Dynamically listen to Firestore screenshot flag and maintain window flags in real time
    WindowSecurityService.initializeGlobalSecurity();
    // _appLifecycleReactor = AppLifecycleReactor(
    //    appOpenAdManager: AppOpenAdManager());
    // WidgetsBinding.instance.addObserver(_appLifecycleReactor);

    _globalAuthSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          final session =
              data.session ?? Supabase.instance.client.auth.currentSession;
          if (session != null && !session.user.isAnonymous) {
            // Auto-register FCM token for the active user
            NotificationManager.instance.registerFCMToken(session.user.id);

            final context = appNavigatorKey.currentContext;
            if (context != null && context.mounted) {
              // ignore: use_build_context_synchronously
              final currentRoute = ModalRoute.of(context)?.settings.name;
              if (currentRoute == '/login' ||
                  currentRoute == '/guest' ||
                  currentRoute == '/splash') {
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              }
            }
          } else if (data.event == AuthChangeEvent.signedOut) {
            if (Supabase.instance.client.auth.currentUser == null) {
              appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                '/guest',
                (route) => false,
              );
            }
          }
        });

    if (!KurichiyarMatrimonyApp.isTesting) {
      // Subscribe to community updates (announcements, history)
      CommunityService.instance.subscribeToUpdates();
      StatusService.instance.subscribeToStatuses();
      // Sync tharavadu list with retry (handles Supabase cold-start PGRST002 errors)
      TharavaduService.instance.syncClans(
        maxRetries: 5,
        retryDelay: const Duration(seconds: 4),
      );

      // Listen for real-time Admin App update configs from Firestore (app_updates/latest)
      InAppUpdateService.instance.initRealtimeUpdateListener();

      // Initialize silent shake telemetry collector and check for OTA updates on launch
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ShakeTelemetryService.instance.initialize(context);
          // Check for in-app APK updates on launch (bypassing Play Store)
          AppService.checkDirectUpdate(context);
        }
      });
    }
  }

  @override
  void dispose() {
    // WidgetsBinding.instance.removeObserver(_appLifecycleReactor);
    _globalAuthSubscription.cancel();
    ShakeTelemetryService.instance.dispose();
    WindowSecurityService.dispose();
    InAppUpdateService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = Provider.of<AppConfigProvider>(context);

    return ListenableBuilder(
      listenable: Listenable.merge([
        MockData(),
        LocalizationService.instance,
        GlobalFeaturesService.instance,
      ]),
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'Kurichiyar Matrimony',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: MockData().appLocale,
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFFFFFFF),
            fontFamilyFallback: const [
              'Noto Sans Malayalam',
              'Manjari',
              'Roboto',
              'sans-serif',
            ],
            colorScheme: ColorScheme.fromSeed(
              seedColor: appConfig.primaryColor,
              primary: appConfig.primaryColor,
              secondary: appConfig.accentColor,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: appConfig.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: appConfig.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            textTheme:
                GoogleFonts.notoSansMalayalamTextTheme(
                  ThemeData.light().textTheme,
                ).apply(
                  fontFamilyFallback: const [
                    'Noto Sans Malayalam',
                    'Manjari',
                    'Roboto',
                    'sans-serif',
                  ],
                  bodyColor: const Color(0xFF333333),
                  displayColor: const Color(0xFF333333),
                ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Color(0xFF000080),
              unselectedItemColor: Color(0xFF718096),
              selectedLabelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
                height: 1.3,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                height: 1.3,
              ),
              showSelectedLabels: true,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              elevation: 8,
            ),
            useMaterial3: true,
          ),
          initialRoute: '/',
          navigatorObservers: [
            globalRouteObserver,
            RouteBreadcrumbObserver.instance,
          ],
          builder: (context, child) {
            if (appConfig.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (appConfig.systemSwitches['maintenance_mode'] == true) {
              // A very basic interceptor for Maintenance Mode
              // Note: In reality, you'd check if currentUser is NOT admin before blocking
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.build,
                        size: 60,
                        color: appConfig.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'System Under Maintenance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('We will be back shortly!'),
                    ],
                  ),
                ),
              );
            }

            Widget appContent = ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: const [
                Breakpoint(start: 0, end: 450, name: MOBILE),
                Breakpoint(start: 451, end: 800, name: TABLET),
                Breakpoint(start: 801, end: 1920, name: DESKTOP),
              ],
            );
            if (kIsWeb) {
              final mediaQuery = MediaQuery.of(context);
              if (mediaQuery.size.width > 600) {
                appContent = Container(
                  color: const Color(0xFF000B4F),
                  alignment: Alignment.center,
                  child: ClipRRect(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: appContent,
                    ),
                  ),
                );
              }
            }

            return RepaintBoundary(
              key: ShakeTelemetryService.rootBoundaryKey,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: kIsWeb
                      ? const TextScaler.linear(1.0)
                      : TextScaler.linear(
                          MediaQuery.of(
                            context,
                          ).textScaler.scale(1.0).clamp(0.85, 1.15),
                        ),
                ),
                child: VerificationCallListener(
                  child: GlobalPopupInterceptor(
                    child: GlobalSecurityBlocker(child: appContent),
                  ),
                ),
              ),
            );
          },
          routes: {
            '/': (context) => const AuthWrapper(child: DashboardShell()),
            '/home': (context) => const AuthWrapper(child: DashboardShell()),
            '/auth_gate': (context) => const AuthGate(),
            '/profile_completion': (context) => ProfileCompletionScreen(
              initialData:
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>? ??
                  {},
            ),
            '/splash': (context) => const SplashScreen(),
            '/guest': (context) => GuestScreen(),
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegistrationWizard(),
            '/agent_register': (context) => const AgentRegistrationScreen(),
            '/waiting': (context) => const WaitingScreen(),
            '/dashboard': (context) =>
                const DashboardShell(), // Protected route internally
            '/admin': (context) => const AgentDashboardShell(),
            '/admin_dashboard': (context) => const AgentDashboardShell(),
            '/agent_dashboard': (context) => const AgentDashboardShell(),
            '/agent_waiting': (context) => const AgentWaitingScreen(),
            '/agent_qr_scanner': (context) => const AgentQrScannerScreen(),
            '/qr_register': (context) => const QrRegisterScreen(),
            '/download': (context) => const PublicDownloadPage(),
            '/moiety_checker': (context) => const MoietyCheckerScreen(),
            '/smart_tharavadu_registration': (context) =>
                const SmartTharavaduRegistrationScreen(),
            '/family_tree_registration': (context) =>
                const SmartTharavaduRegistrationScreen(),
            '/matches': (context) => const MatchesScreen(),
            '/verification_pending': (context) =>
                const VerificationPendingScreen(),
            '/upload_photo': (context) => const ForcePhotoUploadScreen(),
            '/correction': (context) => CorrectionScreen(
              profile:
                  ModalRoute.of(context)!.settings.arguments as UserProfile,
            ),
            '/guest_settings': (context) => const GuestSettingsScreen(),
            '/settings': (context) => const SettingsPage(),
            '/notification_center': (context) => const NotificationCenterScreen(),
          },
          onGenerateRoute: (RouteSettings settings) {
            final name = settings.name;
            if (name != null) {
              if (name == '/profile_detail') {
                final profileId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (context) => ProfileDetailPage(profileId: profileId),
                  settings: settings,
                );
              }
              final uri = Uri.tryParse(name);
              if (uri != null) {
                final segments = uri.pathSegments;
                if (segments.length >= 2 &&
                    (segments[0] == 'profile' || segments[0] == 'p')) {
                  final profileId = segments[1].replaceAll('km-2026-', '');
                  return MaterialPageRoute(
                    builder: (context) =>
                        ProfileDetailPage(profileId: profileId),
                    settings: settings,
                  );
                }
              }
            }
            return null; // Fallback to routes map
          },
        );
      },
    );
  }
}
