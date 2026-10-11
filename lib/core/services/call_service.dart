import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// Centralized In-App Audio & Video Call Service for Mediated Safe Call.
/// Manages WebRTC signaling, `call_sessions` database records, and High-Priority VoIP/Push alerts.
class CallService {
  static final CallService instance = CallService._internal();
  factory CallService() => instance;
  CallService._internal();

  final SupabaseClient supabase = Supabase.instance.client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;

  /// 1. Create Call Session in Supabase `call_sessions` table with status 'calling'
  /// and send high-priority incoming call notification payload to target user.
  Future<String?> initiateCallSession({
    required String callerId,
    required String callerName,
    required String targetUserId,
    required String targetUserName,
    required String callType, // 'audio' or 'video'
    int durationMinutes = 15,
  }) async {
    final String fallbackCallId =
        'call_${DateTime.now().millisecondsSinceEpoch}';
    String callId = fallbackCallId;

    try {
      // Primary: Insert into `call_sessions` table
      try {
        final res = await supabase
            .from('call_sessions')
            .insert({
              'caller_id': callerId,
              'caller_name': callerName,
              'receiver_id': targetUserId,
              'target_user_id': targetUserId,
              'target_user_name': targetUserName,
              'call_type': callType,
              'status':
                  'calling', // 'calling' -> 'connected' -> 'ended' / 'rejected' / 'timeout'
              'created_at': DateTime.now().toIso8601String(),
              'duration_minutes': durationMinutes,
            })
            .select('id')
            .single();

        if (res['id'] != null) {
          callId = res['id'].toString();
        }
      } catch (dbErr) {
        debugPrint(
          '[CALL_SERVICE] Notice: call_sessions insert fallback: $dbErr',
        );
        // Fallback: Insert into `call_requests` table
        try {
          final res = await supabase
              .from('call_requests')
              .insert({
                'caller_id': callerId,
                'receiver_id': targetUserId,
                'target_user_id': targetUserId,
                'status': 'calling',
                'call_type': callType,
                'duration_minutes': durationMinutes,
                'approved_at': DateTime.now().toIso8601String(),
              })
              .select('id')
              .single();

          if (res['id'] != null) {
            callId = res['id'].toString();
          }
        } catch (_) {}
      }

      // 2. Broadcast High-Priority Realtime VoIP / Incoming Call Payload Signal
      try {
        final channel = supabase.channel('user_calls_$targetUserId');
        channel.subscribe();
        await channel.sendBroadcastMessage(
          event: 'incoming_call_signal',
          payload: {
            'call_id': callId,
            'caller_id': callerId,
            'caller_name': callerName,
            'target_user_id': targetUserId,
            'target_user_name': targetUserName,
            'call_type': callType,
            'status': 'calling',
            'priority': 'high',
            'duration_minutes': durationMinutes,
            'created_at': DateTime.now().toIso8601String(),
          },
        );
      } catch (rtErr) {
        debugPrint('[CALL_SERVICE] Realtime signal notice: $rtErr');
      }

      // 3. Queue High-Priority Push / VoIP Notification Record in Supabase Notifications
      try {
        await supabase.from('notifications').insert({
          'user_id': targetUserId,
          'type': 'incoming_call',
          'title': callType == 'video'
              ? '📹 ഇൻകമിംഗ് വീഡിയോ കോൾ'
              : '📞 ഇൻകമിംഗ് ഓഡിയോ കോൾ',
          'body': '$callerName നിങ്ങളെ $callType കോൾ ചെയ്യുന്നു...',
          'data': {
            'call_id': callId,
            'caller_id': callerId,
            'caller_name': callerName,
            'call_type': callType,
            'status': 'calling',
            'priority': 'high',
          },
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (notifErr) {
        debugPrint('[CALL_SERVICE] Notification insert notice: $notifErr');
      }

      return callId;
    } catch (e) {
      debugPrint('[CALL_SERVICE] Error initiating call session: $e');
      return fallbackCallId;
    }
  }

  /// Update call session status in `call_sessions` and `call_requests` tables
  Future<void> updateCallSessionStatus(
    String callId,
    String status, {
    String? endReason,
  }) async {
    final now = DateTime.now().toIso8601String();
    final updateData = <String, dynamic>{
      'status': status,
      if (status == 'ended' || status == 'rejected' || status == 'timeout')
        'ended_at': now,
    };
    if (endReason != null) {
      updateData['end_reason'] = endReason;
    }

    try {
      await supabase.from('call_sessions').update(updateData).eq('id', callId);
    } catch (_) {}

    try {
      await supabase.from('call_requests').update(updateData).eq('id', callId);
    } catch (_) {}
  }

  /// Handle Call Rejection
  Future<void> rejectCallSession(String callId, String targetUserId) async {
    await updateCallSessionStatus(
      callId,
      'rejected',
      endReason: 'User Rejected Call',
    );
    try {
      final channel = supabase.channel('call_room_$callId');
      channel.subscribe();
      await channel.sendBroadcastMessage(
        event: 'call_rejected',
        payload: {'call_id': callId, 'status': 'rejected'},
      );
    } catch (_) {}
  }

  /// Handle 30-Second Ringing Timeout
  Future<void> timeoutCallSession(String callId, String targetUserId) async {
    await updateCallSessionStatus(
      callId,
      'timeout',
      endReason: '30s Ringing Timeout',
    );
    try {
      final channel = supabase.channel('call_room_$callId');
      channel.subscribe();
      await channel.sendBroadcastMessage(
        event: 'call_timeout',
        payload: {'call_id': callId, 'status': 'timeout'},
      );
    } catch (_) {}
  }

  /// Legacy helper for sending raw call request
  Future<String?> sendCallRequest({
    required String callerId,
    required String receiverId,
  }) async {
    try {
      final res = await supabase
          .from('call_requests')
          .insert({
            'caller_id': callerId,
            'receiver_id': receiverId,
            'status': 'pending_user_b',
          })
          .select()
          .single();
      return res['id']?.toString();
    } catch (e) {
      debugPrint('Error sending call request: $e');
      return null;
    }
  }

  Future<void> acceptCallByUserB(String requestId) async {
    try {
      await supabase
          .from('call_requests')
          .update({'status': 'b_accepted_pending_admin'})
          .eq('id', requestId);
    } catch (e) {
      debugPrint('Error accepting call by user B: $e');
    }
  }

  Future<void> declineCallByUserB(String requestId) async {
    try {
      await supabase
          .from('call_requests')
          .update({'status': 'rejected_by_b'})
          .eq('id', requestId);
    } catch (e) {
      debugPrint('Error declining call by user B: $e');
    }
  }

  Future<void> approveCallByAdmin(String requestId) async {
    try {
      await supabase
          .from('call_requests')
          .update({
            'status': 'admin_approved',
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
    } catch (e) {
      debugPrint('Error approving call by admin: $e');
    }
  }

  Future<void> rejectOrEndCall(String requestId) async {
    await updateCallSessionStatus(
      requestId,
      'ended',
      endReason: 'Call Terminated',
    );
  }

  Future<void> triggerEmergencySOS({
    required String callId,
    required String userId,
  }) async {
    try {
      await updateCallSessionStatus(callId, 'sos_triggered');
      await supabase.from('call_sos_alerts').insert({
        'call_id': callId,
        'triggered_by': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error triggering emergency SOS: $e');
    }
  }

  Future<String?> initiateAdminCall({
    required String adminId,
    required String targetUserId,
    required String targetUserName,
    required String callType,
    int durationMinutes = 15,
  }) async {
    return initiateCallSession(
      callerId: adminId,
      callerName: 'Admin Support',
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      callType: callType,
      durationMinutes: durationMinutes,
    );
  }

  // ── Agent Client Call & Recording Methods ──

  // 1. ക്ലയന്റ് ഏജന്റിനെ വിളിക്കുമ്പോൾ
  Future<String?> initiateCall({
    required String clientId,
    required String clientPinCode,
  }) async {
    // a. വെൽക്കം മെസ്സേജ് പ്ലേ ചെയ്യുന്നു
    try {
      await _audioPlayer.play(AssetSource('audio/welcome.mp3'));
    } catch (_) {}

    // b. ആ പിൻകോഡിലുള്ള, നിലവിൽ ഫ്രീയായ ഏജന്റിനെ തിരയുന്നു
    QuerySnapshot agentSnapshot = await _firestore
        .collection('agents')
        .where('is_online', isEqualTo: true)
        .where('is_busy', isEqualTo: false)
        .where('target_pincodes', arrayContains: clientPinCode)
        .orderBy('last_call_at', descending: false)
        .limit(1)
        .get();

    if (agentSnapshot.docs.isEmpty) {
      return null; // നിലവിൽ ആ പിൻകോഡിൽ ഏജന്റുമാർ ഫ്രീ അല്ല
    }

    String agentId = agentSnapshot.docs.first.id;

    // c. ഫയർസ്റ്റോറിൽ കോൾ ഉണ്ടാക്കുന്നു (നമ്പറുകൾ മാസ്ക് ചെയ്തിരിക്കും)
    DocumentReference callRef = await _firestore.collection('calls').add({
      'client_id': clientId,
      'agent_id': agentId,
      'status': 'RINGING',
      'created_at': FieldValue.serverTimestamp(),
      'recording_url': '',
      'call_notes': '',
    });

    // ഏജന്റിനെ busy ആക്കുന്നു
    await _firestore.collection('agents').doc(agentId).update({'is_busy': true});

    return callRef.id;
  }

  // 2. ഏജന്റ് കോൾ എടുക്കുമ്പോൾ റെക്കോർഡിംഗ് ആരംഭിക്കുന്നു
  Future<void> startCallRecording(String callId) async {
    if (await _audioRecorder.hasPermission()) {
      final Directory tempDir = await getTemporaryDirectory();
      _currentRecordingPath = '${tempDir.path}/call_$callId.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _currentRecordingPath!,
      );

      await _firestore.collection('calls').doc(callId).update({
        'status': 'IN_PROGRESS',
      });
    }
  }

  // 3. കോൾ അവസാനിക്കുമ്പോൾ സേവ് ചെയ്ത് Firebase-ലേക്ക് അപ്ലോഡ് ചെയ്യുന്നു
  Future<void> endCallAndUploadRecording({
    required String callId,
    required String agentId,
    String? callNotes,
  }) async {
    final path = await _audioRecorder.stop();

    String downloadUrl = '';
    if (path != null) {
      File audioFile = File(path);
      // Firebase Storage-ലേക്ക് അപ്ലോഡ് ചെയ്യുന്നു
      UploadTask uploadTask = FirebaseStorage.instance
          .ref('call_recordings/$callId.m4a')
          .putFile(audioFile);

      TaskSnapshot snapshot = await uploadTask;
      downloadUrl = await snapshot.ref.getDownloadURL();
    }

    // ഫയർസ്റ്റോറിൽ അപ്ഡേറ്റ് ചെയ്യുന്നു (അഡ്മിന് കേൾക്കാൻ ലിങ്ക് റെഡി)
    await _firestore.collection('calls').doc(callId).update({
      'status': 'ENDED',
      'recording_url': downloadUrl,
      'call_notes': callNotes ?? '',
      'ended_at': FieldValue.serverTimestamp(),
    });

    // ഏജന്റിനെ വീണ്ടും free ആക്കുന്നു
    await _firestore.collection('agents').doc(agentId).update({
      'is_busy': false,
      'last_call_at': FieldValue.serverTimestamp(),
    });
  }
}
