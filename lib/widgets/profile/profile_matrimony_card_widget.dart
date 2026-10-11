import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/models/models.dart';
import '../../core/widgets/watermarked_image.dart';
import '../../core/kurichiyar_clan_engine.dart';
import '../../features/clan_feed/tharavadu_list.dart';

class ProfileMatrimonyCardWidget extends StatelessWidget {
  final UserProfile me;
  final int totalProfileLikes;
  final int totalComments;
  final GlobalKey globalKey;
  final VoidCallback? onLikesTap;
  final VoidCallback? onCommentsTap;

  const ProfileMatrimonyCardWidget({
    super.key,
    required this.me,
    required this.totalProfileLikes,
    required this.totalComments,
    required this.globalKey,
    this.onLikesTap,
    this.onCommentsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Engagement Badge — split into separate Likes and Comments tap zones
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Likes zone ──────────────────────────────────────────────────
            Expanded(
              child: InkWell(
                onTap: onLikesTap,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star_purple500,
                        color: Color(0xFF5C3E00),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ലൈക്കുകൾ ($totalProfileLikes)',
                        style: const TextStyle(
                          color: Color(0xFF5C3E00),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── Comments zone ───────────────────────────────────────────────
            Expanded(
              child: InkWell(
                onTap: onCommentsTap,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(12),
                    ),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Color(0xFF5C3E00),
                        size: 17,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'അഭിപ്രായങ്ങൾ ($totalComments)',
                        style: const TextStyle(
                          color: Color(0xFF5C3E00),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildWhatsAppStatusCard(context, me),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: () => _shareStatusCard(context),
          icon: const Icon(Icons.share, color: Colors.white),
          label: const Text(
            'വാട്സാപ്പ് സ്റ്റാറ്റസ് വഴി പങ്കിടുക',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWhatsAppStatusCard(BuildContext context, UserProfile me) {
    final tharavadName =
        (me.motherTharavadu != null && me.motherTharavadu!.trim().isNotEmpty)
        ? me.motherTharavadu!.trim()
        : (me.tharavaduName.isNotEmpty
              ? me.tharavaduName
              : (me.houseName ?? '—'));
    final profileLink = me.id.isNotEmpty
        ? 'https://kuricharmatrimony.vercel.app/profile?id=${me.id}'
        : 'https://kuricharmatrimony.vercel.app';

    // Dynamic Eligible Taravads Box based on Candidate's Mother's Moiety
    final String candidateMotherClan =
        (me.motherTharavadu ?? me.motherTharavadName ?? '').trim();
    final String candidateFatherClan = (me.fatherTharavadu ?? '').trim();

    final bool isPanthi =
        KurichiyarClanEngine.extractMoiety(candidateMotherClan) == 'PANTHI';
    final String boxTitle = isPanthi
        ? 'വിവാഹബന്ധം അനുവദനീയമായ തറവാടുകൾ (ബന്ധു ഇല്ലങ്ങൾ)'
        : 'വിവാഹബന്ധം അനുവദനീയമായ തറവാടുകൾ (പന്തി ഇല്ലങ്ങൾ)';

    final List<String> oppositeList = me.eligibleTharavadsList;
    final List<String> eligibleList = oppositeList.where((house) {
      final h = house.toLowerCase().trim();
      return !h.contains(candidateMotherClan.toLowerCase().trim()) &&
          !h.contains(candidateFatherClan.toLowerCase().trim());
    }).toList();

    final int dynamicFallbackCount = isPanthi
        ? TharavaduService.bandhuClans.length
        : TharavaduService.pandiClans.length;
    final int count = eligibleList.isNotEmpty
        ? eligibleList.length
        : dynamicFallbackCount;
    final String eligibleGroupTitle = '$boxTitle ($count തറവാടുകൾ)';
    final String eligibleClansText = eligibleList.isNotEmpty
        ? eligibleList.take(10).join(', ') +
              (eligibleList.length > 10 ? '...' : '')
        : (isPanthi ? 'എല്ലാ ബന്ധു തറവാടുകളും' : 'എല്ലാ പന്തി തറവാടുകളും');

    return RepaintBoundary(
      key: globalKey,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D11), // Deep black-grey
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD4AF37),
            width: 3,
          ), // Premium Gold border
          gradient: const RadialGradient(
            colors: [Color(0xFF231F20), Color(0xFF0D0D11)],
            center: Alignment.center,
            radius: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. ഇടതുവശത്തെ സ്റ്റാറും ടൈറ്റിലും
                const Row(
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFFFD700),
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'KURICHIYAR MATRIMONY',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),

                // 2. വലതുവശത്തെ ലോഗോ (കൃത്യമായ അലൈൻമെന്റിൽ)
                Image.asset(
                  'assets/images/logo_kym.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.stars,
                    color: Color(0xFFFFD700),
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              ),
              child: ClipOval(
                child: me.photoUrl.startsWith('http')
                    ? WatermarkedImage(
                        imageUrl: me.photoUrl,
                        width: 96,
                        height: 96,
                      )
                    : Image.asset(
                        'assets/images/default_avatar.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusCardRow('പേര് (Name)', me.name),
            _buildStatusCardRow('വയസ്സ് (Age)', '${me.age} Yrs'),
            _buildStatusCardRow('തറവാട് (Taravad)', tharavadName),
            const SizedBox(height: 6),

            // ── Eligible Clans / Matching Tharavadu Section ──
            _buildEligibleClansSection(
              title: eligibleGroupTitle,
              clansText: eligibleClansText,
            ),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFF333333), height: 1),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: profileLink,
                version: QrVersions.auto,
                size: 125.0,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(4),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Scan QR to view full profile details',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),
            // Website Banner with Copy Action
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935), // Red background
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'വെബ്സൈറ്റ്:',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'https://kuricharmatrimony.vercel.app',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(
                          text: 'https://kuricharmatrimony.vercel.app',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('വെബ് വിലാസം കോപ്പി ചെയ്തു!'),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Copy',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEligibleClansSection({
    required String title,
    required String clansText,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6, bottom: 2),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1917), // Dark gold-tinted background
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, size: 14, color: Color(0xFFD4AF37)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            clansText,
            style: TextStyle(
              color: Colors.amber.shade100.withValues(alpha: 0.9),
              fontSize: 10,
              height: 1.35,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCardRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFFE5D5B3),
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareStatusCard(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return;
      Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/kurichiyar_matrimony_status_${me.id}.png',
      ).create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Check out my matrimonial profile on Kurichiyar Matrimony! Scan the QR code to view my verified details.',
      );
    } catch (e) {
      debugPrint('Failed to share status card: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error sharing status card: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
