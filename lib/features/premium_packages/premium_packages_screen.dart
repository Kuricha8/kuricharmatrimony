import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import 'cashfree_service.dart';

class PremiumPackagesScreen extends StatefulWidget {
  const PremiumPackagesScreen({super.key});

  @override
  State<PremiumPackagesScreen> createState() => _PremiumPackagesScreenState();
}

class _PremiumPackagesScreenState extends State<PremiumPackagesScreen> {
  bool _isLoading = false;

  Future<void> _initiatePayment({
    required String planId,
    required String planName,
    required String tierName,
    required double orderAmount,
    required int durationMonths,
  }) async {
    setState(() => _isLoading = true);

    final user = Supabase.instance.client.auth.currentUser;
    final currentUser = MockData().currentUser;

    if (user == null &&
        (currentUser == null ||
            currentUser.role == 'guest' ||
            currentUser.id == 'guest')) {
      setState(() => _isLoading = false);
      final tier = tierName.toLowerCase().contains('diamond')
          ? SubscriptionTier.tier2
          : (tierName.toLowerCase().contains('platinum')
                ? SubscriptionTier.tier3
                : (tierName.toLowerCase().contains('stealth')
                      ? SubscriptionTier.stealth
                      : SubscriptionTier.tier1));

      MockData().setPendingCheckout(tier, planName);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('ലോഗിൻ ചെയ്യുക'),
            content: const Text(
              'സബ്‌സ്ക്രിപ്ഷൻ എടുക്കാൻ ദയവായി ലോഗിൻ ചെയ്യുക അല്ലെങ്കിൽ രജിസ്റ്റർ ചെയ്യുക.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('റദ്ദാക്കുക'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('ലോഗിൻ / രജിസ്റ്റർ'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final userId =
        user?.id ??
        currentUser?.id ??
        'cust_${DateTime.now().millisecondsSinceEpoch}';
    final customerName = currentUser?.name ?? 'Kurichiyar Member';
    final customerPhone =
        (currentUser?.guardianPhone != null &&
            currentUser!.guardianPhone!.isNotEmpty)
        ? currentUser.guardianPhone!
        : (currentUser?.publicDisplayNumber != null &&
                  currentUser!.publicDisplayNumber!.isNotEmpty
              ? currentUser.publicDisplayNumber!
              : '9999999999');
    final customerEmail =
        currentUser?.email ?? user?.email ?? '$userId@kurichiyarmatrimony.in';
    final orderId =
        'ord_${DateTime.now().millisecondsSinceEpoch}_${userId.length > 5 ? userId.substring(0, 5) : userId}';

    await CashfreeService().startPayment(
      orderId: orderId,
      orderAmount: orderAmount,
      customerId: userId,
      customerPhone: customerPhone,
      customerName: customerName,
      customerEmail: customerEmail,
      planName: planName,
      tierName: tierName,
      durationMonths: durationMonths,
      onSuccess: () async {
        debugPrint("Payment Successful for: $planName");
        final tier = tierName.toLowerCase().contains('diamond')
            ? SubscriptionTier.tier2
            : (tierName.toLowerCase().contains('platinum')
                  ? SubscriptionTier.tier3
                  : (tierName.toLowerCase().contains('stealth')
                        ? SubscriptionTier.stealth
                        : SubscriptionTier.tier1));

        await MockData().activateSubscription(
          tier,
          planTierName: tierName.toLowerCase(),
          durationMonths: durationMonths,
        );
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 $planName വിജയകരമായി ആക്റ്റീവ് ചെയ്തു!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      },
      onFailure: (errorMsg) {
        debugPrint("Payment Failed: $errorMsg");
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment Failed: $errorMsg'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MockData(),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Premium Packages'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 0. Lifetime Till Marriage Plan (₹1499 / No Expiry)
                  _buildPackageCard(
                    title: 'വിവാഹം വരെ (Till Marriage Plan)',
                    price: '₹1499',
                    duration: '/ No Expiry',
                    badgeText: 'ഏറ്റവും മികച്ച പ്ലാൻ / Best Value',
                    icon: Icons.all_inclusive,
                    accentColor: const Color(0xFFD4AF37),
                    buttonColor: const Color(0xFFD4AF37),
                    features: const [
                      'വിവാഹം വരെ കാലാവധി (Lifetime Access)',
                      'പ്ലാറ്റിനം പ്ലാനിലെ എല്ലാ സൗകര്യങ്ങളും',
                      'പരിധിയില്ലാത്ത പ്രൊഫൈൽ കാഴ്ചകൾ',
                      'നേരിട്ടുള്ള ഫോൺ നമ്പർ വിവരങ്ങൾ',
                      'വിഐപി പ്രൊഫൈൽ ബൂസ്റ്റർ & ബാഡ്ജ്',
                    ],
                    onTap: () => _initiatePayment(
                      planId: 'plan_lifetime',
                      planName: 'Till Marriage Plan',
                      tierName: 'platinum',
                      orderAmount: 1499.0,
                      durationMonths: 120,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Gold Plan (₹250 / 3 Months)
                  _buildPackageCard(
                    title: 'ഗോൾഡ് പ്ലാൻ (Gold Plan)',
                    price: '₹250',
                    duration: '/ 3 മാസം',
                    icon: Icons.star_border,
                    accentColor: const Color(0xFF3F5560),
                    buttonColor: const Color(0xFF3F5560),
                    features: const [
                      'പരിധിയില്ലാത്ത ഇൻ-ആപ്പ് ചാറ്റ്',
                      'പ്രൊഫൈൽ കാഴ്ചകൾ (പരിമിതം)',
                      'പ്രൊഫൈൽ സന്ദർശകരുടെ ലിസ്റ്റ്',
                    ],
                    onTap: () => _initiatePayment(
                      planId: 'plan_gold_3m',
                      planName: 'Gold Plan',
                      tierName: 'gold',
                      orderAmount: 250.0,
                      durationMonths: 3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Diamond Plan (₹450 / 6 Months)
                  _buildPackageCard(
                    title: 'ഡയമണ്ട് പ്ലാൻ (Diamond Plan)',
                    price: '₹450',
                    duration: '/ 6 മാസം',
                    badgeText: 'ഏറ്റവും ജനപ്രിയം',
                    icon: Icons.star,
                    accentColor: Colors.orange,
                    buttonColor: Colors.orange,
                    features: const [
                      'ഗോൾഡ് പ്ലാനിലെ എല്ലാ സൗകര്യങ്ങളും',
                      'പ്രൊഫൈൽ ബൂസ്റ്റർ (തിരച്ചിലിൽ മുൻഗണന)',
                      'പ്രൊഫൈലിൽ പ്രീമിയം ബാഡ്ജ്',
                    ],
                    onTap: () => _initiatePayment(
                      planId: 'plan_diamond_6m',
                      planName: 'Diamond Plan',
                      tierName: 'diamond',
                      orderAmount: 450.0,
                      durationMonths: 6,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Platinum Plan (₹799 / 1 Year)
                  _buildPackageCard(
                    title: 'പ്ലാറ്റിനം പ്ലാൻ (Platinum Plan)',
                    price: '₹799',
                    duration: '/ 1 വർഷം',
                    icon: Icons.military_tech,
                    accentColor: const Color(0xFFB8860B),
                    buttonColor: const Color(0xFFB8860B),
                    buttonText: 'പ്ലാൻ അപ്ഗ്രേഡ് ചെയ്യുക',
                    features: const [
                      'ഡയമണ്ട് പ്ലാനിലെ എല്ലാ സൗകര്യങ്ങളും',
                      'പരിധിയില്ലാത്ത പ്രൊഫൈൽ കാഴ്ചകൾ',
                      'നേരിട്ടുള്ള ഫോൺ നമ്പർ വിവരങ്ങൾ',
                      'മുൻഗണനാ അഡ്മിൻ സപ്പോർട്ട്',
                    ],
                    onTap: () => _initiatePayment(
                      planId: 'plan_platinum_1y',
                      planName: 'Platinum Plan',
                      tierName: 'platinum',
                      orderAmount: 799.0,
                      durationMonths: 12,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Stealth Mode (₹200 / 3 Months)
                  _buildPackageCard(
                    title: 'സ്റ്റെൽത്ത് മോഡ് (Stealth Mode)',
                    price: '₹200',
                    duration: '/ 3 മാസം',
                    icon: Icons.visibility_off,
                    accentColor: const Color(0xFF4A148C),
                    buttonColor: const Color(0xFF4A148C),
                    features: const [
                      '100% സ്വകാര്യമായി പ്രൊഫൈലുകൾ കാണാം',
                      'നിങ്ങൾ സന്ദർശിച്ചത് ആരും അറിയുകയില്ല',
                      'പരിധിയില്ലാത്ത ഇൻ-ആപ്പ് ചാറ്റ്',
                      'എല്ലാ പ്രൊഫൈൽ വിവരങ്ങളും ലഭ്യമാകും',
                    ],
                    onTap: () => _initiatePayment(
                      planId: 'plan_stealth_3m',
                      planName: 'Stealth Mode',
                      tierName: 'stealth',
                      orderAmount: 200.0,
                      durationMonths: 3,
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black38,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPackageCard({
    required String title,
    required String price,
    required String duration,
    required IconData icon,
    required Color accentColor,
    required Color buttonColor,
    required List<String> features,
    required VoidCallback onTap,
    String? badgeText,
    String buttonText = 'ഇപ്പോൾ വാങ്ങുക',
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withValues(alpha: 0.5), width: 1.5),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (badgeText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Icon(icon, size: 40, color: accentColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const Divider(height: 24),
            ...features.map(
              (feat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: accentColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(feat, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onTap,
                child: Text(
                  buttonText,
                  style: const TextStyle(
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
}
