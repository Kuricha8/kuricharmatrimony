import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../otp_verification/services/otp_service.dart';
import '../auth_splash/guest_page.dart';
import 'widgets/verification_pending_screen.dart';

import 'package:kurichiyar_matrimony/core/widgets/interstitial_ad_manager.dart';
import 'package:kurichiyar_matrimony/core/widgets/ad_banner_widget.dart';

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  StreamSubscription? _streamSubscription;
  StreamSubscription? _firestoreSubscription;
  Timer? _pollingTimer;
  Map<String, dynamic>? _profile;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initRealtimeStream();
    // Show interstitial ad after a slight delay (Mobile only)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        InterstitialAdManager().showAdIfAvailable(onComplete: () {});
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _streamSubscription?.cancel();
    _firestoreSubscription?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _initRealtimeStream() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User not found';
      });
      return;
    }

    // 1. Realtime Firestore listener (Primary)
    _firestoreSubscription?.cancel();
    try {
      _firestoreSubscription = FirebaseFirestore.instance
          .collection('kurichiyar_profiles')
          .doc(currentUserId)
          .snapshots()
          .listen((doc) {
            if (doc.exists && doc.data() != null && mounted) {
              final profile = doc.data();
              setState(() {
                _profile = profile;
                _errorMessage = null;
                _isLoading = false;
              });
              _checkAutoTransition(profile);
            }
          });
    } catch (e) {
      debugPrint('WaitingScreen Firestore stream error: $e');
    }

    // 2. Realtime Supabase listener (Secondary fallback)
    _streamSubscription?.cancel();
    try {
      _streamSubscription = Supabase.instance.client
          .from('kurichiyar_profiles')
          .stream(primaryKey: ['id'])
          .eq('id', currentUserId)
          .listen(
            (data) {
              if (mounted) {
                final profile = data.isNotEmpty ? data.first : null;
                if (profile != null) {
                  setState(() {
                    _profile = profile;
                    _errorMessage = null;
                    _isLoading = false;
                  });
                  _checkAutoTransition(profile);
                }
              }
            },
            onError: (err) {
              debugPrint(
                'WaitingScreen Realtime stream failed, falling back to Future polling: $err',
              );
              _streamSubscription?.cancel();
              _streamSubscription = null;
              _startPollingFallback(currentUserId);
            },
            cancelOnError: true,
          );
    } catch (sbErr) {
      debugPrint('WaitingScreen Supabase stream error: $sbErr');
      _startPollingFallback(currentUserId);
    }
  }

  void _startPollingFallback(String currentUserId) {
    _pollingTimer?.cancel();
    _fetchProfileOnce(currentUserId);
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _fetchProfileOnce(currentUserId);
    });
  }

  void _checkAutoTransition(Map<String, dynamic>? profile) {
    if (profile == null || !mounted) return;

    final overrideScreen =
        (profile['app_screen_override'] ?? profile['current_screen'])
            ?.toString()
            .toLowerCase();
    if (overrideScreen == 'guest_page') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const GuestScreen(isForced: true),
            ),
            (route) => false,
          );
        }
      });
      return;
    } else if (overrideScreen == 'pending_screen') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const VerificationPendingScreen(),
            ),
            (route) => false,
          );
        }
      });
      return;
    } else if (overrideScreen == 'main_screen') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      });
      return;
    }

    final statusUpper = profile['status']?.toString().toUpperCase();
    final approvalStatusUpper = profile['approval_status']
        ?.toString()
        .toUpperCase();
    final accountStatusUpper = profile['account_status']
        ?.toString()
        .toUpperCase();
    final regStatusUpper = profile['registration_status']
        ?.toString()
        .toUpperCase();

    if (statusUpper == 'APPROVED' ||
        statusUpper == 'LIVE' ||
        approvalStatusUpper == 'APPROVED' ||
        approvalStatusUpper == 'LIVE' ||
        accountStatusUpper == 'APPROVED' ||
        accountStatusUpper == 'LIVE' ||
        regStatusUpper == 'LIVE') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      });
    }
  }

  Future<void> _fetchProfileOnce(String currentUserId) async {
    try {
      Map<String, dynamic>? res;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('kurichiyar_profiles')
            .doc(currentUserId)
            .get();
        if (doc.exists && doc.data() != null) {
          res = doc.data();
        }
      } catch (e) {
        debugPrint('Firestore fetch kurichiyar_profiles once notice: $e');
      }

      if (res == null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();
          if (doc.exists && doc.data() != null) {
            res = doc.data();
          }
        } catch (e) {
          debugPrint('Firestore fetch users once notice: $e');
        }
      }

      if (res == null) {
        try {
          res = await Supabase.instance.client
              .from('kurichiyar_profiles')
              .select()
              .eq('id', currentUserId)
              .maybeSingle();
        } catch (sbErr) {
          debugPrint('Supabase fetch profile once notice: $sbErr');
        }
      }
      if (mounted) {
        setState(() {
          _profile = res;
          _errorMessage = null;
          _isLoading = false;
        });
        _checkAutoTransition(res);
      }
    } catch (e) {
      debugPrint('WaitingScreen Polling fallback failed: $e');
      if (mounted && _profile == null) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _verifyOtp(String currentUserId, Map<String, dynamic> profile) async {
    setState(() {
      _isVerifying = true;
    });

    String enteredOtp = _otpController.text.trim();
    try {
      await OtpService.instance.verifyOtp(
        currentUserId,
        enteredOtp,
        setLiveStatus: true,
      );

      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account verified successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('User not found. Please log in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Under Review'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Ad Banner (Web + Mobile)
            const AdBannerWidget(),

            Expanded(
              child: Builder(
                builder: (context) {
                  if (_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_errorMessage != null && _profile == null) {
                    return Center(child: Text('Error: $_errorMessage'));
                  }
                  if (_profile == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final profile = _profile!;
                  _checkAutoTransition(profile);

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.pending_actions,
                            size: 80,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'പരിശോധന പുരോഗമിക്കുന്നു, ദയവായി കാത്തിരിക്കുക...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your profile is currently under review. Please enter the verification OTP provided by the Admin to unlock your account, or wait for the Admin to approve it.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 32),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _otpController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Enter Admin OTP',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.lock_outline),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _isVerifying
                                        ? null
                                        : () => _verifyOtp(
                                            currentUserId,
                                            profile,
                                          ),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(
                                        double.infinity,
                                        50,
                                      ),
                                    ),
                                    child: _isVerifying
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : const Text(
                                            'Verify OTP',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Ad Banner (Web + Mobile)
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }
}
