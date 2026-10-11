import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/consent_service.dart';
import '../../core/services/legal_service.dart';
import '../../core/utils/legal_strings.dart';
import '../../core/utils/mock_data.dart';
import 'package:kurichiyar_matrimony/l10n/app_localizations.dart';

class TermsAndConditionsPage extends StatefulWidget {
  final VoidCallback? onAgreed;

  const TermsAndConditionsPage({super.key, this.onAgreed});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  bool _isChecked = false;
  bool _isLoading = false;
  final _legalService = LegalService();
  late Future<List<LegalSection>> _sectionsFuture;

  Future<Map<String, String>> _resolveUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = MockData().currentUser;
    final fbUser = FirebaseAuth.instance.currentUser;
    final sbUser = Supabase.instance.client.auth.currentUser;

    // Resolve user ID
    String userId = '';
    if (fbUser != null && fbUser.uid.isNotEmpty) {
      userId = fbUser.uid;
    } else if (sbUser != null && sbUser.id.isNotEmpty) {
      userId = sbUser.id;
    } else if (currentUser != null && currentUser.id.isNotEmpty) {
      userId = currentUser.id;
    } else {
      userId = prefs.getString('user_id') ??
          prefs.getString('uid') ??
          '';
    }

    // Resolve phone
    String userPhone = '';
    if (fbUser?.phoneNumber?.isNotEmpty == true) {
      userPhone = fbUser!.phoneNumber!;
    } else if (currentUser?.guardianPhone?.isNotEmpty == true) {
      userPhone = currentUser!.guardianPhone!;
    } else if (sbUser?.phone?.isNotEmpty == true) {
      userPhone = sbUser!.phone!;
    } else {
      userPhone = sbUser?.userMetadata?['phone']?.toString() ??
          prefs.getString('user_phone') ??
          prefs.getString('phone') ??
          '';
    }

    if (userId.isEmpty) {
      userId = userPhone.isNotEmpty
          ? userPhone
          : 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Resolve user name
    String userName = '';
    if (currentUser != null &&
        currentUser.name.isNotEmpty &&
        currentUser.name != 'Anonymous') {
      userName = currentUser.name;
    } else if (fbUser?.displayName?.isNotEmpty == true) {
      userName = fbUser!.displayName!;
    } else if (sbUser?.userMetadata?['name'] != null) {
      userName = sbUser!.userMetadata!['name'].toString();
    } else {
      userName = prefs.getString('user_name') ?? 'Anonymous/New User';
    }

    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final langCode = Localizations.localeOf(context).languageCode;
    _sectionsFuture = _legalService.fetchLegalSections('terms', langCode);
  }

