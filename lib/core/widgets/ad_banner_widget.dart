import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ad_status_service.dart';
import '../utils/mock_data.dart';

class AdBannerWidget extends StatefulWidget {
  final String adUnitId;
  final AdSize size;
  final String? customBannerUrl;
  final String? redirectUrl;

  const AdBannerWidget({
    super.key,
    this.adUnitId = 'ca-app-pub-3940256099942544/6300978111', // Test Banner ID
    this.size = AdSize.banner,
    this.customBannerUrl,
    this.redirectUrl,
  });

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isPremium = false;
  bool _isCheckingStatus = true;
  String? _supabaseBannerUrl;
  String? _supabaseTargetUrl;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionAndLoadAd();
    _fetchSupabaseCustomAd();
  }

  Future<void> _fetchSupabaseCustomAd() async {
    try {
      if (widget.customBannerUrl != null &&
          widget.customBannerUrl!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _supabaseBannerUrl = widget.customBannerUrl;
            _supabaseTargetUrl = widget.redirectUrl;
          });
        }
        return;
      }

      // 1. Fetch promotional banner from registration_fee_settings
      final res = await Supabase.instance.client
          .from('registration_fee_settings')
          .select()
          .limit(2);

      if (res.isNotEmpty) {
        for (var row in res) {
          final url = row['banner_url'] as String?;
          if (url != null && url.isNotEmpty) {
            if (mounted) {
              setState(() {
                _supabaseBannerUrl = url;
              });
            }
            break;
          }
        }
      }

      // 2. Fallback to active coin slot promotions if available
      if (_supabaseBannerUrl == null || _supabaseBannerUrl!.isEmpty) {
        final slots = await Supabase.instance.client
            .from('coin_ad_slots')
            .select('image_url')
            .eq('status', 'active')
            .limit(1);

        if (slots.isNotEmpty && slots[0]['image_url'] != null) {
          if (mounted) {
            setState(() {
              _supabaseBannerUrl = slots[0]['image_url'] as String?;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching custom Supabase ad banner: $e');
    }
  }

  void _checkSubscriptionAndLoadAd() {
    final isPremium = AdStatusService.instance.isPremiumUser;
    if (isPremium) {
      if (mounted) {
        setState(() {
          _isPremium = true;
          _isCheckingStatus = false;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _isPremium = false;
        _isCheckingStatus = false;
      });
      if (!kIsWeb) {
        _loadAd();
      }
    }
  }

  void _loadAd() {
    if (kIsWeb) return;
    try {
      _bannerAd = BannerAd(
        adUnitId: widget.adUnitId,
        request: const AdRequest(),
        size: widget.size,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, err) {
            debugPrint('BannerAd failed to load: $err');
            ad.dispose();
            if (mounted) {
              setState(() {
                _bannerAd = null;
                _isLoaded = false;
              });
            }
          },
        ),
      )..load();
    } catch (e) {
      debugPrint('Error initializing BannerAd: $e');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _handleBannerClick() async {
    if (_supabaseTargetUrl != null && _supabaseTargetUrl!.isNotEmpty) {
      final uri = Uri.tryParse(_supabaseTargetUrl!);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Default: Navigate to Premium / Subscription upgrade screen
    final me = MockData().currentUser;
    if (me != null && mounted) {
      Navigator.pushNamed(context, '/subscriptions', arguments: me);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium || _isCheckingStatus) return const SizedBox.shrink();

    // 1. If mobile Google AdMob is successfully loaded, show it
    if (!kIsWeb && _isLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // 2. Custom Supabase Promotional Banner (Web and Mobile fallback)
    if (_supabaseBannerUrl != null && _supabaseBannerUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: _handleBannerClick,
        child: Container(
          width: double.infinity,
          height: widget.size.height > 60 ? widget.size.height.toDouble() : 72,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            image: DecorationImage(
              image: NetworkImage(_supabaseBannerUrl!),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Subtle gradient overlay for readability
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              // "Sponsored / പരസ്യം" badge
              Positioned(
                top: 6,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Sponsored',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Fallback Matrimonial Premium Promo Banner
    return GestureDetector(
      onTap: _handleBannerClick,
      child: Container(
        width: double.infinity,
        height: widget.size.height > 60 ? widget.size.height.toDouble() : 68,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F1B80), Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F1B80).withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Color(0xFFFFD700),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'കുറിച്ച്യർ മാട്രിമോണി പ്രീമിയം',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'നേരിട്ടുള്ള കോൺടാക്റ്റ് & ജാതക പൊരുത്തം കാണാം',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Unlock',
                style: TextStyle(
                  color: Color(0xFF000B4F),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
