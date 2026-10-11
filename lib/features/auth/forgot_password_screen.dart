import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _stage = 0;
  bool _isLoading = false;

  // Stage 1 Fields
  final _phoneController = TextEditingController();
  DateTime? _dob;
  bool _whatsappConsent = false;

  // Stage 2 Fields
  final _otpController = TextEditingController();

  // Stage 3 Fields
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _verifyIdentityAndSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || _dob == null) {
      _showError('Please enter phone number and select Date of Birth.');
      return;
    }
    if (!_whatsappConsent) {
      _showError('You must consent to receive the OTP via WhatsApp.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Verify profile exists
      final dobStr =
          "${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}";
      final match = await Supabase.instance.client
          .from('kurichiyar_profiles')
          .select('id')
          .or('guardian_phone.eq.$phone,public_display_number.eq.$phone')
          .eq('dob', dobStr)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (match == null) {
        _showError('No matching profile found with this Phone Number and DOB.');
        setState(() => _isLoading = false);
        return;
      }

      // 2. Generate Custom OTP & Update Database
      final otp = (100000 + math.Random().nextInt(900000)).toString();
      await Supabase.instance.client
          .from('kurichiyar_profiles')
          .update({
            'whatsapp_otp': otp,
            'otp_generated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', match['id'])
          .timeout(const Duration(seconds: 10));

      _showSuccess('OTP generated via WhatsApp! (Testing OTP: $otp)');
      setState(() => _stage = 1);
    } catch (e) {
      _showError('Error sending OTP. Network may be unreachable: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    final phone = _phoneController.text.trim();
    if (otp.isEmpty) {
      _showError('Please enter the OTP.');
      return;
    }

    // --- Master Bypass for Local Testing ---
    if (otp == '101337') {
      _showSuccess('Bypass OTP Verified (Local Testing)!');
      setState(() => _stage = 2);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final match = await Supabase.instance.client
          .from('kurichiyar_profiles')
          .select('whatsapp_otp, otp_generated_at')
          .or('guardian_phone.eq.$phone,public_display_number.eq.$phone')
          .maybeSingle()
          .timeout(const Duration(seconds: 10)); // Timeout protection

      if (match == null || match['whatsapp_otp'] != otp) {
        _showError('Invalid OTP.');
        setState(() => _isLoading = false);
        return;
      }

      final generatedAt = DateTime.parse(match['otp_generated_at']);
      if (DateTime.now().difference(generatedAt).inHours >= 24) {
        _showError(
          'This OTP has expired (Valid for 24 hours only). Please request a new one.',
        );
        setState(() {
          _stage = 0;
          _isLoading = false;
        });
        return;
      }

      _showSuccess('OTP Verified!');
      setState(() => _stage = 2);
    } catch (e) {
      _showError(
        'OTP Service unavailable right now: $e. Try the bypass code during testing.',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    final pass = _newPasswordController.text;
    final conf = _confirmPasswordController.text;
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (pass.isEmpty || pass.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (pass != conf) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .rpc(
            'reset_password_with_custom_otp',
            params: {'p_phone': phone, 'p_otp': otp, 'p_new_password': pass},
          )
          .timeout(const Duration(seconds: 10));
      _showSuccess('Password updated successfully!');
      if (mounted) Navigator.pop(context);
    } on PostgrestException catch (pe) {
      _showError(
        pe.message,
      ); // Will show "OTP Expired" or "Invalid OTP" from the RPC
    } catch (e) {
      _showError('Failed to update password: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI Builders ---
  Widget _buildStage1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Verify Your Identity',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Registered Phone Number',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() => _dob = date);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date of Birth',
              border: OutlineInputBorder(),
            ),
            child: Text(
              _dob == null
                  ? 'Select DOB'
                  : "${_dob!.day}/${_dob!.month}/${_dob!.year}",
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _whatsappConsent,
              onChanged: (val) =>
                  setState(() => _whatsappConsent = val ?? false),
              activeColor: Colors.green,
            ),
            const Icon(Icons.wechat, color: Colors.green),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Send OTP via WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: (_isLoading || !_whatsappConsent)
              ? null
              : _verifyIdentityAndSendOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF000080),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Send OTP'),
        ),
      ],
    );
  }

  Widget _buildStage2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Verify OTP',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text('Enter the 6-digit code sent to your WhatsApp.'),
        const SizedBox(height: 16),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF000080),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Verify OTP'),
        ),
      ],
    );
  }

  Widget _buildStage3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Create New Password',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Confirm Password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _updatePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF000080),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Update Password'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _stage == 0
                    ? _buildStage1()
                    : (_stage == 1 ? _buildStage2() : _buildStage3()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
