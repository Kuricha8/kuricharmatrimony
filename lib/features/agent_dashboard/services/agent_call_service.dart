import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AgentCallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;

  // 1. ക്ലയന്റ് ഏജന്റിനെ വിളിക്കുമ്പോൾ
  Future<String?> initiateCall({
    required String clientId,
    required String clientPinCode,
  }) async {
    // a. വെൽക്കം മെസ്സേജ് പ്ലേ ചെയ്യുന്നു
    try {
      // 1. പഴയ ഓഡിയോ ഓടുന്നുണ്ടെങ്കിൽ പൂർണ്ണമായി നിർത്തുക
      await _audioPlayer.stop();
      // 2. പുതിയ ഓഡിയോ മാത്രം വ്യക്തമായി പ്ലേ ചെയ്യുക
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
