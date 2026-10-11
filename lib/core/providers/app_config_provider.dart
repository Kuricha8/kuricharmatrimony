import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfigProvider with ChangeNotifier {
  static const String _configId = '00000000-0000-0000-0000-000000000000';

  Map<String, dynamic> visualTheme = {
    'primary_color': '#000080',
    'accent_color': '#FFC107',
    'festival_mode': false,
  };

  Map<String, dynamic> brandAssets = {
    'splash_logo_url': null,
    'banner_slider_images': [],
  };

  Map<String, dynamic> contactInfo = {
    'support_phone': '+919876543210',
    'support_whatsapp': '+919876543210',
    'help_email': 'support@kurichiyarmatrimony.com',
  };

  Map<String, dynamic> pricingTiers = {
    'plans': [],
    'discounts': [],
    'free_contact_limits': 5,
  };

  Map<String, dynamic> systemSwitches = {
    'maintenance_mode': false,
    'force_update_min_version': '1.0.0',
    'auto_approve_profiles': false,
  };

  bool isLoading = true;

  AppConfigProvider() {
    _fetchConfig();
  }

  Future<void> _fetchConfig() async {
    try {
      final response = await Supabase.instance.client
          .from('app_configs')
          .select()
          .eq('id', _configId)
          .maybeSingle();

      if (response != null) {
        visualTheme = response['visual_theme'] ?? visualTheme;
        brandAssets = response['brand_assets'] ?? brandAssets;
        contactInfo = response['contact_info'] ?? contactInfo;
        pricingTiers = response['pricing_tiers'] ?? pricingTiers;
        systemSwitches = response['system_switches'] ?? systemSwitches;
      }
    } catch (e) {
      debugPrint('Error fetching App Configs: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Update Configs globally
  Future<void> updateConfig(String column, Map<String, dynamic> data) async {
    try {
      await Supabase.instance.client
          .from('app_configs')
          .update({column: data})
          .eq('id', _configId);

      if (column == 'visual_theme') visualTheme = data;
      if (column == 'brand_assets') brandAssets = data;
      if (column == 'contact_info') contactInfo = data;
      if (column == 'pricing_tiers') pricingTiers = data;
      if (column == 'system_switches') systemSwitches = data;

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating App Configs: $e');
      rethrow;
    }
  }

  // Helper Methods
  Color get primaryColor {
    try {
      final hex = visualTheme['primary_color'].toString().replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF000080); // Default Navy
    }
  }

  Color get accentColor {
    try {
      final hex = visualTheme['accent_color'].toString().replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFFFFC107); // Default Amber
    }
  }
}
