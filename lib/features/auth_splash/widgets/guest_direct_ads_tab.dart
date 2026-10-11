import 'package:flutter/material.dart';
import '../../clan_feed/admin_custom_ad_widget.dart';
import '../../../core/widgets/native_ad_card.dart';
import '../../../core/widgets/app_footer.dart';

class GuestDirectAdsTab extends StatefulWidget {
  const GuestDirectAdsTab({super.key});

  @override
  State<GuestDirectAdsTab> createState() => _GuestDirectAdsTabState();
}

class _GuestDirectAdsTabState extends State<GuestDirectAdsTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade800, Colors.amber.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.campaign, color: Colors.white, size: 28),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ഡയറക്ട് പരസ്യങ്ങൾ & ഓഫറുകൾ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'സമുദായ ബിസിനസ്സുകൾ, സംരംഭങ്ങൾ, സ്‌പോൺസേഡ് സേവനങ്ങൾ എന്നിവ ഇവിടെ കാണാം.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Featured Business Video Ads',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 10),
          const AdminCustomAdWidget(),
          const SizedBox(height: 16),
          const Text(
            'Sponsored Community Notices',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 10),
          const NativeAdCard(isStatusLayout: true),
          const SizedBox(height: 16),
          const NativeAdCard(),
          const SizedBox(height: 24),
          const AppFooter(),
        ],
      ),
    );
  }
}
