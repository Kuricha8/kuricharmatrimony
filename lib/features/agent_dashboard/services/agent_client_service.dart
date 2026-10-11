import 'package:cloud_firestore/cloud_firestore.dart';

class AgentClientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. സ്വന്തം പ്രൊഫൈൽ എഡിറ്റ് ചെയ്യുന്നത് തടയുകയും മറ്റുള്ളവരുടെ എഡിറ്റ് റിക്വസ്റ്റ് അയക്കുകയും ചെയ്യൽ
  Future<void> requestProfileEdit({
    required String loggedInUserId,
    required String clientProfileId,
    required String agentId,
    required Map<String, dynamic> updatedFields,
  }) async {
    // റൂൾ: സ്വന്തം പ്രൊഫൈൽ സ്വയം എഡിറ്റ് ചെയ്യാൻ പാടില്ല
    if (loggedInUserId == clientProfileId) {
      throw Exception("നിങ്ങൾക്ക് നിങ്ങളുടെ സ്വന്തം പ്രൊഫൈൽ എഡിറ്റ് ചെയ്യാൻ അനുവാദമില്ല. മറ്റൊരു ഏജന്റിനെ സമീപിക്കുക.");
    }

    // ക്ലയന്റിന്റെ അപ്രൂവലിനായി മാറ്റങ്ങൾ പ്രത്യേക കളക്ഷനിലേക്ക് അയക്കുന്നു
    await _firestore.collection('profile_edit_requests').add({
      'client_id': clientProfileId,
      'requested_by_agent_id': agentId,
      'updated_data': updatedFields,
      'status': 'PENDING_CLIENT_APPROVAL',
      'created_at': FieldValue.serverTimestamp(),
    });

    // അഡ്മിൻ അറിയാൻ ആക്റ്റിവിറ്റി ലോഗ് ചേർക്കുന്നു
    await _firestore.collection('activity_logs').add({
      'actor_id': agentId,
      'action_type': 'PROFILE_EDIT_REQUESTED',
      'client_id': clientProfileId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 2. ക്ലയന്റ് സ്വന്തം ആപ്പിൽ വെച്ച് മാറ്റങ്ങൾ അപ്രൂവ് ചെയ്യുന്നു
  Future<void> approveEditByClient({
    required String requestId,
    required String clientProfileId,
    required Map<String, dynamic> updatedData,
  }) async {
    // മെയിൻ പ്രൊഫൈൽ അപ്ഡേറ്റ് ചെയ്യുന്നു
    await _firestore.collection('profiles').doc(clientProfileId).update(updatedData);

    // റിക്വസ്റ്റ് സ്റ്റാറ്റസ് മാറ്റുന്നു
    await _firestore.collection('profile_edit_requests').doc(requestId).update({
      'status': 'APPROVED',
      'client_approved_at': FieldValue.serverTimestamp(),
    });

    // അഡ്മിൻ അറിയാൻ ലോഗ് രേഖപ്പെടുത്തുന്നു
    await _firestore.collection('activity_logs').add({
      'actor_id': clientProfileId,
      'action_type': 'EDIT_APPROVED_BY_CLIENT',
      'client_id': clientProfileId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 3. ഏജന്റ് തിരഞ്ഞെടുത്ത പിൻകോഡിലുള്ള ക്ലയന്റുകളെ മാത്രം കാണിക്കുന്നു
  Stream<QuerySnapshot> getTargetedClients(List<String> assignedPinCodes) {
    if (assignedPinCodes.isEmpty) {
      return const Stream.empty();
    }
    return _firestore
        .collection('profiles')
        .where('is_deleted', isEqualTo: false)
        .where('pincode', whereIn: assignedPinCodes)
        .limit(20)
        .snapshots();
  }
}
