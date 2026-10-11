import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpService {
  static final OtpService instance = OtpService._internal();
  OtpService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  String generateAlphanumericOTP() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<bool> autoGenerateOTPs(List<Map<String, dynamic>> profiles) async {
    bool anyGenerated = false;
    for (var profile in profiles) {
      bool needsNewOtp = false;
      final existingOtp =
          profile['admin_otp'] ??
          profile['whatsapp_otp'] ??
          profile['verification_otp'];
      if (existingOtp == null || existingOtp.toString().isEmpty) {
        needsNewOtp = true;
      } else {
        final generatedAtRaw =
            (profile['admin_otp_generated_at'] ?? profile['otp_generated_at'])
                as String?;
        if (generatedAtRaw != null) {
          final generatedAt = DateTime.tryParse(generatedAtRaw);
          if (generatedAt != null &&
              DateTime.now().toUtc().difference(generatedAt.toUtc()).inHours >=
                  48) {
            needsNewOtp = true;
          }
        }
      }

      if (needsNewOtp) {
        final newOtp = generateAlphanumericOTP();
        anyGenerated = true;
        final nowIso = DateTime.now().toUtc().toIso8601String();
        await _supabase
            .from('kurichiyar_profiles')
            .update({
              'admin_otp': newOtp,
              'whatsapp_otp': newOtp,
              'verification_otp': newOtp,
              'admin_otp_generated_at': nowIso,
              'otp_generated_at': nowIso,
            })
            .eq('id', profile['id']);
      }
    }
    return anyGenerated;
  }

  Future<void> verifyOtp(
    String userId,
    String enteredOtp, {
    bool setLiveStatus = false,
  }) async {
    final cleanOtp = enteredOtp.trim().toUpperCase();
    if (cleanOtp.isEmpty) {
      throw 'Please enter the OTP code.';
    }

    final response = await _supabase
        .from('kurichiyar_profiles')
        .select(
          'id, admin_otp, whatsapp_otp, verification_otp, admin_otp_generated_at, otp_generated_at',
        )
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      throw 'Profile not found. Please try again later.';
    }

    final adminOtp = (response['admin_otp']?.toString())?.trim().toUpperCase();
    final whatsappOtp = (response['whatsapp_otp']?.toString())
        ?.trim()
        .toUpperCase();
    final verifOtp = (response['verification_otp']?.toString())
        ?.trim()
        .toUpperCase();

    final validOtps = <String>{
      if (adminOtp != null && adminOtp.isNotEmpty) adminOtp,
      if (whatsappOtp != null && whatsappOtp.isNotEmpty) whatsappOtp,
      if (verifOtp != null && verifOtp.isNotEmpty) verifOtp,
    };

    final generatedAtRaw =
        (response['admin_otp_generated_at'] ?? response['otp_generated_at'])
            as String?;

    if (cleanOtp != '101337') {
      if (validOtps.isNotEmpty && !validOtps.contains(cleanOtp)) {
        throw 'Incorrect OTP code. Please check the code and try again.';
      }

      if (generatedAtRaw != null) {
        final generatedAt = DateTime.tryParse(generatedAtRaw);
        if (generatedAt != null) {
          final hoursDiff = DateTime.now()
              .toUtc()
              .difference(generatedAt.toUtc())
              .inHours;
          if (hoursDiff >= 48) {
            throw 'Your OTP has expired (valid for 48 hours). Please request a new one.';
          }
        }
      }
    }

    // OTP matches (or is 101337 master code), update status across all status columns
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final updateData = <String, dynamic>{
      'approval_status': 'Approved',
      'status': 'live',
      'account_status': 'active',
      'registration_status': 'live',
      'is_verified': true,
      'app_screen_override': 'main_screen',
      'current_screen': 'main_screen',
      'admin_otp_generated_at': nowIso,
      'otp_generated_at': nowIso,
    };

    await _supabase
        .from('kurichiyar_profiles')
        .update(updateData)
        .eq('id', userId);

    try {
      await _supabase
          .from('kurichiyar_profiles')
          .update({'verification_otp': null})
          .eq('id', userId);
    } catch (_) {}
  }

  Future<void> verifyOtpWithLookup(
    String? identifier,
    String enteredOtp, {
    bool setLiveStatus = false,
  }) async {
    final cleanOtp = enteredOtp.trim().toUpperCase();
    if (cleanOtp.isEmpty) {
      throw 'Please enter the OTP code.';
    }

    Map<String, dynamic>? targetProfile;

    // 1. Try lookup by identifier (ID or Phone) if provided
    if (identifier != null && identifier.trim().isNotEmpty) {
      final cleanId = identifier.trim();
      try {
        targetProfile = await _supabase
            .from('kurichiyar_profiles')
            .select(
              'id, admin_otp, whatsapp_otp, verification_otp, admin_otp_generated_at, otp_generated_at',
            )
            .eq('id', cleanId)
            .maybeSingle();
      } catch (_) {}

      if (targetProfile == null) {
        try {
          targetProfile = await _supabase
              .from('kurichiyar_profiles')
              .select(
                'id, admin_otp, whatsapp_otp, verification_otp, admin_otp_generated_at, otp_generated_at',
              )
              .or(
                'phone.eq.$cleanId,guardian_phone.eq.$cleanId,public_display_number.eq.$cleanId',
              )
              .maybeSingle();
        } catch (_) {}
      }
    }

    // 2. Try authenticated user profile as target
    if (targetProfile == null) {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        try {
          targetProfile = await _supabase
              .from('kurichiyar_profiles')
              .select(
                'id, admin_otp, whatsapp_otp, verification_otp, admin_otp_generated_at, otp_generated_at',
              )
              .eq('id', currentUser.id)
              .maybeSingle();
        } catch (_) {}
      }
    }

    // 3. Direct query on admin_otp column (exact & case-insensitive)
    if (targetProfile == null) {
      try {
        final matches = await _supabase
            .from('kurichiyar_profiles')
            .select(
              'id, admin_otp, whatsapp_otp, verification_otp, admin_otp_generated_at, otp_generated_at',
            )
            .or(
              'admin_otp.ilike.$cleanOtp,whatsapp_otp.ilike.$cleanOtp,verification_otp.ilike.$cleanOtp',
            )
            .limit(1);
        if (matches.isNotEmpty) {
          targetProfile = matches.first;
        }
      } catch (_) {}
    }

    // 4. Master Test OTP '101337' fallback
    if (targetProfile == null && cleanOtp == '101337') {
      try {
        final pendingMatches = await _supabase
            .from('kurichiyar_profiles')
            .select(
              'id, admin_otp, whatsapp_otp, verification_otp, admin_otp_generated_at, otp_generated_at',
            )
            .or(
              'status.eq.pending,approval_status.eq.PENDING,approval_status.eq.Pending',
            )
            .order('id', ascending: false)
            .limit(1);
        if (pendingMatches.isNotEmpty) {
          targetProfile = pendingMatches.first;
        }
      } catch (_) {}
    }

    if (targetProfile == null) {
      throw 'No profile matching this OTP code ($cleanOtp) was found. Please check your code or contact an admin.';
    }

    final targetUserId = targetProfile['id'] as String;
    await verifyOtp(targetUserId, cleanOtp, setLiveStatus: setLiveStatus);
  }
}
