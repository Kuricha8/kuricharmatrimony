import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/mock_data.dart';
import 'package:kurichiyar_matrimony/core/utils/legal_strings.dart';
import 'package:kurichiyar_matrimony/features/support/user_support_chat_screen.dart';
import 'package:kurichiyar_matrimony/l10n/app_localizations.dart';
import '../../core/services/biometric_auth_service.dart';
import '../../core/services/support_unread_service.dart';
import '../../core/widgets/global_feature_showcase.dart';
import '../auth_splash/guest_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isAppLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkAppLock();
  }

  Future<void> _checkAppLock() async {
    final enabled = await BiometricAuthService.instance.isAppLockEnabled();
    if (mounted) {
      setState(() => _isAppLockEnabled = enabled);
    }
  }

  Future<void> _toggleAppLock(bool enable) async {
    final reason = enable
        ? 'ആപ്പ് ലോക്ക് സജീവമാക്കാൻ ദയവായി നിങ്ങളുടെ ഫോൺ ലോക്ക് അല്ലെങ്കിൽ വിരലടയാളം സ്ഥിരീകരിക്കുക'
        : 'ആപ്പ് ലോക്ക് ഒഴിവാക്കാൻ ദയവായി സ്ഥിരീകരിക്കുക';

    final success = await BiometricAuthService.instance.authenticate(
      localizedReason: reason,
    );
    if (success) {
      await BiometricAuthService.instance.setAppLockEnabled(enable);
      if (mounted) {
        setState(() => _isAppLockEnabled = enable);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enable
                  ? 'ആപ്പ് ലോക്ക് വിജയകരമായി സജീവമാക്കി! (App Lock Enabled)'
                  : 'ആപ്പ് ലോക്ക് ഒഴിവാക്കി (App Lock Disabled).',
            ),
            backgroundColor: enable ? Colors.green.shade700 : Colors.black87,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Revert the toggle visually if authentication failed or was cancelled
      await _checkAppLock();
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.settings ?? 'Settings')),
      body: ListenableBuilder(
        listenable: MockData(),
        builder: (context, child) {
          final mockData = MockData();
          return ListView(
            children: [
              const Divider(),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n?.selectLanguage ?? 'App Language'),
                subtitle: Text(
                  mockData.appLocale.languageCode == 'ml'
                      ? 'മലയാളം'
                      : mockData.appLocale.languageCode == 'hi'
                      ? 'हिन्दी'
                      : 'English',
                ),
                trailing: DropdownButton<Locale>(
                  value: mockData.appLocale,
                  underline: const SizedBox(),
                  onChanged: (Locale? locale) {
                    if (locale != null) {
                      mockData.setLocale(locale);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: Locale('en'),
                      child: Text('English'),
                    ),
                    DropdownMenuItem(
                      value: Locale('ml'),
                      child: Text('മലയാളം'),
                    ),
                    DropdownMenuItem(
                      value: Locale('hi'),
                      child: Text('हिन्दी'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: Text(l10n?.pushNotifications ?? 'Push Notifications'),
                subtitle: const Text(
                  'Receive alerts for matches, messages, and updates.',
                ),
                value: mockData.notificationsEnabled,
                onChanged: (val) => mockData.toggleNotifications(val),
                activeThumbColor: Colors.red.shade700,
              ),
              const Divider(),
              SwitchListTile(
                title: Text(l10n?.accountPrivacy ?? 'Account Privacy'),
                subtitle: const Text(
                  'Hide my profile from public searches and recommendations.',
                ),
                value: mockData.hideProfile,
                onChanged: (val) => mockData.togglePrivacy(val),
                activeThumbColor: Colors.red.shade700,
              ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint, color: Color(0xFF5C3E00)),
                title: const Text(
                  'ആപ്പ് ലോക്ക് / ഫിംഗർപ്രിന്റ് (App Lock)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: const Text(
                  'ഫോൺ ഫിംഗർപ്രിന്റ് അല്ലെങ്കിൽ സ്ക്രീൻ ലോക്ക് ഉപയോഗിച്ച് ആപ്പ് സുരക്ഷിതമാക്കുക',
                  style: TextStyle(fontSize: 12),
                ),
                value: _isAppLockEnabled,
                onChanged: _toggleAppLock,
                activeThumbColor: const Color(0xFFD4AF37),
                activeTrackColor: Colors.amber.shade200,
              ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.screenshot_outlined, color: Color(0xFF000080)),
                title: const Text(
                  'സ്ക്രീൻഷോട്ട് അനുവാദം (Allow Screenshot)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: const Text(
                  'മറ്റ് അംഗങ്ങൾക്ക് നിങ്ങളുടെ പ്രൊഫൈൽ സ്ക്രീൻഷോട്ട് എടുക്കാൻ അനുവാദം നൽകുക (സ്ഥിരസ്ഥിതിയായി സുരക്ഷിതമായി തടയപ്പെട്ടിരിക്കുന്നു).',
                  style: TextStyle(fontSize: 12),
                ),
                value: mockData.currentUser?.allowScreenshot ?? false,
                onChanged: (val) async {
                  await mockData.updateAllowScreenshot(val);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          val
                              ? 'മറ്റു അംഗങ്ങൾക്ക് നിങ്ങളുടെ പ്രൊഫൈൽ സ്ക്രീൻഷോട്ട് എടുക്കാൻ അനുവാദം നൽകി.'
                              : 'നിങ്ങളുടെ പ്രൊഫൈൽ സ്ക്രീൻഷോട്ട് എടുക്കുന്നത് തടഞ്ഞു (Strictly Blocked).',
                        ),
                        backgroundColor: val ? const Color(0xFF000080) : Colors.black87,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                activeThumbColor: const Color(0xFF000080),
                activeTrackColor: Colors.blue.shade200,
              ),
              const Divider(),
              ListTile(
                leading: ValueListenableBuilder<int>(
                  valueListenable: SupportUnreadService.instance.unreadCount,
                  builder: (context, count, _) {
                    return Badge(
                      isLabelVisible: count > 0,
                      label: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.red,
                      alignment: AlignmentDirectional.topEnd,
                      child: const Icon(Icons.help_outline),
                    );
                  },
                ),
                title: Text(l10n?.helpAndSupport ?? 'Help & Support'),
                subtitle: const Text('Contact Admin Raneesh'),
                onTap: () {
                  final user = mockData.currentUser;
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserSupportChatScreen(
                          userId: user.id,
                          userName: user.name,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please log in to use support chat.'),
                      ),
                    );
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.gavel_outlined),
                title: Text(l10n?.termsOfService ?? 'Terms & Conditions'),
                onTap: () => openTermsPage(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy (സ്വകാര്യതാ നയം)'),
                onTap: () => openPrivacyPage(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.currency_rupee_outlined),
                title: const Text('Refund Policy (റിഫണ്ട് നയം)'),
                onTap: () => openRefundPage(context),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: GlobalFeatureShowcase(),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  await mockData.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.pink),
                title: const Text(
                  'വിവാഹം ഉറപ്പിച്ചു / അക്കൗണ്ട് ഇല്ലാതാക്കുക',
                  style: TextStyle(
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Marriage Fixed / Delete Account (Instant deactivation)',
                ),
                onTap: () => _marriageFixedDeleteAccount(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _confirmAndDeleteAccount(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmAndDeleteAccount(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to delete your account.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        DateTime? selectedDob;
        final nameController = TextEditingController();
        final passwordController = TextEditingController();
        bool isSubmitting = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Confirm Account Deletion'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'This action is permanent and cannot be undone. Please verify your details to proceed.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    if (errorMessage != null) ...[
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text(
                        selectedDob == null
                            ? 'Select Date of Birth'
                            : 'DOB: ${selectedDob!.day}/${selectedDob!.month}/${selectedDob!.year}',
                        style: TextStyle(
                          color: selectedDob == null
                              ? Colors.grey.shade600
                              : Colors.black,
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(
                            const Duration(days: 365 * 18),
                          ),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => selectedDob = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (isSubmitting) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final enteredName = nameController.text.trim();
                          final enteredPassword = passwordController.text;

                          if (enteredName.isEmpty ||
                              selectedDob == null ||
                              enteredPassword.isEmpty) {
                            setState(
                              () => errorMessage = 'All fields are required.',
                            );
                            return;
                          }

                          // Capture context states before async operations
                          final navigator = Navigator.of(context);
                          final rootNavigator = Navigator.of(dialogCtx);
                          final messenger = ScaffoldMessenger.of(context);

                          setState(() {
                            isSubmitting = true;
                            errorMessage = null;
                          });

                          try {
                            // 1. Fetch profile data from Supabase
                            final profile = await Supabase.instance.client
                                .from('kurichiyar_profiles')
                                .select('full_name, dob')
                                .eq('id', user.id)
                                .maybeSingle();

                            if (profile == null) {
                              setState(() {
                                isSubmitting = false;
                                errorMessage = 'Profile record not found.';
                              });
                              return;
                            }

                            final dbFullName = (profile['full_name'] as String?)
                                ?.trim();
                            final dbDobStr = profile['dob'] as String?;

                            DateTime? dbDob;
                            if (dbDobStr != null) {
                              dbDob = DateTime.tryParse(dbDobStr);
                            }

                            // Match Full Name (Case-insensitive)
                            if (dbFullName == null ||
                                dbFullName.toLowerCase() !=
                                    enteredName.toLowerCase()) {
                              setState(() {
                                isSubmitting = false;
                                errorMessage =
                                    'Verification failed: Full name does not match.';
                              });
                              return;
                            }

                            // Match DOB
                            if (dbDob == null ||
                                dbDob.year != selectedDob!.year ||
                                dbDob.month != selectedDob!.month ||
                                dbDob.day != selectedDob!.day) {
                              setState(() {
                                isSubmitting = false;
                                errorMessage =
                                    'Verification failed: Date of Birth does not match.';
                              });
                              return;
                            }

                            // 2. Re-authenticate using Password
                            try {
                              await Supabase.instance.client.auth
                                  .signInWithPassword(
                                    email: user.email!,
                                    password: enteredPassword,
                                  );
                            } catch (_) {
                              setState(() {
                                isSubmitting = false;
                                errorMessage =
                                    'Verification failed: Incorrect password.';
                              });
                              return;
                            }

                            // 3. Execute atomic account deletion RPC
                            try {
                              await Supabase.instance.client.rpc(
                                'delete_user_completely',
                                params: {'target_user_id': user.id},
                              );
                            } catch (rpcErr) {
                              debugPrint(
                                'RPC delete_user_completely failed: $rpcErr',
                              );
                            }

                            // 4. Log out and clear state
                            await Supabase.instance.client.auth.signOut();
                            MockData().logout();

                            rootNavigator.pop();
                            navigator.pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const GuestScreen(),
                              ),
                              (route) => false,
                            );
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Your account has been successfully deleted.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } catch (e) {
                            setState(() {
                              isSubmitting = false;
                              errorMessage =
                                  'Error occurred during deletion: $e';
                            });
                          }
                        },
                  child: const Text('Delete Permanently'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _marriageFixedDeleteAccount(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to delete your account.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('വിവാഹം ഉറപ്പിച്ചു / അക്കൗണ്ട് ഇല്ലാതാക്കുക'),
        content: const Text(
          'നിങ്ങളുടെ വിവാഹം ഉറപ്പിച്ചതിൽ ഞങ്ങൾ സന്തോഷിക്കുന്നു! '
          'അക്കൗണ്ട് ഇല്ലാതാക്കിക്കഴിഞ്ഞാൽ നിങ്ങളുടെ പ്രൊഫൈൽ മറ്റുള്ളവർക്ക് ദൃശ്യമാകില്ല, ഒപ്പം എല്ലാ നോട്ടിഫിക്കേഷനുകളും നിർത്തലാക്കും. '
          'ഈ പ്രക്രിയ ഉടൻ തന്നെ നടപ്പിലാക്കാൻ ആഗ്രഹിക്കുന്നുണ്ടോ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('അല്ല (Cancel)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('അതെ, ഇല്ലാതാക്കുക (Confirm)'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      try {
        // Set status to DELETED, deactivate profile, and clear FCM token
        await Supabase.instance.client
            .from('kurichiyar_profiles')
            .update({'status': 'DELETED', 'fcm_token': null})
            .eq('id', user.id);

        // Sign out
        await Supabase.instance.client.auth.signOut();
        MockData().logout();

        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const GuestScreen()),
          (route) => false,
        );

        messenger.showSnackBar(
          const SnackBar(
            content: Text('അക്കൗണ്ട് വിജയകരമായി ഇല്ലാതാക്കി. ആശംസകൾ!'),
            backgroundColor: Colors.pink,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
