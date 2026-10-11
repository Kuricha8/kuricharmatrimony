import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/guest_favorites_service.dart';
import '../../core/services/in_app_update_service.dart';
import '../../core/utils/mock_data.dart';
import '../../core/widgets/universal_profile_card.dart';
import '../auth_splash/widgets/guest_auth_bottom_sheet.dart';
import '../../core/services/registration_route_helper.dart';
import '../../core/services/biometric_auth_service.dart';

class GuestSettingsScreen extends StatefulWidget {
  final bool isModal;
  const GuestSettingsScreen({super.key, this.isModal = false});

  /// Opens the Guest Settings as a modern Bottom Sheet
  static Future<void> showAsBottomSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: const GuestSettingsScreen(isModal: true),
        ),
      ),
    );
  }

  @override
  State<GuestSettingsScreen> createState() => _GuestSettingsScreenState();
}

class _GuestSettingsScreenState extends State<GuestSettingsScreen> {
  bool _notificationSoundEnabled = true;
  bool _isAppLockEnabled = false;
  String _appVersion = 'v1.0.0';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sound = prefs.getBool('guest_notification_sound_enabled') ?? true;
      final appLock = await BiometricAuthService.instance.isAppLockEnabled();
      final info = await PackageInfo.fromPlatform();

      if (mounted) {
        setState(() {
          _notificationSoundEnabled = sound;
          _isAppLockEnabled = appLock;
          _appVersion = 'v${info.version} (Build ${info.buildNumber})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleAppLock(bool value) async {
    final reason = value
        ? 'ആപ്പ് ലോക്ക് സജീവമാക്കാൻ ദയവായി നിങ്ങളുടെ ഫോൺ ലോക്ക് അല്ലെങ്കിൽ വിരലടയാളം സ്ഥിരീകരിക്കുക'
        : 'ആപ്പ് ലോക്ക് ഒഴിവാക്കാൻ ദയവായി സ്ഥിരീകരിക്കുക';

    final success = await BiometricAuthService.instance.authenticate(
      localizedReason: reason,
    );
    if (success) {
      await BiometricAuthService.instance.setAppLockEnabled(value);
      if (mounted) {
        setState(() => _isAppLockEnabled = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'ആപ്പ് ലോക്ക് വിജയകരമായി സജീവമാക്കി! (App Lock Enabled)'
                  : 'ആപ്പ് ലോക്ക് ഒഴിവാക്കി (App Lock Disabled).',
            ),
            backgroundColor: value ? Colors.green.shade700 : Colors.black87,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() {}); // Revert toggle visually
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('സ്ഥിരീകരണം പൂർത്തിയായില്ല (Verification not completed).'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _toggleNotificationSound(bool value) async {
    setState(() {
      _notificationSoundEnabled = value;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('guest_notification_sound_enabled', value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                ? 'അറിയിപ്പ് ശബ്ദം ഓണാക്കി (Notification sound ON)'
                : 'അറിയിപ്പ് ശബ്ദം ഓഫാക്കി (Notification sound OFF)',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  void _openLikedProfiles(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GuestLikedProfilesScreen(),
      ),
    );
  }

  Future<void> _contactSupport(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'സഹായം & അന്വേഷണങ്ങൾ (Support)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'മാട്രിമോണി സേവനങ്ങളുമായി ബന്ധപ്പെട്ട സംശയങ്ങൾക്ക് അഡ്മിനെ ബന്ധപ്പെടാം:',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final Uri url = Uri.parse(
                    "https://wa.me/918606415174?text=${Uri.encodeComponent('ഹലോ അഡ്മിൻ, കുറിച്ച്യർ മാട്രിമോണി ആപ്പുമായി ബന്ധപ്പെട്ട് ഒരു സംശയമുണ്ട്.')}",
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.chat_outlined, color: Colors.white),
                label: const Text('WhatsApp വഴി സംസാരിക്കുക'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final Uri url = Uri.parse("tel:+918606415174");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                icon: const Icon(Icons.phone, color: Color(0xFF1E3A8A)),
                label: const Text('ഫോൺ വിളിക്കുക (+91 86064 15174)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('അപ്‌ഡേറ്റുകൾ പരിശോധിക്കുന്നു...'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await InAppUpdateService.instance.checkForUpdates(
      context,
      forceCheck: true,
      showNoUpdateToast: true,
    );
  }

  Future<void> _navigateToAuth(BuildContext context) async {
    final isRegistered =
        await RegistrationRouteHelper.isUserRegisteredOrPending();
    if (!context.mounted) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: !widget.isModal,
        leading: widget.isModal
            ? IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'ക്രമീകരണങ്ങൾ (Settings)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header Card (Guest Mode)
                  _buildGuestHeaderCard(context),

                  const SizedBox(height: 20),

                  // 2. Settings Options List
                  _buildSettingsSection(
                    title: 'മുൻഗണനകൾ (Preferences)',
                    children: [
                      // Sound Toggle
                      SwitchListTile.adaptive(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.volume_up_outlined,
                            color: Color(0xFF1E3A8A),
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'അറിയിപ്പ് ശബ്ദം (Sound Alerts)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: const Text(
                          'പുതിയ അറിയിപ്പുകൾക്ക് ശബ്ദം കേൾക്കുക',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        value: _notificationSoundEnabled,
                        activeTrackColor: const Color(0xFF1E3A8A),
                        onChanged: _toggleNotificationSound,
                      ),
                      const Divider(height: 1),

                      // App Lock Toggle
                      SwitchListTile.adaptive(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fingerprint_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'ആപ്പ് ലോക്ക് / ഫിംഗർപ്രിന്റ് (App Lock)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: const Text(
                          'ഫോൺ ലോക്ക് / വിരലടയാളം ഉപയോഗിച്ച് ആപ്പ് സുരക്ഷിതമാക്കുക',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        value: _isAppLockEnabled,
                        activeTrackColor: const Color(0xFF1E3A8A),
                        onChanged: _toggleAppLock,
                      ),
                      const Divider(height: 1),

                      // My Liked Profiles
                      ListenableBuilder(
                        listenable: GuestFavoritesService.instance,
                        builder: (context, _) {
                          final count =
                              GuestFavoritesService.instance.favoriteIds.length;
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.pink.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.pink,
                                size: 20,
                              ),
                            ),
                            title: const Text(
                              'ഞാൻ ലൈക്ക് ചെയ്തവ (My Liked)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              count > 0
                                  ? '$count പ്രൊഫൈലുകൾ സൂക്ഷിച്ചിട്ടുണ്ട്'
                              : 'ലൈക്ക് ചെയ്ത പ്രൊഫൈലുകൾ കാണുക',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (count > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.pink,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                            onTap: () => _openLikedProfiles(context),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildSettingsSection(
                    title: 'ആപ്പ് & സഹായം (App & Support)',
                    children: [
                      // Check for updates
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.system_update_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'ആപ്പ് അപ്ഡേറ്റ് പരിശോധിക്കുക',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: const Text(
                          'ഏറ്റവും പുതിയ പതിപ്പ് ഇൻസ്റ്റാൾ ചെയ്യുക',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onTap: () => _checkForUpdates(context),
                      ),
                      const Divider(height: 1),

                      // Help & Support
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'സഹായം & അന്വേഷണങ്ങൾ (Help & Support)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: const Text(
                          'WhatsApp അല്ലെങ്കിൽ ഫോൺ വഴി അഡ്മിനുമായി ബന്ധപ്പെടുക',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onTap: () => _contactSupport(context),
                      ),
                      const Divider(height: 1),

                      // App Version
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.blueGrey,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'ആപ്പ് വേർഷൻ (App Version)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          _appVersion,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGuestHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ഗസ്റ്റ് ഉപയോക്താവ് (Guest Mode)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'പൂർണ്ണ പ്രൊഫൈൽ കാണാനും ബന്ധപ്പെടാനും രജിസ്റ്റർ ചെയ്യുക.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToAuth(context),
              icon: const Icon(Icons.app_registration_rounded, size: 18),
              label: const Text(
                'രജിസ്റ്റർ ചെയ്യുക / ലോഗിൻ (Register / Login)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

/// Dedicated Screen displaying profiles liked by the guest user.
class GuestLikedProfilesScreen extends StatelessWidget {
  const GuestLikedProfilesScreen({super.key});

  Future<void> _openAuth(BuildContext context) async {
    final isRegistered =
        await RegistrationRouteHelper.isUserRegisteredOrPending();
    if (!context.mounted) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'ഞാൻ ലൈക്ക് ചെയ്തവ (Liked Profiles)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: ListenableBuilder(
        listenable: GuestFavoritesService.instance,
        builder: (context, _) {
          final likedIds = GuestFavoritesService.instance.favoriteIds;

          if (likedIds.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.pink.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 64,
                        color: Colors.pink,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ലൈക്ക് ചെയ്ത പ്രൊഫൈലുകൾ ഒന്നുമില്ല',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'പബ്ലിക് ഹബ്ബിൽ നിന്നും പ്രൊഫൈലുകളിലെ ❤️ ബട്ടൺ അമർത്തി ഇവിടെ സൂക്ഷിക്കാം.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Fetch profiles matching likedIds from MockData
          final allProfiles = MockData().profiles;
          final likedProfiles =
              allProfiles.where((p) => likedIds.contains(p.id)).toList();

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: likedProfiles.isNotEmpty ? likedProfiles.length : likedIds.length,
            itemBuilder: (context, index) {
              if (likedProfiles.isNotEmpty) {
                final profile = likedProfiles[index];
                return UniversalProfileCard(
                  profile: profile,
                  isGuest: true,
                  onRegisterLogin: () => _openAuth(context),
                );
              } else {
                // Fallback dummy profile placeholder with the liked ID
                final pid = likedIds.elementAt(index);
                return UniversalProfileCard(
                  rawProfileData: {
                    'id': pid,
                    'full_name': 'അംഗം $pid',
                    'age': 25,
                    'district': 'വയനാട്',
                  },
                  isGuest: true,
                  onRegisterLogin: () => _openAuth(context),
                );
              }
            },
          );
        },
      ),
    );
  }
}
