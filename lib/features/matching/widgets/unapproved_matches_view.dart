import 'package:flutter/material.dart';
import '../controllers/matching_controller.dart';

class UnapprovedMatchesView extends StatelessWidget {
  final MatchingController controller;

  const UnapprovedMatchesView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person_rounded, size: 80, color: Colors.white70),
            const SizedBox(height: 16),
            const Text(
              'പ്രൊഫൈൽ പരിശോധനയിലാണ്',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'അഡ്മിൻ നിങ്ങളുടെ രേഖകളും പ്രൊഫൈലും പരിശോധിച്ച് അംഗീകരിച്ചതിന് (Approve) ശേഷം മാത്രമേ മറ്റ് മാച്ചുകളും ഫോട്ടോകളും കാണാൻ സാധിക്കൂ.',
                style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orangeAccent),
              ),
              child: const Text(
                'നിലവിലെ അവസ്ഥ: വെരിഫിക്കേഷൻ പുരോഗമിക്കുന്നു',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.isRefreshing
                  ? null
                  : () => controller.refreshStatusAndProfile(context),
              icon: controller.isRefreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                controller.isRefreshing
                    ? 'Checking Database...'
                    : 'Check Status / Refresh',
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
