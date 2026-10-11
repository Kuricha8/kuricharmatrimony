import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../premium_packages/cashfree_service.dart';
import '../premium_packages/payment_success_celebration_screen.dart';
import '../payment/payment_status_page.dart';
import '../payment/custom_checkout_sheet.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SubscriptionPage extends StatefulWidget {
  final UserProfile currentUser;

  const SubscriptionPage({super.key, required this.currentUser});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  // ── Dynamic fee settings from DB
  bool _settingsLoading = true;
  String? _bannerUrl;
  String? _reasonText;
  double? _feeAmount;
  int? _validityMonths;
  List<String> _benefits = [];

  double _vipTier1Price = 250.0;
  double _vipTier2Price = 450.0;
  double _vipTier3Price = 799.0;

  // Payment method configs
  String _preferredPaymentMethod = 'cashfree';
  String _businessUpiId = '';

  @override
  void initState() {
    super.initState();
    _fetchFeeSettings();
  }

  Future<void> _fetchFeeSettings() async {
    try {
      // Determine gender from profile
      final gender = widget.currentUser.gender.name;

      final row = await Supabase.instance.client
          .from('registration_fee_settings')
          .select()
          .eq('gender', gender)
          .maybeSingle();

      if (row != null && mounted) {
        final rawDesc = row['description'] as String? ?? '';
        // Support both comma-separated and newline-separated benefits
        final benefits = rawDesc
            .split(RegExp(r'[,\n]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        setState(() {
          _feeAmount = (row['fee_amount'] as num?)?.toDouble();
          _validityMonths = row['validity_months'] as int?;
          _benefits = benefits;
          _reasonText = row['reason_text'] as String?;
          _bannerUrl = row['banner_url'] as String?;
          _settingsLoading = false;
        });
      } else {
        if (mounted) setState(() => _settingsLoading = false);
      }

      // Fetch dynamic VIP rates
      final systemSettings = await Supabase.instance.client
          .from('system_settings')
          .select();
      for (final row in systemSettings) {
        if (row['config_key'] == 'VIP_TIER1_PRICE') {
          _vipTier1Price =
              double.tryParse(row['config_value'].toString()) ?? 250.0;
        } else if (row['config_key'] == 'VIP_TIER2_PRICE') {
          _vipTier2Price =
              double.tryParse(row['config_value'].toString()) ?? 450.0;
        } else if (row['config_key'] == 'VIP_TIER3_PRICE') {
          _vipTier3Price =
              double.tryParse(row['config_value'].toString()) ?? 799.0;
        }
      }

      // Fetch dynamic payment settings
      final appSettingsRes = await Supabase.instance.client
          .from('admin_app_settings')
          .select('key, value');
      for (final row in appSettingsRes) {
        if (row['key'] == 'preferred_payment_method') {
          _preferredPaymentMethod = row['value'].toString();
        } else if (row['key'] == 'business_upi_id') {
          _businessUpiId = row['value'].toString();
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Fee settings fetch error: $e');
      if (mounted) setState(() => _settingsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MockData(),
      builder: (context, _) {
        final me = MockData().currentUser ?? widget.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Premium Packages',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF5C3E00),
            elevation: 1,
          ),
          backgroundColor: const Color(0xFFF9F7F3),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                // ── Admin Promotional Banner Ad Block (gender-specific)
                if (_bannerUrl != null && _bannerUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      _bannerUrl!,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (ctx, err, st) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Note: Eligible for a full refund within 4 days of purchase.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Text(
                  'നല്ലൊരു പങ്കാളിയെ കണ്ടെത്താൻ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5C3E00),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'നിങ്ങൾക്ക് ഏറ്റവും അനുയോജ്യമായ പ്ലാൻ തിരഞ്ഞെടുക്കുക.',
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // ── Limited-time Welcome Offer Banner (48h countdown) ──
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎉 വെൽക്കം ഓഫർ: പ്രത്യേക കിഴിവ്!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '48 മണിക്കൂറിനുള്ളിൽ പ്ലാൻ എടുക്കൂ, വൻ ആനുകൂല്യങ്ങൾ നേടൂ (47h:59m ബാക്കി)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Dynamic Registration Fee Plan Block
                if (_settingsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  )
                else if (_feeAmount != null) ...[
                  _buildDynamicFeeCard(),
                  const SizedBox(height: 24),
                ],

                // ── 0. Lifetime / Till Marriage Plan (Featured Best Value) ──
                _buildPricingCard(
                  tier: SubscriptionTier.tier3,
                  title: 'വിവാഹം വരെ (Till Marriage Plan)',
                  price: '₹1499',
                  rawPrice: 1499.0,
                  duration: 'വിവാഹം വരെ (No Expiry)',
                  features: [
                    'വിവാഹം വരെ കാലാവധി (Lifetime Access)',
                    'പ്ലാറ്റിനം പ്ലാനിലെ എല്ലാ സൗകര്യങ്ങളും',
                    'പരിധിയില്ലാത്ത പ്രൊഫൈൽ കാഴ്ചകൾ',
                    'നേരിട്ടുള്ള ഫോൺ നമ്പർ വിവരങ്ങൾ',
                    'വിഐപി പ്രൊഫൈൽ ബൂസ്റ്റർ & ബാഡ്ജ്',
                  ],
                  color: const Color(0xFFD4AF37),
                  icon: Icons.all_inclusive,
                  isRecommended: true,
                  isPremium: me.subscriptionTier == SubscriptionTier.tier3,
                ),
                const SizedBox(height: 20),

                _buildPricingCard(
                  tier: SubscriptionTier.tier1,
                  title: 'ഗോൾഡ് പ്ലാൻ (Gold Plan)',
                  price: '₹${_vipTier1Price.toStringAsFixed(0)}',
                  rawPrice: _vipTier1Price,
                  duration: '3 മാസം',
                  features: [
                    'പരിധിയില്ലാത്ത ഇൻ-ആപ്പ് ചാറ്റ്',
                    'പ്രൊഫൈൽ കാഴ്ചകൾ (പരിമിതം)',
                    'പ്രൊഫൈൽ സന്ദർശകരുടെ ലിസ്റ്റ്',
                  ],
                  color: Colors.blueGrey.shade700,
                  icon: Icons.star_border,
                  isPremium: me.subscriptionTier == SubscriptionTier.tier1,
                ),
                const SizedBox(height: 20),
                _buildPricingCard(
                  tier: SubscriptionTier.tier2,
                  title: 'ഡയമണ്ട് പ്ലാൻ (Diamond Plan)',
                  price: '₹${_vipTier2Price.toStringAsFixed(0)}',
                  rawPrice: _vipTier2Price,
                  duration: '6 മാസം',
                  features: [
                    'ഗോൾഡ് പ്ലാനിലെ എല്ലാ സൗകര്യങ്ങളും',
                    'പ്രൊഫൈൽ ബൂസ്റ്റർ (തിരച്ചിലിൽ മുൻഗണന)',
                    'പ്രൊഫൈലിൽ പ്രീമിയം ബാഡ്ജ്',
                  ],
                  color: Colors.amber.shade800,
                  icon: Icons.star,
                  isPremium: me.subscriptionTier == SubscriptionTier.tier2,
                ),
                const SizedBox(height: 20),
                _buildPricingCard(
                  tier: SubscriptionTier.tier3,
                  title: 'പ്ലാറ്റിനം പ്ലാൻ (Platinum Plan)',
                  price: '₹${_vipTier3Price.toStringAsFixed(0)}',
                  rawPrice: _vipTier3Price,
                  duration: '1 വർഷം',
                  features: [
                    'ഡയമണ്ട് പ്ലാനിലെ എല്ലാ സൗകര്യങ്ങളും',
                    'പരിധിയില്ലാത്ത പ്രൊഫൈൽ കാഴ്ചകൾ',
                    'നേരിട്ടുള്ള ഫോൺ നമ്പർ വിവരങ്ങൾ',
                    'മുൻഗണനാ അഡ്മിൻ സപ്പോർട്ട്',
                  ],
                  color: const Color(0xFFB8860B),
                  icon: Icons.workspace_premium,
                  isPremium: true,
                ),
                const SizedBox(height: 32),
                buildStealthPlanCard(context),
                const SizedBox(height: 32),
                _buildDisclaimer(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Dynamic registration fee card fetched from admin settings
  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                'നിരാകരണം (Disclaimer)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "ഈ പ്ലാറ്റ്ഫോം മാട്രിമോണി സേവനങ്ങൾ ലഭ്യമാക്കുന്ന ഒരു മധ്യസ്ഥൻ മാത്രമാണ്. ഇവിടെ നൽകിയിരിക്കുന്ന പ്രീമിയം സബ്സ്ക്രിപ്ഷൻ പ്രൊഫൈലുകൾ തിരയാനും, അവരുമായി ആശയവിനിമയം നടത്താനുമുള്ള സൗകര്യം മാത്രമാണ്. വിവാഹം നടക്കുമെന്നോ, അനുയോജ്യമായ പങ്കാളിയെ ഉറപ്പായി കണ്ടെത്താമെന്നോ ഉള്ള യാതൊരു ഗ്യാരണ്ടിയും ഈ പ്ലാറ്റ്ഫോം നൽകുന്നില്ല. അംഗങ്ങളുടെ വ്യക്തിഗത വിവരങ്ങളുടെ ആധികാരികത പരിശോധിക്കേണ്ടത് അവരവരുടെ ഉത്തരവാദിത്തമാണ്. പേയ്മെന്റ് നടത്തുന്നതിന് മുൻപ് ഞങ്ങളുടെ പൂർണ്ണമായ 'Terms & Conditions' വായിച്ചു മനസ്സിലാക്കുക.",
            style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicFeeCard() {
    final isFree = (_feeAmount ?? 0) == 0;
    final isFemale = widget.currentUser.gender == Gender.female;
    final accentColor = isFemale
        ? const Color(0xFFC2185B)
        : const Color(0xFF1565C0);
    final durationLabel = (_validityMonths != null)
        ? '$_validityMonths Month${_validityMonths! > 1 ? "s" : ""}'
        : 'Limited Period';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: isFree ? Colors.green : accentColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isFree ? '🎉 FREE REGISTRATION' : '📋 REGISTRATION PLAN',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Price + Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isFree ? 'FREE' : '₹${_feeAmount!.toInt()}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: isFree ? Colors.green.shade700 : Colors.black87,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/ $durationLabel',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Benefits list
          if (_benefits.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "What's included:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ..._benefits.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: accentColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Reason text
          if (_reasonText != null && _reasonText!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _reasonText!,
                      style: TextStyle(
                        fontSize: 13,
                        color: accentColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget buildStealthPlanCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A148C), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: const [
                  Icon(
                    Icons.visibility_off_rounded,
                    size: 36,
                    color: Color(0xFF4A148C),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "സ്റ്റെൽത്ത് മോഡ് (Stealth Mode)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "₹200 / 3 മാസം",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureRow("100% സ്വകാര്യമായി പ്രൊഫൈലുകൾ കാണാം"),
            _buildFeatureRow("നിങ്ങൾ സന്ദർശിച്ചത് ആരും അറിയുകയില്ല"),
            _buildFeatureRow("പരിധിയില്ലാത്ത ഇൻ-ആപ്പ് ചാറ്റ്"),
            _buildFeatureRow("എല്ലാ പ്രൊഫൈൽ വിവരങ്ങളും ലഭ്യമാകും"),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A148C),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  _handlePayment(
                    SubscriptionTier.stealth,
                    200.0,
                    "സ്റ്റെൽത്ത് മോഡ് (Stealth Mode)",
                    const Color(0xFF4A148C),
                  );
                },
                child: const Text(
                  "ഇപ്പോൾ വാങ്ങുക",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF4A148C), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required SubscriptionTier tier,
    required String title,
    required String price,
    required double rawPrice,
    required String duration,
    required List<String> features,
    required Color color,
    required IconData icon,
    bool isRecommended = false,
    bool isPremium = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRecommended || isPremium ? color : Colors.grey.shade300,
              width: isRecommended || isPremium ? 2 : 1,
            ),
            boxShadow: [
              if (isRecommended || isPremium)
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
            gradient: isPremium
                ? LinearGradient(
                    colors: [Colors.amber.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ $duration',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _handlePayment(tier, rawPrice, title, color),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isPremium ? 'പ്ലാൻ അപ്ഗ്രേഡ് ചെയ്യുക' : 'ഇപ്പോൾ വാങ്ങുക',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isRecommended)
          Positioned(
            top: -12,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ഏറ്റവും ജനപ്രിയം',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _handlePayment(
    SubscriptionTier tier,
    double rawPrice,
    String title,
    Color color,
  ) {
    if (_preferredPaymentMethod == 'upi' && _businessUpiId.isNotEmpty) {
      _showUpiQrCodeSheet(tier, rawPrice, title, color);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => CustomCheckoutSheet(
          amount: rawPrice,
          packageName: title,
          onUpiSelected: (upiId) {
            _processUpiPayment(tier, rawPrice, title, color, upiId);
          },
          onCardPayPressed:
              (cardNumber, holderName, expiryMonth, expiryYear, cvv) {
                _processCardPayment(
                  tier,
                  rawPrice,
                  title,
                  color,
                  cardNumber,
                  holderName,
                  expiryMonth,
                  expiryYear,
                  cvv,
                );
              },
        ),
      );
    }
  }

  void _showUpiQrCodeSheet(
    SubscriptionTier tier,
    double price,
    String title,
    Color color,
  ) {
    final utrController = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Complete Payment via UPI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Amount: ₹${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data:
                            'upi://pay?pa=$_businessUpiId&am=${price.toStringAsFixed(2)}&cu=INR&tn=Subscription Upgrade',
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scan the QR code above or pay directly to $_businessUpiId using any UPI app.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: utrController,
                      decoration: const InputDecoration(
                        labelText: 'Enter 12-digit UTR / Reference No.',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.receipt_long),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: submitting
                            ? null
                            : () async {
                                final utr = utrController.text.trim();
                                if (utr.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter the UTR / Reference No.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setSheetState(() => submitting = true);
                                await _submitManualUtr(tier, price, title, utr);
                                if (context.mounted) Navigator.pop(context);
                              },
                        child: submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Submit Transaction for Approval'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitManualUtr(
    SubscriptionTier tier,
    double price,
    String title,
    String utr,
  ) async {
    try {
      await Supabase.instance.client.from('manual_payments').insert({
        'user_id': widget.currentUser.id,
        'subscription_tier': tier.name,
        'amount': price,
        'utr_number': utr,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transaction submitted successfully! Waiting for admin approval.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Failed to submit manual payment: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _processUpiPayment(
    SubscriptionTier tier,
    double rawPrice,
    String title,
    Color color,
    String appName,
  ) {
    final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final double amount = (tier == SubscriptionTier.tier1)
        ? 250.0
        : (tier == SubscriptionTier.tier2)
        ? 450.0
        : (tier == SubscriptionTier.tier3)
        ? 799.0
        : (tier == SubscriptionTier.stealth)
        ? 200.0
        : rawPrice;

    final int durationMonths =
        (tier == SubscriptionTier.tier1 || tier == SubscriptionTier.stealth)
        ? 3
        : (tier == SubscriptionTier.tier2)
        ? 6
        : (tier == SubscriptionTier.tier3)
        ? 12
        : 3;

    CashfreeService().startPayment(
      orderId: orderId,
      orderAmount: amount,
      customerId: widget.currentUser.id,
      customerPhone:
          (widget.currentUser.guardianPhone != null &&
              widget.currentUser.guardianPhone!.isNotEmpty)
          ? widget.currentUser.guardianPhone!
          : (widget.currentUser.publicDisplayNumber != null &&
                    widget.currentUser.publicDisplayNumber!.isNotEmpty
                ? widget.currentUser.publicDisplayNumber!
                : '9999999999'),
      customerName: widget.currentUser.name,
      customerEmail: widget.currentUser.email.isNotEmpty
          ? widget.currentUser.email
          : '${widget.currentUser.id}@kurichiyarmatrimony.in',
      planName: tier == SubscriptionTier.tier1
          ? 'Gold Plan'
          : (tier == SubscriptionTier.tier2
                ? 'Diamond Plan'
                : (tier == SubscriptionTier.tier3 ? 'Platinum Plan' : title)),
      tierName: tier.name,
      durationMonths: durationMonths,
      onSuccess: () async {
        debugPrint("Payment Successful for Order: $orderId");

        try {
          MockData().activateSubscription(
            tier,
          ); // fallback if no handleSubscriptionSuccess
        } catch (e) {
          debugPrint('Failed to activate mock subscription: $e');
        }

        if (context.mounted) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Dismiss loader
          }
          await PaymentSuccessCelebrationScreen.show(
            context,
            tier: tier,
            planName: tier == SubscriptionTier.tier1
                ? 'ഗോൾഡ് പ്ലാൻ (Gold Plan)'
                : (tier == SubscriptionTier.tier2
                      ? 'ഡയമണ്ട് പ്ലാൻ (Diamond Plan)'
                      : title),
          );
        }
      },
      onFailure: (errorMsg) {
        debugPrint("Payment Failed: $errorMsg");
        if (context.mounted) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Dismiss loader
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Payment Failed: $errorMsg')));
        }
      },
    );
  }

  void _processCardPayment(
    SubscriptionTier tier,
    double rawPrice,
    String title,
    Color color,
    String cardNumber,
    String cardHolderName,
    String cardExpiryMonth,
    String cardExpiryYear,
    String cardCvv,
  ) {
    final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    CashfreeService().startCardPayment(
      orderId: orderId,
      orderAmount: rawPrice,
      customerId: widget.currentUser.id,
      customerPhone:
          (widget.currentUser.guardianPhone != null &&
              widget.currentUser.guardianPhone!.isNotEmpty)
          ? widget.currentUser.guardianPhone!
          : (widget.currentUser.publicDisplayNumber != null &&
                    widget.currentUser.publicDisplayNumber!.isNotEmpty
                ? widget.currentUser.publicDisplayNumber!
                : '9999999999'),
      customerName: widget.currentUser.name,
      customerEmail: widget.currentUser.email.isNotEmpty
          ? widget.currentUser.email
          : '${widget.currentUser.id}@kurichiyarmatrimony.in',
      cardNumber: cardNumber,
      cardHolderName: cardHolderName,
      cardExpiryMonth: cardExpiryMonth,
      cardExpiryYear: cardExpiryYear,
      cardCvv: cardCvv,
      planName: title,
      tierName: tier.name,
      durationMonths: (tier == SubscriptionTier.tier1)
          ? 3
          : (tier == SubscriptionTier.tier2)
          ? 6
          : 1,
      onSuccess: () async {
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context); // Dismiss loader
        }

        try {
          MockData().activateSubscription(tier); // Fallback for UI updates
        } catch (e) {
          debugPrint('Failed to activate mock subscription: $e');
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentStatusPage(
              status: PaymentStatus.success,
              packageName: title,
              onHomePressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              ),
              onRetryPressed: () {},
            ),
          ),
        );
      },
      onFailure: (errorMsg) {
        if (mounted) {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context); // Dismiss loader
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment failed or cancelled ($errorMsg). You can try again or use UTR payment.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
    );
  }
}
