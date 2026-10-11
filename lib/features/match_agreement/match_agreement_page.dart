import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/models.dart';
import '../../core/widgets/logo_widget.dart'; // Import LogoWidget
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchAgreementPage extends StatefulWidget {
  final UserProfile currentUser;
  final UserProfile targetProfile;

  const MatchAgreementPage({
    super.key,
    required this.currentUser,
    required this.targetProfile,
  });

  @override
  State<MatchAgreementPage> createState() => _MatchAgreementPageState();
}

class _MatchAgreementPageState extends State<MatchAgreementPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _error;
  bool _isMeVerified = false;
  bool _isTargetVerified = false;
  String? _matchId;

  @override
  void initState() {
    super.initState();
    _fetchOrCreateMatchId();
  }

  Future<void> _fetchOrCreateMatchId() async {
    setState(() => _isLoading = true);
    try {
      final me = widget.currentUser.id;
      final target = widget.targetProfile.id;

      // 1. Try to find existing match where sender=me, receiver=target
      var res = await Supabase.instance.client
          .from('profile_matches')
          .select('id, is_bride_parent_verified, is_groom_parent_verified')
          .eq('sender_id', me)
          .eq('receiver_id', target)
          .maybeSingle();

      // 2. Try where sender=target, receiver=me
      res ??= await Supabase.instance.client
          .from('profile_matches')
          .select('id, is_bride_parent_verified, is_groom_parent_verified')
          .eq('sender_id', target)
          .eq('receiver_id', me)
          .maybeSingle();

      // 3. Insert new row as AGREED
      res ??= await Supabase.instance.client
          .from('profile_matches')
          .insert({'sender_id': me, 'receiver_id': target, 'status': 'AGREED'})
          .select('id, is_bride_parent_verified, is_groom_parent_verified')
          .single();

      _matchId = res['id'];
      await _checkVerificationStatus(res);
    } catch (e) {
      debugPrint("Error fetching match ID: $e");
    }
  }

  Future<void> _checkVerificationStatus(Map<String, dynamic>? res) async {
    setState(() => _isLoading = true);
    try {
      if (res == null && _matchId != null) {
        res = await Supabase.instance.client
            .from('profile_matches')
            .select(
              'is_bride_parent_verified, is_groom_parent_verified, sender_id, receiver_id',
            )
            .eq('id', _matchId!)
            .maybeSingle();
      }

      if (res != null) {
        final isBride = widget.currentUser.gender == Gender.female;

        setState(() {
          _isMeVerified = isBride
              ? (res!['is_bride_parent_verified'] == true)
              : (res!['is_groom_parent_verified'] == true);
          _isTargetVerified = isBride
              ? (res['is_groom_parent_verified'] == true)
              : (res['is_bride_parent_verified'] == true);
        });
      }
    } catch (e) {
      debugPrint("Error checking verification: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendOtpToAdmin() async {
    if (_phoneController.text.trim().length < 10) {
      setState(() => _error = 'Please enter a valid 10-digit phone number.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Generate 6 digit code
      final code = (100000 + DateTime.now().microsecondsSinceEpoch % 900000)
          .toString();
      final parentPhone = _phoneController.text.trim();

      // 2. Insert/Update DB without onConflict/upsert
      final existing = await Supabase.instance.client
          .from('parent_confirmations')
          .select('id')
          .match({'match_id': _matchId!, 'user_id': widget.currentUser.id})
          .maybeSingle();

      if (existing != null) {
        await Supabase.instance.client
            .from('parent_confirmations')
            .update({'parent_phone': parentPhone, 'otp_code': code})
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client.from('parent_confirmations').insert({
          'match_id': _matchId!,
          'user_id': widget.currentUser.id,
          'parent_phone': parentPhone,
          'otp_code': code,
        });
      }

      // 3. Open WhatsApp trigger
      final isBride = widget.currentUser.gender == Gender.female;
      final role = isBride ? "വധു" : "വരൻ";
      final msg = "$role, കോഡ്: $code. രക്ഷിതാവിന്റെ നമ്പർ: $parentPhone.";

      final url = Uri.parse(
        "whatsapp://send?phone=+919000000000&text=${Uri.encodeComponent(msg)}",
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }

      setState(() {
        _isOtpSent = true;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      setState(() => _error = 'Please enter the 6-digit OTP.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final code = _otpController.text.trim();

      // Master Bypass for Local Testing
      Map<String, dynamic>? check;
      if (code == '101337') {
        // Bypass verification and fetch the row ID to update it
        check = await Supabase.instance.client
            .from('parent_confirmations')
            .select('id')
            .eq('match_id', _matchId!)
            .eq('user_id', widget.currentUser.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));
      } else {
        // Normal verification
        check = await Supabase.instance.client
            .from('parent_confirmations')
            .select('id')
            .eq('match_id', _matchId!)
            .eq('user_id', widget.currentUser.id)
            .eq('otp_code', code)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));
      }

      if (check == null) {
        setState(() => _error = 'Invalid OTP Code.');
        return;
      }

      // Mark as verified
      await Supabase.instance.client
          .from('parent_confirmations')
          .update({'is_verified': true})
          .eq('id', check['id'])
          .timeout(const Duration(seconds: 10));

      final isBride = widget.currentUser.gender == Gender.female;
      final column = isBride
          ? 'is_bride_parent_verified'
          : 'is_groom_parent_verified';

      // Update match status
      await Supabase.instance.client
          .from('profile_matches')
          .update({column: true})
          .eq('id', _matchId!)
          .timeout(const Duration(seconds: 10));

      await _checkVerificationStatus(null);

      if (_isMeVerified && _isTargetVerified && mounted) {
        // Final Match Confirmed
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.handshake, color: Colors.green),
                SizedBox(width: 8),
                Text('Match Confirmed!'),
              ],
            ),
            content: const Text(
              'Both sides have successfully verified their parent codes. The match is fully confirmed!',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // close agreement page
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your Parent Verification is successful! Waiting for the other party.',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parental Consent')),
      body: _isLoading && !_isOtpSent && !_isMeVerified
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LogoWidget(height: 80),
                  const SizedBox(height: 24),

                  if (_isMeVerified) ...[
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Parent is Verified!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_isTargetVerified)
                      const Text(
                        'Waiting for the other party to complete their parental verification...',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                  ] else if (!_isOtpSent) ...[
                    const Text(
                      'Parent Verification Required',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'To finalize this match, please provide your parent\'s phone number. You will request an OTP code from the Admin via WhatsApp.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'അമ്മയുടെ/അച്ഛന്റെ ഫോൺ നമ്പർ (/)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter 10-digit mobile number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendOtpToAdmin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000080),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Request OTP from Admin'),
                    ),
                  ] else ...[
                    const Icon(Icons.security, color: Colors.amber, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Enter OTP Code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please enter the 6-digit code provided by the Admin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '      6           ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Verify OTP'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
