import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<DocumentSnapshot>? _userFuture;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _userFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get(const GetOptions(source: Source.serverAndCache));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text("Login Required")));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const HomeScreen();
        }

        var userData = snapshot.data?.data() as Map<String, dynamic>?;
        bool isBlocked = userData?['isBlocked'] ??
            userData?['is_blocked'] ??
            userData?['is_banned'] ??
            false;

        // അഡ്മിൻ ബ്ലോക്ക് ചെയ്തിട്ടുണ്ടെങ്കിൽ ആക്സസ് തടയുന്നു
        if (isBlocked) {
          String reason = userData?['blockReason'] ??
              userData?['banned_reason'] ??
              'നിങ്ങളുടെ അക്കൗണ്ട് താല്ക്കാലികമായി ബ്ലോക്ക് ചെയ്തിരിക്കുന്നു.';
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, size: 80, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      "അക്കൗണ്ട് തടഞ്ഞിരിക്കുന്നു",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(reason, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    const Text(
                      "കൂടുതൽ വിവരങ്ങൾക്ക് അഡ്മിനുമായി ബന്ധപ്പെടുക: Kuricha8@gmail.com",
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const HomeScreen();
      },
    );
  }
}
