import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Local business promotional model for in-feed sponsored ads.
class LocalBusinessPromo {
  final String id;
  final String businessName;
  final String categoryMalayalam;
  final String categoryEnglish;
  final String locationMalayalam;
  final String tagline;
  final String imageUrl;
  final String phoneNumber;
  final String whatsappNumber;
  final double rating;
  final int reviewsCount;

  const LocalBusinessPromo({
    required this.id,
    required this.businessName,
    required this.categoryMalayalam,
    required this.categoryEnglish,
    required this.locationMalayalam,
    required this.tagline,
    required this.imageUrl,
    required this.phoneNumber,
    required this.whatsappNumber,
    this.rating = 4.9,
    this.reviewsCount = 48,
  });

  static const List<LocalBusinessPromo> allPromos = [
    LocalBusinessPromo(
      id: 'promo_photo',
      businessName: 'വേദിക് വെഡ്ഡിംഗ് സിനിമ & ഫോട്ടോഗ്രാഫി',
      categoryMalayalam: 'വെഡ്ഡിംഗ് ഫോട്ടോഗ്രാഫി',
      categoryEnglish: 'Wedding Photography & Cinema',
      locationMalayalam: 'സുൽത്താൻ ബത്തേരി, വയനാട്',
      tagline:
          'പ്രീ-വെഡ്ഡിംഗ്, താലികെട്ട്, സിനിമാറ്റിക് ഹൈലൈറ്റ്സ് & പ്രീമിയം ആൽബം ഡിസൈനിംഗ്.',
      imageUrl:
          'https://images.unsplash.com/photo-1519741497674-611481863552?w=800',
      phoneNumber: '+919447123456',
      whatsappNumber: '919447123456',
      rating: 4.9,
      reviewsCount: 82,
    ),
    LocalBusinessPromo(
      id: 'promo_catering',
      businessName: 'റോയൽ മലബാർ കാറ്ററിംഗ് & സദ്യ',
      categoryMalayalam: 'ട്രഡീഷണൽ കാറ്ററിംഗ്',
      categoryEnglish: 'Traditional Feast & Catering',
      locationMalayalam: 'മാനന്തവാടി, വയനാട്',
      tagline:
          '28 കൂട്ടം വിഭവങ്ങളോടെ ശുദ്ധമായ കുറിച്ച്യർ സദ്യ, പായസങ്ങൾ & വിശിഷ്ട വിഭവങ്ങൾ.',
      imageUrl:
          'https://images.unsplash.com/photo-1555244162-803834f70033?w=800',
      phoneNumber: '+919447234567',
      whatsappNumber: '919447234567',
      rating: 4.8,
      reviewsCount: 114,
    ),
    LocalBusinessPromo(
      id: 'promo_jewellery',
      businessName: 'ശ്രീ ലക്ഷ്മി വെഡ്ഡിംഗ് ജ്വല്ലറി',
      categoryMalayalam: 'കല്യാണ ആഭരണങ്ങൾ',
      categoryEnglish: 'Bridal Jewellery & Ornaments',
      locationMalayalam: 'കൽപ്പറ്റ, വയനാട്',
      tagline:
          '916 ബി.ഐ.എസ് ഹാൾമാർക്ക് ചെയ്ത ശുദ്ധമായ വിവാഹ ആഭരണങ്ങളും പാരമ്പര്യ താലിയും.',
      imageUrl:
          'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800',
      phoneNumber: '+919447345678',
      whatsappNumber: '919447345678',
      rating: 4.9,
      reviewsCount: 96,
    ),
    LocalBusinessPromo(
      id: 'promo_stage',
      businessName: 'ഡ്രീംസ് വെഡ്ഡിംഗ് മണ്ഡപം & ഇന്റീരിയർ',
      categoryMalayalam: 'മണ്ഡപം & ഇന്റീരിയർ',
      categoryEnglish: 'Wedding Stage & Interior Decor',
      locationMalayalam: 'പനമരം, വയനാട്',
      tagline:
          'പരമ്പരാഗത പൂപ്പന്തൽ, പ്രീമിയം സ്റ്റേജ് ഡെക്കറേഷൻ, തീം ലൈറ്റിംഗ് & മണ്ഡപം.',
      imageUrl:
          'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=800',
      phoneNumber: '+919447456789',
      whatsappNumber: '919447456789',
      rating: 4.7,
      reviewsCount: 58,
    ),
    LocalBusinessPromo(
      id: 'promo_makeover',
      businessName: 'കല്യാണി ബ്രൈഡൽ മേക്കോവർ & മെഹന്ദി',
      categoryMalayalam: 'ബ്രൈഡൽ മേക്കോവർ',
      categoryEnglish: 'Bridal Makeover & Henna Studio',
      locationMalayalam: 'മീനങ്ങാടി, വയനാട്',
      tagline:
          'പ്രൊഫഷണൽ എച്ച്.ഡി ബ്രൈഡൽ മേക്കപ്പ്, സാരി ഡ്രേപ്പിംഗ് & ബ്രൈഡൽ മെഹന്ദി ഡിസൈനുകൾ.',
      imageUrl:
          'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=800',
      phoneNumber: '+919447567890',
      whatsappNumber: '919447567890',
      rating: 4.9,
      reviewsCount: 67,
    ),
  ];
}

