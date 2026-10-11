import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../utils/mock_data.dart';
import '../services/notification_manager.dart';

enum InterestStatus { none, iSent, theySent, mutual }

class UnifiedInterestButton extends StatefulWidget {
  final UserProfile targetProfile;
  final Function(InterestStatus newStatus)? onStateChanged;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;

  const UnifiedInterestButton({
    super.key,
    required this.targetProfile,
    this.onStateChanged,
    this.fullWidth = true,
    this.padding,
  });

  @override
  State<UnifiedInterestButton> createState() => _UnifiedInterestButtonState();
}

class _UnifiedInterestButtonState extends State<UnifiedInterestButton> {
  bool _loading = true;
  InterestStatus _status = InterestStatus.none;
  bool _isConfirmingInterest = false;
  Timer? _confirmResetTimer;

  @override
  void initState() {
    super.initState();
    _fetchInterestStatus();
  }

  @override
  void didUpdateWidget(covariant UnifiedInterestButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetProfile.id != widget.targetProfile.id) {
      _isConfirmingInterest = false;
      _fetchInterestStatus();
    }
  }

  @override
  void dispose() {
    _confirmResetTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchInterestStatus() async {
    final me = MockData().currentUser;
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? me?.id;
    if (currentUserId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final targetId = widget.targetProfile.id;

    try {
      // 1. Try new RPC
      final response = await Supabase.instance.client.rpc(
        'get_interest_relationship_status',
        params: {'target_user_id': targetId},
      );

      final String statusStr = response?.toString() ?? 'NONE';
      if (mounted) {
        setState(() {
          _status = _parseStatusString(statusStr);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint(
        '[RPC Note] get_interest_relationship_status RPC fallback: $e',
      );
      // Fallback query if RPC does not exist on Supabase instance
      _fallbackFetchStatus(currentUserId, targetId);
    }
  }

  InterestStatus _parseStatusString(String str) {
    switch (str.toUpperCase()) {
      case 'I_SENT':
        return InterestStatus.iSent;
      case 'THEY_SENT':
        return InterestStatus.theySent;
      case 'MUTUAL':
        return InterestStatus.mutual;
      case 'NONE':
      default:
        return InterestStatus.none;
    }
  }

  Future<void> _fallbackFetchStatus(
    String currentUserId,
    String targetId,
  ) async {
    try {
      final List res = await Supabase.instance.client
          .from('profile_interests')
          .select('sender_id, receiver_id, status')
          .or(
            'and(sender_id.eq.$currentUserId,receiver_id.eq.$targetId),and(sender_id.eq.$targetId,receiver_id.eq.$currentUserId)',
          );

      InterestStatus determinedStatus = InterestStatus.none;

      if (res.isNotEmpty) {
        final rows = res;
        bool meSent = false;
        bool targetSent = false;
        bool isMutualAccepted = false;

        for (var row in rows) {
          final String statusStr = row['status'] as String? ?? 'pending';
          final String senderId = row['sender_id'] as String;

          if (statusStr == 'mutual_accepted' || statusStr == 'accepted') {
            isMutualAccepted = true;
          }
          if (senderId == currentUserId) meSent = true;
          if (senderId == targetId) targetSent = true;
        }

        if (isMutualAccepted || (meSent && targetSent)) {
          determinedStatus = InterestStatus.mutual;
        } else if (targetSent) {
          determinedStatus = InterestStatus.theySent;
        } else if (meSent) {
          determinedStatus = InterestStatus.iSent;
        }
      }

      if (mounted) {
        setState(() {
          _status = determinedStatus;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Fallback status query error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getAgeDiffString() {
    final me = MockData().currentUser;
    if (me == null) return '';
    final myAge = me.age;
    final targetAge = widget.targetProfile.age;
    final diff = (targetAge - myAge).abs();

    if (diff == 0) {
      return 'ഒരേ വയസ്സ് (Same Age)';
    }

    final String relStr = targetAge > myAge
        ? 'മൂത്തയാൾ (Older)'
        : 'ഇളയയാൾ (Younger)';
    return '$diff വയസ്സ് വ്യത്യാസം ($diff Years $relStr)';
  }

  Future<void> _handleToggle() async {
    final me = MockData().currentUser;
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? me?.id;
    if (currentUserId == null) return;

    final targetId = widget.targetProfile.id;

    // STEP 1: FIRST TAP (SHOW AGE DIFFERENCE & ASK FOR CONFIRMATION)
    if (_status == InterestStatus.none && !_isConfirmingInterest) {
      // Soft vibration
      HapticFeedback.mediumImpact();

      setState(() {
        _isConfirmingInterest = true;
      });

      _confirmResetTimer?.cancel();
      _confirmResetTimer = Timer(const Duration(seconds: 6), () {
        if (mounted && _isConfirmingInterest) {
          setState(() {
            _isConfirmingInterest = false;
          });
        }
      });
      return;
    }

    // STEP 2: SECOND TAP (CONFIRM & SEND INTEREST)
    _confirmResetTimer?.cancel();
    if (_isConfirmingInterest) {
      setState(() {
        _isConfirmingInterest = false;
      });
    }

    // Strong vibration & Audio alert sound
    HapticFeedback.heavyImpact();
    try {
      final player = AudioPlayer();
      await player
          .play(AssetSource('sounds/general_notification.wav'))
          .catchError((_) {});
    } catch (_) {}

    try {
      // 1. Try atomic RPC
      final rpcRes = await Supabase.instance.client.rpc(
        'toggle_profile_interest',
        params: {'target_user_id': targetId},
      );

      final newStatus = _parseStatusString(rpcRes?.toString() ?? 'NONE');

      if (mounted) {
        setState(() => _status = newStatus);
      }
      widget.onStateChanged?.call(newStatus);
      _showToastForStatus(newStatus);

      // Trigger cross-device Realtime & FCM Push Notification for receiver
      _dispatchNotification(currentUserId, targetId, newStatus);
    } catch (e) {
      debugPrint('[RPC Note] toggle_profile_interest RPC fallback: $e');
      _fallbackToggle(currentUserId, targetId);
    }
  }

  Future<void> _fallbackToggle(String currentUserId, String targetId) async {
    InterestStatus newStatus = InterestStatus.none;

    try {
      if (_status == InterestStatus.none) {
        // Check if target sent interest to me
        if (_status == InterestStatus.theySent) {
          await Supabase.instance.client
              .from('profile_interests')
              .update({'status': 'mutual_accepted'})
              .match({'sender_id': targetId, 'receiver_id': currentUserId});

          await Supabase.instance.client
              .from('profile_interests')
              .insert({
                'sender_id': currentUserId,
                'receiver_id': targetId,
                'status': 'mutual_accepted',
                'type': 'interest',
              })
              .catchError((_) {});

          newStatus = InterestStatus.mutual;
        } else {
          await Supabase.instance.client.from('profile_interests').insert({
            'sender_id': currentUserId,
            'receiver_id': targetId,
            'status': 'pending',
            'type': 'interest',
          });

          newStatus = InterestStatus.iSent;
        }
      } else if (_status == InterestStatus.iSent) {
        await Supabase.instance.client.from('profile_interests').delete().match(
          {'sender_id': currentUserId, 'receiver_id': targetId},
        );

        newStatus = InterestStatus.none;
      } else if (_status == InterestStatus.theySent) {
        await Supabase.instance.client
            .from('profile_interests')
            .update({'status': 'mutual_accepted'})
            .match({'sender_id': targetId, 'receiver_id': currentUserId});

        await Supabase.instance.client
            .from('profile_interests')
            .insert({
              'sender_id': currentUserId,
              'receiver_id': targetId,
              'status': 'mutual_accepted',
              'type': 'interest',
            })
            .catchError((_) {});

        newStatus = InterestStatus.mutual;
      } else if (_status == InterestStatus.mutual) {
        await Supabase.instance.client.from('profile_interests').delete().match(
          {'sender_id': currentUserId, 'receiver_id': targetId},
        );

        await Supabase.instance.client
            .from('profile_interests')
            .update({'status': 'pending'})
            .match({'sender_id': targetId, 'receiver_id': currentUserId});

        newStatus = InterestStatus.theySent;
      }

      if (mounted) {
        setState(() => _status = newStatus);
      }
      widget.onStateChanged?.call(newStatus);
      _showToastForStatus(newStatus);
      _dispatchNotification(currentUserId, targetId, newStatus);
    } catch (e) {
      debugPrint('Fallback toggle error: $e');
    }
  }

  void _showToastForStatus(InterestStatus status) {
    if (!mounted) return;
    String text = '';
    Color bg = Colors.pink.shade700;
    final ageDiffText = _getAgeDiffString();

    switch (status) {
      case InterestStatus.iSent:
        text =
            'താല്പര്യം അയച്ചു! (Interest Sent to ${widget.targetProfile.name}) ❤️${ageDiffText.isNotEmpty ? "\n• $ageDiffText" : ""}';
        bg = const Color(0xFF2E7D32); // Green on interest sent
        break;
      case InterestStatus.theySent:
        text = 'താല്പര്യം റദ്ദാക്കി';
        bg = Colors.grey.shade800;
        break;
      case InterestStatus.mutual:
        text =
            '🎉 പരസ്പര പൊരുത്തം! (Mutual Match with ${widget.targetProfile.name})${ageDiffText.isNotEmpty ? "\n• $ageDiffText" : ""}';
        bg = Colors.purple.shade700;
        break;
      case InterestStatus.none:
        text = 'താല്പര്യം മാറ്റി തിരിച്ചു (Interest Removed)';
        bg = Colors.grey.shade800;
        break;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, height: 1.3),
        ),
        backgroundColor: bg,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _dispatchNotification(
    String currentUserId,
    String targetId,
    InterestStatus newStatus,
  ) {
    final me = MockData().currentUser;
    final myName = me?.name ?? 'ഒരു ഉപയോക്താവ്';

    if (newStatus == InterestStatus.iSent) {
      // 1. Instant Realtime cross-device broadcast to receiver's channel
      try {
        final channel = Supabase.instance.client.channel(
          'user_interests_$targetId',
        );
        channel.subscribe();
        channel.sendBroadcastMessage(
          event: 'incoming_interest',
          payload: {
            'sender_id': currentUserId,
            'sender_name': myName,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } catch (e) {
        debugPrint('Realtime interest signal error: $e');
      }

      // 2. FCM Push Notification
      NotificationManager.instance.sendTargetedTestNotification(
        target: targetId,
        title: '🔔 $myName നിങ്ങൾക്ക് താല്പര്യം അറിയിച്ചിരിക്കുന്നു!',
        body: '$myName നിങ്ങൾക്ക് താല്പര്യം അറിയിച്ചിട്ടുണ്ട്.',
      );
    } else if (newStatus == InterestStatus.mutual) {
      try {
        final channel = Supabase.instance.client.channel(
          'user_interests_$targetId',
        );
        channel.subscribe();
        channel.sendBroadcastMessage(
          event: 'incoming_interest',
          payload: {
            'sender_id': currentUserId,
            'sender_name': myName,
            'type': 'mutual',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } catch (_) {}

      NotificationManager.instance.sendTargetedTestNotification(
        target: targetId,
        title: '🎉 പരസ്പര പൊരുത്തം! (Mutual Match)',
        body: '$myName നിങ്ങളുടെ താല്പര്യം സ്വീകരിച്ചു!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.pink.shade400,
            ),
          ),
        ),
      );
    }

    IconData icon;
    String label;
    Color buttonBgColor;
    Color textColor;
    Color iconColor;
    BorderSide borderSide = BorderSide.none;

    if (_isConfirmingInterest) {
      final me = MockData().currentUser;
      final myAge = me?.age ?? 25;
      final targetAge = widget.targetProfile.age;
      final diff = (targetAge - myAge).abs();
      final relStr = targetAge > myAge
          ? 'മൂത്തയാൾ'
          : (targetAge < myAge ? 'ഇളയയാൾ' : 'ഒരേ വയസ്സ്');

      icon = Icons.touch_app;
      label =
          "വയസ്സ് വ്യത്യാസം: $diff വയസ്സ് ($relStr). താല്പര്യം അയക്കാൻ ഒന്നുകൂടി അമർത്തുക";
      buttonBgColor = const Color(0xFFE65100); // Amber/Orange Accent
      textColor = Colors.white;
      iconColor = Colors.amberAccent;
      borderSide = BorderSide.none;
    } else {
      switch (_status) {
        case InterestStatus.iSent:
          icon = Icons.check_circle;
          label = "✔️ താല്പര്യം അയച്ചു (Interest Sent)";
          buttonBgColor = const Color(0xFF2E7D32); // GREEN on interest sent
          textColor = Colors.white;
          iconColor = Colors.white;
          break;

        case InterestStatus.theySent:
          icon = Icons.volunteer_activism;
          label = "താല്പര്യം വന്നിട്ടുണ്ട് (സ്വീകരിക്കുക)";
          buttonBgColor = const Color(0xFF2E7D32); // Green
          textColor = Colors.white;
          iconColor = Colors.white;
          break;

        case InterestStatus.mutual:
          icon = Icons.auto_awesome;
          label = "പരസ്പര പൊരുത്തം! (Mutual Match)";
          buttonBgColor = const Color(0xFF6A1B9A); // Deep Purple/Gold Accent
          textColor = Colors.white;
          iconColor = Colors.amberAccent;
          break;

        case InterestStatus.none:
          icon = Icons.favorite_border;
          label = "താല്പര്യം അറിയിക്കുക";
          buttonBgColor = Colors.white;
          textColor = const Color(0xFFC2185B);
          iconColor = const Color(0xFFC2185B);
          borderSide = const BorderSide(color: Color(0xFFC2185B), width: 1.5);
          break;
      }
    }

    final buttonWidget = ElevatedButton.icon(
      onPressed: _handleToggle,
      icon: Icon(icon, color: iconColor, size: 20),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
          fontSize: 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonBgColor,
        foregroundColor: textColor,
        elevation: 2,
        padding:
            widget.padding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: borderSide,
        ),
      ),
    );

    if (widget.fullWidth) {
      return SizedBox(width: double.infinity, child: buttonWidget);
    }

    return buttonWidget;
  }
}
