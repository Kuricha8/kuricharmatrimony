import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../utils/mock_data.dart';

class FeatureAccessService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Checks if the current user has access to a specific feature.
  /// If the feature is premium-only and the user is not premium, it shows an upgrade prompt.
  /// Returns `true` if access is granted, `false` otherwise.
  static Future<bool> checkAccess(
    BuildContext context,
    String featureName,
  ) async {
    try {
      final response = await _supabase
          .from('feature_settings')
          .select('is_premium_only, display_label')
          .eq('feature_name', featureName)
          .maybeSingle();

      if (response == null) {
        // Feature not found in DB, assume it's free/allowed by default
        return true;
      }

      final bool isPremiumOnly = response['is_premium_only'] == true;
      final String displayLabel = response['display_label'] ?? 'This Feature';

      if (!isPremiumOnly) {
        return true; // Feature is free
      }

      // Feature is premium-only. Check user's premium status.
      final user = MockData().currentUser;
      if (user == null) {
        // User not logged in, deny access
        return false;
      }

      // Check if user has a premium subscription tier
      final bool isPremiumUser = user.subscriptionTier != SubscriptionTier.free;

      if (isPremiumUser) {
        return true; // User has premium access
      }

      // User is free but feature is premium. Block access and show prompt.
      if (context.mounted) {
        _showPremiumUpgradePrompt(context, displayLabel);
      }
      return false;
    } catch (e) {
      debugPrint('Error checking feature access: $e');
      // On error, default to allowed to prevent locking out users due to network issues
      return true;
    }
  }

  static void _showPremiumUpgradePrompt(
    BuildContext context,
    String featureName,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, size: 48, color: Colors.orange),
              ),
              const SizedBox(height: 24),
              const Text(
                'Premium Upgrade Required',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Unlock "$featureName" and many other exclusive tools by upgrading to a Premium Membership today!',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Optional: Navigate to premium purchase screen
                    // Navigator.pushNamed(context, '/premium_upgrade');
                  },
                  child: const Text(
                    'Upgrade to Premium',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
