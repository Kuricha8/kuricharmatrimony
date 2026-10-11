import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/call_service.dart';
import '../../core/utils/haptic_helper.dart';
import 'secure_audio_call_screen.dart';

/// Incoming Mediated Safe Call Alert Dialog for Receiver (e.g. Madhu).
/// Displays high-priority incoming audio/video call notification with Accept and Reject actions.
class IncomingCallDialog extends StatefulWidget {
  final String callId;
  final String callerId;
  final String callerName;
  final String callType; // 'audio' or 'video'
  final String currentUserId;

  const IncomingCallDialog({
    super.key,
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.callType,
    required this.currentUserId,
  });

  static Future<void> show(
    BuildContext context, {
    required String callId,
    required String callerId,
    required String callerName,
    required String callType,
    required String currentUserId,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => IncomingCallDialog(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        callType: callType,
        currentUserId: currentUserId,
      ),
    );
  }

  @override
  State<IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<IncomingCallDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    HapticHelper.heavyImpact();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // 30 seconds auto-dismiss ringing timeout
    _autoDismissTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _acceptCall() {
    _autoDismissTimer?.cancel();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SecureAudioCallScreen(
          currentUserId: widget.currentUserId,
          targetUserId: widget.callerId,
          targetUserName: widget.callerName,
          callId: widget.callId,
          callType: widget.callType,
          isCaller: false,
          maxDurationMinutes: 15,
        ),
      ),
    );
  }

  Future<void> _rejectCall() async {
    _autoDismissTimer?.cancel();
    await CallService.instance.rejectCallSession(
      widget.callId,
      widget.currentUserId,
    );
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isVideo = widget.callType == 'video';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFF0F172A),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulse Avatar
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.12),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: isVideo
                        ? Colors.blue.shade700
                        : Colors.green.shade700,
                    child: Icon(
                      isVideo ? Icons.videocam : Icons.phone,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            Text(
              isVideo ? '📹 ഇൻകമിംഗ് വീഡിയോ കോൾ' : '📞 ഇൻകമിംഗ് ഓഡിയോ കോൾ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              widget.callerName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),

            const Text(
              'അഡ്മിൻ മധ്യസ്ഥതയിലുള്ള സുരക്ഷിത കോൾ',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 28),

            // Action Buttons (Reject & Accept)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reject Button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filled(
                      iconSize: 32,
                      onPressed: _rejectCall,
                      icon: const Icon(Icons.call_end),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'നിരസിക്കുക',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(width: 24),

                // Accept Button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filled(
                      iconSize: 32,
                      onPressed: _acceptCall,
                      icon: Icon(isVideo ? Icons.videocam : Icons.call),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'സ്വീകരിക്കുക',
                      style: TextStyle(
                        color: Color(0xFF22C55E),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
