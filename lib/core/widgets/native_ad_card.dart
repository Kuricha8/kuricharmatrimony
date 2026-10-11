import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/mock_data.dart';

class NativeAdCard extends StatefulWidget {
  final bool isStatusLayout;

  const NativeAdCard({super.key, this.isStatusLayout = false});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  String? _customBannerUrl;

  final String _adUnitId =
      'ca-app-pub-3940256099942544/2247696110'; // Google Test ID

  @override
  void initState() {
    super.initState();
    final mockData = MockData();
    final isPremiumUser = mockData.currentUser?.isPremium ?? false;
    if (!isPremiumUser) {
      if (!kIsWeb) {
        _loadAd();
      }
      _fetchCustomAd();
    }
  }

  Future<void> _fetchCustomAd() async {
    try {
      final res = await Supabase.instance.client
          .from('registration_fee_settings')
          .select()
          .limit(1);

      if (res.isNotEmpty && res[0]['banner_url'] != null) {
        if (mounted) {
          setState(() {
            _customBannerUrl = res[0]['banner_url'] as String?;
          });
        }
      }
    } catch (e) {
      debugPrint('Note fetching native custom ad: $e');
    }
  }

  void _loadAd() {
    if (kIsWeb) return;
    try {
      _nativeAd = NativeAd(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: widget.isStatusLayout
              ? TemplateType.medium
              : TemplateType.small,
          mainBackgroundColor: Colors.white,
          cornerRadius: 16.0,
          callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: const Color(0xFF000080),
            style: NativeTemplateFontStyle.bold,
            size: 16.0,
          ),
          primaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.black,
            backgroundColor: Colors.white,
            style: NativeTemplateFontStyle.bold,
            size: 16.0,
          ),
        ),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _nativeAd = ad as NativeAd;
                _isAdLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Ad failed to load: $error');
            ad.dispose();
            if (mounted) {
              setState(() {
                _nativeAd = null;
                _isAdLoaded = false;
              });
            }
          },
        ),
      )..load();
    } catch (e) {
      debugPrint('NativeAd load exception: $e');
    }
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MockData(),
      builder: (context, _) {
        final mockData = MockData();
        final isPremiumUser = mockData.currentUser?.isPremium ?? false;

        if (isPremiumUser) {
          return const SizedBox.shrink();
        }

        // 1. Mobile AdMob Native Ad
        if (!kIsWeb && _isAdLoaded && _nativeAd != null) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.amber.shade200, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: widget.isStatusLayout ? 320 : 120,
                maxWidth: 400,
                maxHeight: widget.isStatusLayout ? 400 : 150,
              ),
              child: AdWidget(ad: _nativeAd!),
            ),
          );
        }

        // 2. Custom Native Ad Card for Web & Mobile fallback
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade300, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1B80),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Ad',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'കുറിച്ച്യർ മാട്രിമോണി പ്രൊമോഷൻ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F1B80),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_customBannerUrl != null && _customBannerUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _customBannerUrl!,
                    height: widget.isStatusLayout ? 180 : 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => const SizedBox.shrink(),
                  ),
                )
              else
                Container(
                  height: widget.isStatusLayout ? 120 : 70,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF000B4F), Color(0xFF1E3A8A)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Colors.amber,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'അനുയോജ്യമായ ജീവിതപങ്കാളിയെ കണ്ടെത്തൂ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'പ്രീമിയം അംഗത്വം നേടൂ, കൂടുതൽ പ്രൊഫൈലുകൾ കാണൂ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final me = MockData().currentUser;
                    if (me != null && context.mounted) {
                      Navigator.pushNamed(
                        context,
                        '/subscriptions',
                        arguments: me,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F1B80),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'കൂടുതൽ അറിയാൻ / Upgrade',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
