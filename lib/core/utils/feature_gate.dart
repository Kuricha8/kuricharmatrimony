class FeatureGate {
  // 1. ചാറ്റ് സൗകര്യം ഉണ്ടോ എന്ന് നോക്കുന്നു (Gold, Diamond, Platinum, Stealth)
  static bool canChat(Map<String, dynamic> profile) {
    final tier = profile['plan_tier']?.toString().toLowerCase() ?? 'free';
    return ['gold', 'diamond', 'platinum', 'stealth'].contains(tier);
  }

  // 2. പ്രൊഫൈൽ സേർച്ചിൽ മുകളിലായി കാണിക്കണോ (Diamond & Platinum)
  static bool isBoosted(Map<String, dynamic> profile) {
    final tier = profile['plan_tier']?.toString().toLowerCase() ?? 'free';
    return tier == 'diamond' || tier == 'platinum';
  }

  // 4. ഇൻകോഗ്നിറ്റോ ആണോ (സന്ദർശിച്ചത് മറ്റുള്ളവർ കാണാതിരിക്കാൻ)
  static bool isStealth(Map<String, dynamic> profile) {
    return profile['stealth_mode'] == true || profile['plan_tier'] == 'stealth';
  }
}
