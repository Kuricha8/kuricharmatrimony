import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SocialMediaPromoCard extends StatelessWidget {
  final GlobalKey cardKey;
  final String imagePath; // യൂസർ സെലക്ട് ചെയ്ത ഫോട്ടോയുടെ പാത്ത്
  final String fullName; // പേര്
  final int age; // വയസ്സ്
  final String job; // ജോലി
  final String district; // ജില്ല
  final String websiteUrl; // വെബ്സൈറ്റ് ലിങ്ക് (ക്യുആർ കോഡിനായി)

  const SocialMediaPromoCard({
    super.key,
    required this.cardKey,
    required this.imagePath,
    required this.fullName,
    required this.age,
    required this.job,
    required this.district,
    this.websiteUrl = "https://pcmwayanad.com", // നിങ്ങളുടെ വെബ്സൈറ്റ്
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: cardKey, // ഇമേജ് ആക്കി മാറ്റാൻ ആവശ്യമായ കീ
      child: Container(
        width: 340,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF000080).withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. ഹെഡർ: ലോഗോ & ആപ്പ് പേര്
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_kym.png',
                  height: 24,
                  width: 24,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                Text(
                  "WAYANAD MATRIMONY",
                  style: TextStyle(
                    color: const Color(0xFF000080),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 2. പ്രൊഫൈൽ ഫോട്ടോ (നടുവിൽ വൃത്താകൃതിയിൽ)
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF000080), width: 3.5),
                image: DecorationImage(
                  image: FileImage(File(imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. പേര്
            Text(
              fullName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            // 4. പ്രധാന വിവരങ്ങൾ (വയസ്സ്, ജില്ല, ജോലി)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "വയസ്സ്: $age",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Text("  |  ", style: TextStyle(color: Colors.grey)),
                      Text(
                        "ജില്ല: $district",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  if (job.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "തൊഴിൽ: ${job.trim()}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF000080),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 5. വെബ്സൈറ്റ് ക്യുആർ കോഡ് (QR Code)
            QrImageView(
              data: websiteUrl,
              version: QrVersions.auto,
              size: 80.0,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF000080),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF000080),
              ),
            ),

            const SizedBox(height: 8),

            // അടിയിലെ വിവരണം
            const Text(
              "കൂടുതൽ വിവരങ്ങൾക്ക് വെബ്സൈറ്റ് സന്ദർശിക്കുക",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
