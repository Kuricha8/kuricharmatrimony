import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'dart:async';

class VerificationCallListener extends StatefulWidget {
  final Widget child;
  const VerificationCallListener({super.key, required this.child});

  @override
  State<VerificationCallListener> createState() => _VerificationCallListenerState();
}

class _VerificationCallListenerState extends State<VerificationCallListener> {
  StreamSubscription? _callSubscription;
  StreamSubscription? _authSubscription;
  bool _isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session?.user != null) {
        _listenForCalls();
      } else {
        _callSubscription?.cancel();
      }
    });
    
    if (Supabase.instance.client.auth.currentUser != null) {
      _listenForCalls();
    }
  }

  void _listenForCalls() {
    _callSubscription?.cancel();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _callSubscription = FirebaseFirestore.instance
        .collection('calls')
        .where('target_user_id', isEqualTo: user.id)
        .where('status', isEqualTo: 'calling')
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        _showIncomingCallDialog(doc);
      }
    });
  }

  void _showIncomingCallDialog(QueryDocumentSnapshot doc) {
    if (_isShowingDialog) return;
    _isShowingDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('അഡ്മിനിൽ നിന്നുള്ള വെരിഫിക്കേഷൻ വീഡിയോ കോൾ'),
          content: const Text('Admin is calling you for profile verification.'),
          actions: [
            TextButton(
              onPressed: () {
                _isShowingDialog = false;
                FirebaseFirestore.instance.collection('calls').doc(doc.id).update({'status': 'rejected'});
                Navigator.pop(context);
              },
              child: const Text('Decline'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                _isShowingDialog = false;
                FirebaseFirestore.instance.collection('calls').doc(doc.id).update({'status': 'accepted'});
                Navigator.pop(context);
                
                final data = doc.data() as Map<String, dynamic>;
                final roomName = data.containsKey('channel_name') ? data['channel_name'] : doc.id;
                
                final jitsiMeet = JitsiMeet();
                final options = JitsiMeetConferenceOptions(
                  room: roomName,
                  configOverrides: {
                    "startWithVideoMuted": false,
                    "startWithAudioMuted": false,
                  },
                );
                jitsiMeet.join(options);
              },
              child: const Text('Accept', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((_) => _isShowingDialog = false);
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
