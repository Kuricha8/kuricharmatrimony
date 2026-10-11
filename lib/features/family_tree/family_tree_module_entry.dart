import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_page.dart';
import 'family_tree_home_screen.dart';
import 'family_tree_constants.dart';
import 'family_tree_auth_service.dart';
import 'family_registration_screen.dart';

// ==========================================
// 1. എൻട്രി പോയിന്റ് (MAIN GATEWAY SCREEN)
// ==========================================
class FamilyTreeModuleEntry extends StatefulWidget {
  const FamilyTreeModuleEntry({super.key});

  @override
  State<FamilyTreeModuleEntry> createState() => _FamilyTreeModuleEntryState();
}

class _FamilyTreeModuleEntryState extends State<FamilyTreeModuleEntry> {
  Future<DocumentSnapshot>? _memberFuture;
  String? _effectiveUid;
  bool _isCheckingAuth = true;
  StreamSubscription<User?>? _fbAuthSub;

  @override
  void initState() {
    super.initState();
    _resolveAuthSession();
  }

  void _resolveAuthSession() {
    // 1. Check if auth session is already present
    _effectiveUid = getEffectiveUserId();

    if (_effectiveUid != null && _effectiveUid!.isNotEmpty) {
      _loadMemberDoc(_effectiveUid!);
      if (mounted) {
        setState(() => _isCheckingAuth = false);
      }
      return;
    }

    // 2. Listen to FirebaseAuth authStateChanges in case token restoration is in-flight
    try {
      _fbAuthSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (!mounted) return;
        if (user != null && user.uid.isNotEmpty) {
          setState(() {
            _effectiveUid = user.uid;
            _isCheckingAuth = false;
          });
          _loadMemberDoc(user.uid);
        } else {
          final fallbackUid = getEffectiveUserId();
          if (fallbackUid != null && fallbackUid.isNotEmpty) {
            setState(() {
              _effectiveUid = fallbackUid;
              _isCheckingAuth = false;
            });
            _loadMemberDoc(fallbackUid);
          } else {
            setState(() => _isCheckingAuth = false);
          }
        }
      });
    } catch (e) {
      debugPrint('Auth listener notice: ');
      if (mounted) {
        setState(() => _isCheckingAuth = false);
      }
    }

    // Failsafe timeout so user is never stuck on loading
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _isCheckingAuth) {
        final fallbackUid = getEffectiveUserId();
        setState(() {
          _effectiveUid = fallbackUid;
          _isCheckingAuth = false;
        });
        if (fallbackUid != null && fallbackUid.isNotEmpty) {
          _loadMemberDoc(fallbackUid);
        }
      }
    });
  }

  void _loadMemberDoc(String uid) {
    setState(() {
      _memberFuture = FirebaseFirestore.instance
          .collection('ft_members')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));
    });
  }

  void _reload() {
    _effectiveUid = getEffectiveUserId();
    if (_effectiveUid != null && _effectiveUid!.isNotEmpty) {
      _loadMemberDoc(_effectiveUid!);
    } else {
      _resolveAuthSession();
    }
  }

  @override
  void dispose() {
    _fbAuthSub?.cancel();
    super.dispose();
  }

  void _openLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (mounted) {
      _resolveAuthSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Initial Auth Check State - Never show a blank screen!
    if (_isCheckingAuth) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('കുടുംബമാല (Family Tree)'),
          backgroundColor: const Color(0xFF000080),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF000080)),
              SizedBox(height: 16),
              Text(
                'കുടുംബമാല ലോഡ് ചെയ്യുന്നു...',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                'Verifying authenticated session',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Unauthenticated State - Rich UI with Direct Login Action
    if (_effectiveUid == null || _effectiveUid!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('കുടുംബമാല (Family Tree)'),
          backgroundColor: const Color(0xFF000080),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000080).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_outlined,
                    size: 64,
                    color: Color(0xFF000080),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ലോഗിൻ ആവശ്യമാണ് (Login Required)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000080),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'കുടുംബമാല ഫാമിലി ട്രീ വിവരങ്ങൾ കാണുന്നതിനും രജിസ്റ്റർ ചെയ്യുന്നതിനും ദയവായി നിങ്ങളുടെ അക്കൗണ്ടിൽ ലോഗിൻ ചെയ്യുക.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 28),
                GoogleSignInButton(
                  label: 'Google വഴി തുടരുക (Continue with Google)',
                  onPressed: () =>
                      FamilyTreeAuthService.handleContinueWithGoogle(context),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'അല്ലെങ്കിൽ (OR)',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF000080),
                    side: const BorderSide(color: Color(0xFF000080), width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.login, size: 20),
                  onPressed: _openLogin,
                  label: const Text(
                    'ലോഗിൻ ചെയ്യുക (Login with Email/Phone)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('തിരികെ പോകുക (Go Back)', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Authenticated - Stream/Future for Member Document
    return FutureBuilder<DocumentSnapshot>(
      future: _memberFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('കുടുംബമാല'),
              backgroundColor: const Color(0xFF000080),
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF000080)),
                  SizedBox(height: 16),
                  Text('കുടുംബശൃംഖല വിവരങ്ങൾ പരിശോധിക്കുന്നു...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('കുടുംബമാല'),
              backgroundColor: const Color(0xFF000080),
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    const Text(
                      'ഡാറ്റ ലഭ്യമാക്കാൻ സാധിച്ചില്ല',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text('', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000080),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('വീണ്ടും ശ്രമിക്കുക (Retry)'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          final currentUser = FirebaseAuth.instance.currentUser;
          return FamilyRegistrationScreen(
            initialName: currentUser?.displayName,
            initialEmail: currentUser?.email,
            initialPhotoUrl: currentUser?.photoURL,
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final status = data['approval_status'] ?? 'pending';

        if (status == 'rejected') {
          final currentUser = FirebaseAuth.instance.currentUser;
          return FamilyRegistrationScreen(
            rejectionReason: data['rejection_reason']?.toString(),
            initialName: data['full_name'] ?? currentUser?.displayName,
            initialEmail: data['email'] ?? currentUser?.email,
            initialPhotoUrl: data['profile_photo'] ?? currentUser?.photoURL,
          );
        }

        return FamilyTreeHomeScreen(memberData: data);
      },
    );
  }
}
