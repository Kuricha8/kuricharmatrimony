import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kurichiyar_matrimony/core/utils/mock_data.dart';
import '../auth_splash/guest_page.dart';

class WeddingSuccessPage extends StatelessWidget {
  const WeddingSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF9E6),
              Color(0xFFFFF0C2),
            ], // Light warm gold gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Icon(
                  Icons.favorite,
                  color: Color(0xFFD4AF37), // Gold heart
                  size: 100,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Congratulations on your Wedding!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C3E00), // Deep brown/gold
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'നവദമ്പതികൾക്ക് ആശംസകൾ!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5C3E00),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'We are thrilled to have played a part in your journey. Your profile has been automatically hidden from matching rooms and search results to ensure your privacy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Log out user securely
                    await Supabase.instance.client.auth.signOut();
                    MockData().logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GuestScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Logout & Exit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C3E00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