/// In-Feed Local Business & Sponsored Banner Card
///
/// Displayed every 4 or 5 profiles in feed ListViews.
/// Includes top label "പ്രാദേശിക സേവനങ്ങൾ / Sponsored", rich visuals, and direct
/// "വിളിക്കുക" (Call) and "വാട്സാപ്പ്" (WhatsApp) action buttons.
/// Provides a slot to swap with Google AdMob Banner widget when AdMob is enabled.
class SponsoredBannerCard extends StatelessWidget {
  final int itemIndex;
  final LocalBusinessPromo? customPromo;
  final Widget? adMobBannerWidget;
  final EdgeInsetsGeometry margin;

  const SponsoredBannerCard({
    super.key,
    this.itemIndex = 0,
    this.customPromo,
    this.adMobBannerWidget,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  LocalBusinessPromo get _activePromo {
    if (customPromo != null) return customPromo!;
    final list = LocalBusinessPromo.allPromos;
    final idx = (itemIndex ~/ 5) % list.length;
    return list[idx];
  }

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d\+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ഫോൺ നമ്പർ: $phone'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching phone call: $e');
    }
  }

  Future<void> _openWhatsApp(
    BuildContext context,
    String waNumber,
    String businessName,
  ) async {
    final clean = waNumber.replaceAll(RegExp(r'[^\d]'), '');
    final message =
        'ഹലോ $businessName, കുറിച്ച്യർ മാട്രിമോണി ആപ്പിലെ പരസ്യം വഴി ബന്ധപ്പെടുകയാണ്. കൂടുതൽ വിവരങ്ങൾ അറിയാൻ താല്പര്യമുണ്ട്.';
    final uri = Uri.parse(
      'https://wa.me/$clean?text=${Uri.encodeComponent(message)}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('വാട്സാപ്പ് നമ്പർ: $waNumber'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prepared slot for Google AdMob Banner widget when enabled
    if (adMobBannerWidget != null) {
      return Container(
        margin: margin,
        child: adMobBannerWidget,
      );
    }

    final promo = _activePromo;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD97706).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: Top label & Sponsored Badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFFBEB),
                  const Color(0xFFFEF3C7),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFFCD34D).withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Sponsored',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'പ്രാദേശിക സേവനങ്ങൾ (Local Services)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFBBF24)),
                  ),
                  child: Text(
                    promo.categoryMalayalam,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Promo Image & Overlay ──
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 7.5,
                child: Image.network(
                  promo.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF1E3A8A),
                    child: const Center(
                      child: Icon(Icons.business, color: Colors.white70, size: 48),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFFD700), size: 13),
                          const SizedBox(width: 3),
                          Text(
                            '${promo.rating} (${promo.reviewsCount})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        promo.categoryEnglish,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Business Details ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.businessName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        promo.locationMalayalam,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  promo.tagline,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // ── Direct Action Buttons (Call / WhatsApp) ──
                Row(
                  children: [
                    // വിളിക്കുക (Call) Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(context, promo.phoneNumber),
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text(
                          'വിളിക്കുക (Call)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // വാട്സാപ്പ് (WhatsApp) Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openWhatsApp(
                          context,
                          promo.whatsappNumber,
                          promo.businessName,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text(
                          'വാട്സാപ്പ് (Chat)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