  void _showTermsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              AppBar(
                title: const Text('Terms & Conditions'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: FutureBuilder<List<LegalSection>>(
                    future: _sectionsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final sections = snapshot.data ?? [];
                      if (sections.isEmpty) {
                        return const Center(
                          child: Text('No information available.'),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...sections.map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.heading,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF000080),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    s.body,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isChecked = true;
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000080),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'I Agree',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: FutureBuilder<List<LegalSection>>(
                  future: _sectionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final sections = snapshot.data ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome to Kurichiyar Matrimony',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000080),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'By installing and using this application, you agree to comply with and be bound by the following terms and conditions:',
                          style: TextStyle(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'നിരാകരണം (Disclaimer)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                "ഈ പ്ലാറ്റ്ഫോം മാട്രിമോണി സേവനങ്ങൾ ലഭ്യമാക്കുന്ന ഒരു മധ്യസ്ഥൻ മാത്രമാണ്. ഇവിടെ നൽകിയിരിക്കുന്ന പ്രീമിയം സബ്സ്ക്രിപ്ഷൻ പ്രൊഫൈലുകൾ തിരയാനും, അവരുമായി ആശയവിനിമയം നടത്താനുമുള്ള സൗകര്യം മാത്രമാണ്. വിവാഹം നടക്കുമെന്നോ, അനുയോജ്യമായ പങ്കാളിയെ ഉറപ്പായി കണ്ടെത്താമെന്നോ ഉള്ള യാതൊരു ഗ്യാരണ്ടിയും ഈ പ്ലാറ്റ്ഫോം നൽകുന്നില്ല. അംഗങ്ങളുടെ വ്യക്തിഗത വിവരങ്ങളുടെ ആധികാരികത പരിശോധിക്കേണ്ടത് അവരവരുടെ ഉത്തരവാദിത്തമാണ്. പേയ്മെന്റ് നടത്തുന്നതിന് മുൻപ് ഞങ്ങളുടെ പൂർണ്ണമായ 'Terms & Conditions' വായിച്ചു മനസ്സിലാക്കുക.",
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...sections.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.heading,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF000080),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  s.body,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.6,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _isChecked,
                        activeColor: const Color(0xFF000080),
                        onChanged: (val) {
                          debugPrint('[TermsAndConditionsPage] Checkbox toggled: $val');
                          setState(() {
                            _isChecked = val ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            debugPrint('[TermsAndConditionsPage] Label row tapped -> toggling checkbox');
                            setState(() {
                              _isChecked = !_isChecked;
                            });
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.termsAndConditions,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        color: Color(0xFF000080),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      debugPrint('[TermsAndConditionsPage] Opening terms bottom sheet');
                                      _showTermsBottomSheet(context);
                                    },
                                    child: const Text(
                                      '(വായിക്കുക / View)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF000080),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.termsAndConditionsMl,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.termsAndConditionsEn,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      debugPrint(
                        '[TermsAndConditionsPage] "Agree & Proceed" tapped! _isChecked: $_isChecked, _isLoading: $_isLoading',
                      );

                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      if (!_isChecked) {
                        debugPrint(
                          '[TermsAndConditionsPage] Checkbox is NOT ticked. Showing warning snackbar.',
                        );
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'ദയവായി നിബന്ധനകൾ അംഗീകരിച്ച് ചെക്ക്ബോക്സ് ടിക്ക് ചെയ്യുക (Please tick the checkbox to agree to Terms & Conditions)',
                            ),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      if (_isLoading) {
                        debugPrint(
                          '[TermsAndConditionsPage] Already processing, skipping duplicate tap.',
                        );
                        return;
                      }

                      setState(() => _isLoading = true);

                      // 1. Resolve user profile details
                      final userInfo = await _resolveUserInfo();
                      final userId = userInfo['userId']!;
                      final userName = userInfo['userName']!;
                      final userPhone = userInfo['userPhone']!;
                      final docId = (userId.isNotEmpty && !userId.startsWith('anonymous_'))
                          ? userId
                          : (userPhone.isNotEmpty ? userPhone : userId);

                      debugPrint(
                        '[TermsAndConditionsPage] User resolved: docId=$docId, userId=$userId, name=$userName, phone=$userPhone',
                      );

                      // 2. Immediately persist local consent in SharedPreferences so progress is never lost
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('hasAgreedTerms', true);
                        await prefs.setBool('has_accepted_terms', true);
                        debugPrint(
                          '[TermsAndConditionsPage] Successfully saved hasAgreedTerms=true to SharedPreferences.',
                        );
                      } catch (e) {
                        debugPrint(
                          '[TermsAndConditionsPage] SharedPreferences save error: $e',
                        );
                      }

                      // 3. SAVE AGREEMENT TO FIRESTORE: collection `terms_agreements`
                      try {
                        final agreementData = {
                          'user_id': userId,
                          'user_name': userName,
                          'user_phone': userPhone,
                          'agreed': true,
                          'agreed_at': FieldValue.serverTimestamp(),
                        };

                        unawaited(
                          FirebaseFirestore.instance
                              .collection('terms_agreements')
                              .doc(docId)
                              .set(agreementData, SetOptions(merge: true))
                              .then((_) {
                            debugPrint(
                              '[TermsAndConditionsPage] Successfully recorded agreement in Firestore "terms_agreements" for $docId',
                            );
                          }).catchError((e) {
                            debugPrint(
                              '[TermsAndConditionsPage] Error saving to terms_agreements: $e',
                            );
                          }),
                        );
                      } catch (e) {
                        debugPrint(
                          '[TermsAndConditionsPage] Firestore terms_agreements error: $e',
                        );
                      }

                      // 4. ALSO UPDATE USER'S DOCUMENT IN `users` COLLECTION: has_accepted_terms: true
                      try {
                        unawaited(
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(docId)
                              .set({
                            'has_accepted_terms': true,
                            'terms_accepted': true,
                            'terms_accepted_at': FieldValue.serverTimestamp(),
                            'updated_at': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true))
                              .then((_) {
                            debugPrint(
                              '[TermsAndConditionsPage] Successfully updated "users" collection (has_accepted_terms: true) for $docId',
                            );
                          }).catchError((e) {
                            debugPrint(
                              '[TermsAndConditionsPage] Error updating users collection: $e',
                            );
                          }),
                        );
                      } catch (e) {
                        debugPrint(
                          '[TermsAndConditionsPage] Firestore users collection error: $e',
                        );
                      }

                      // 5. Fire-and-forget background updates (Supabase & ConsentService)
                      try {
                        final sbUser =
                            Supabase.instance.client.auth.currentUser;
                        if (sbUser != null) {
                          unawaited(
                            Supabase.instance.client
                                .from('kurichiyar_profiles')
                                .update({
                                  'terms_accepted': true,
                                  'updated_at':
                                      DateTime.now().toIso8601String(),
                                })
                                .eq('id', sbUser.id)
                                .timeout(const Duration(seconds: 3))
                                .then(
                                  (_) => debugPrint(
                                    '[TermsAndConditionsPage] Supabase profile terms_accepted updated.',
                                  ),
                                )
                                .catchError(
                                  (e) => debugPrint(
                                    '[TermsAndConditionsPage] Supabase update warning: $e',
                                  ),
                                ),
                          );
                        }
                      } catch (e) {
                        debugPrint(
                          '[TermsAndConditionsPage] Supabase sync caught: $e',
                        );
                      }

                      try {
                        unawaited(
                          ConsentService.captureConsent()
                              .then(
                                (_) => debugPrint(
                                  '[TermsAndConditionsPage] ConsentService captured successfully.',
                                ),
                              )
                              .catchError(
                                (e) => debugPrint(
                                  '[TermsAndConditionsPage] ConsentService capture warning: $e',
                                ),
                              ),
                        );
                      } catch (e) {
                        debugPrint(
                          '[TermsAndConditionsPage] ConsentService caught: $e',
                        );
                      }

                      // 6. TRIGGER IMMEDIATE SMOOTH NAVIGATION TO DASHBOARD/HOME
                      debugPrint(
                        '[TermsAndConditionsPage] Triggering immediate smooth navigation...',
                      );
                      if (widget.onAgreed != null) {
                        debugPrint(
                          '[TermsAndConditionsPage] Executing widget.onAgreed()...',
                        );
                        widget.onAgreed!();
                      }

                      if (!mounted) return;

                      if (navigator.canPop()) {
                        debugPrint(
                          '[TermsAndConditionsPage] Navigating via navigator.pop(true)',
                        );
                        navigator.pop(true);
                      } else if (widget.onAgreed == null) {
                        debugPrint(
                          '[TermsAndConditionsPage] Navigating to Dashboard via navigator.pushReplacementNamed("/dashboard")',
                        );
                        navigator.pushReplacementNamed('/dashboard');
                      }

                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isChecked
                          ? const Color(0xFF000080)
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Agree & Proceed',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
