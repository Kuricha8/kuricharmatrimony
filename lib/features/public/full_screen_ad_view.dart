import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../registration/auto_video_verification_screen.dart';

class FullScreenAdView extends StatelessWidget {
  const FullScreenAdView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'à´µà´¾àµ¼à´¤àµà´¤à´•à´³àµà´‚ à´ªà´°à´¸àµà´¯à´™àµà´™à´³àµà´‚',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'à´²àµ‹à´—àµ—à´Ÿàµà´Ÿàµ',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildVideoKycBanner(context),
          // à´…à´ªàµà´°àµ‚à´µàµ½ à´ªàµà´°à´•àµà´°à´¿à´¯ à´¨à´Ÿà´•àµà´•àµà´¨àµà´¨àµ à´Žà´¨àµà´¨ à´…à´±à´¿à´¯à´¿à´ªàµà´ªàµ à´¬à´¾à´¨àµ¼
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.hourglass_top, color: Colors.deepOrange, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'à´¨à´¿à´™àµà´™à´³àµà´Ÿàµ† à´ªàµà´°àµŠà´«àµˆàµ½ à´ªà´°à´¿à´¶àµ‹à´§à´¨à´¯à´¿à´²à´¾à´£àµ. à´…à´¡àµà´®à´¿àµ» à´…à´ªàµà´°àµ‚à´µàµ½ à´ªàµ‚àµ¼à´¤àµà´¤à´¿à´¯à´¾à´¯à´¾àµ½ à´‰à´Ÿàµ» à´®à´¾à´Ÿàµà´°à´¿à´®àµ‹à´£à´¿ à´ªàµ‡à´œàµ à´¤àµà´±à´•àµà´•àµà´¨àµà´¨à´¤à´¾à´£àµ.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // à´ªà´°à´¸àµà´¯à´™àµà´™àµ¾ / à´¬à´¾à´¨à´±àµà´•àµ¾
          _buildPosterCard(
            'assets/images/ad_banner1.jpg',
            'à´ªàµà´°à´¤àµà´¯àµ‡à´• à´“à´«à´±àµà´•àµ¾ & à´…à´±à´¿à´¯à´¿à´ªàµà´ªàµà´•àµ¾',
          ),
          const SizedBox(height: 14),
          _buildPosterCard(
            'assets/images/ad_banner2.jpg',
            'à´µà´¾à´£à´¿à´œàµà´¯ à´ªà´°à´¸àµà´¯à´™àµà´™àµ¾ & à´¸àµ‡à´µà´¨à´™àµà´™àµ¾',
          ),
        ],
      ),
    );
  }

  Widget _buildPosterCard(String img, String title) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey.shade100, Colors.blueGrey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign, size: 54, color: Color(0xFF1E3A8A)),
                SizedBox(height: 8),
                Text(
                  'Community News & Ads',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoKycBanner(BuildContext context) {
    final String currentUid = (FirebaseAuth.instance.currentUser?.uid.isNotEmpty == true)
        ? FirebaseAuth.instance.currentUser!.uid
        : (Supabase.instance.client.auth.currentUser?.id.isNotEmpty == true)
            ? Supabase.instance.client.auth.currentUser!.id
            : '';

    if (currentUid.trim().isEmpty) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() ?? {};
        final status = (data['video_kyc_status'] ?? '').toString().toLowerCase().trim();
        final bool isRequested = status == 'requested';
        final bool isRequired = data['video_kyc_required'] == true;

        if (!isRequested && !isRequired) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFD32F2F),
                Color(0xFFFF5722),
                Color(0xFFFF8F00),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade200, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.4),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => AutoVideoVerificationScreen.start(context, userId: currentUid),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'URGENT / അത്യാവശ്യം',
                                  style: TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'വീഡിയോ കെവൈസി ആവശ്യപ്പെട്ടിരിക്കുന്നു: നിങ്ങളുടെ പ്രൊഫൈൽ പൂർണ്ണമാക്കാൻ സെൽഫി വീഡിയോ അപ്ലോഡ് ചെയ്യുക.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFD32F2F),
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => AutoVideoVerificationScreen.start(context, userId: currentUid),
                      child: const Text(
                        'അപ്‌ലോഡ്',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}