import '../../core/models/models.dart';

// ---------------------------------------------------------------------------
// Malayalam string constants — all visible text in Malayalam
// ---------------------------------------------------------------------------

/// Subscription tier display names (Malayalam)
const kTierNameFree = 'സൗജന്യ';
const kTierNameTier1 = 'Gold Plan (Basic)';
const kTierNameTier2 = 'Diamond Plan (Recommended)';
const kTierNameTier3 = 'Platinum Plan (Premium)';

/// Pricing display (Malayalam)
const kPriceTier1 = '₹250';
const kPriceTier2 = '₹450';
const kPriceTier3 = '₹799';
const kPriceStealth = '₹200';

/// View quota display
String quotaLabel(UserProfile user) {
  if (user.subscriptionTier == SubscriptionTier.tier3) {
    return 'അൺലിമിറ്റഡ് പ്രൊഫൈൽ വ്യൂ'; // Unlimited profile views
  }
  if (user.subscriptionTier == SubscriptionTier.free) {
    return 'സബ്‌സ്ക്രിപ്ഷൻ ഇല്ല'; // No subscription
  }
  final used = user.profileViewsUsed;
  final quota = user.viewQuota;
  final remaining = user.viewsRemaining;
  return '$used / $quota പ്രൊഫൈലുകൾ കണ്ടു • $remaining ബാക്കി';
  // "X / Y profiles viewed • Z remaining"
}

/// Auto-extension alert (Malayalam)
String extensionAlert(UserProfile user) {
  if (!user.isSubscriptionActive) return '';
  final end = user.subscriptionEndDate;
  if (end == null) return '';
  final expired = DateTime.now().isAfter(end);
  if (expired && user.viewsRemaining > 0) {
    return 'സബ്‌സ്ക്രിപ്ഷൻ കാലാവധി കഴിഞ്ഞു, '
        'എന്നാൽ ${user.viewsRemaining} പ്രൊഫൈൽ വ്യൂ ബാക്കിയുള്ളതിനാൽ '
        'സ്വയം നീട്ടി.';
    // "Subscription expired, but auto-extended as N views remain."
  }
  return '';
}

/// Paywall message — quota exhausted (Malayalam)
const kQuotaExhaustedMsg =
    'നിങ്ങളുടെ പ്രൊഫൈൽ കാഴ്ച പരിധി തീർന്നു.\n'
    'കൂടുതൽ കാണുന്നതിന് പ്ലാൻ അപ്‌ഗ്രേഡ് ചെയ്യുക.';
// "Your profile view quota is exhausted. Upgrade to see more."

/// Subscription lapsed message (Malayalam)
const kSubscriptionLapsedMsg =
    'നിങ്ങളുടെ സബ്‌സ്ക്രിപ്ഷൻ അവസാനിച്ചു.\n'
    'തുടരാൻ ദയവായി പുതുക്കുക.';
// "Your subscription has ended. Please renew to continue."

/// No subscription message (Malayalam)
const kNoSubscriptionMsg =
    'ഈ പ്രൊഫൈൽ പൂർണ്ണമായി കാണണമെങ്കിൽ\n'
    'ഒരു പ്ലാൻ തിരഞ്ഞെടുക്കുക.';
// "Choose a plan to view this profile in full."

/// Upgrade CTA button (Malayalam)
const kUpgradeBtn = 'അപ്‌ഗ്രേഡ് ചെയ്യുക';
const kRenewBtn = 'പുതുക്കുക';
const kViewFullBtn = 'പൂർണ്ണ വിവരങ്ങൾ കാണുക';
const kUpgradeNow = 'ഇപ്പോൾ അപ്‌ഗ്രേഡ് ചെയ്യുക';

// ---------------------------------------------------------------------------
// SubscriptionService — pure business logic, no Flutter dependencies
// ---------------------------------------------------------------------------

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  // ── Tier metadata ──────────────────────────────────────────────────────

  String tierName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return kTierNameFree;
      case SubscriptionTier.tier1:
        return kTierNameTier1;
      case SubscriptionTier.tier2:
        return kTierNameTier2;
      case SubscriptionTier.tier3:
        return kTierNameTier3;
      case SubscriptionTier.stealth:
        return 'Stealth Mode';
    }
  }

  String tierPrice(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return '—';
      case SubscriptionTier.tier1:
        return kPriceTier1;
      case SubscriptionTier.tier2:
        return kPriceTier2;
      case SubscriptionTier.tier3:
        return kPriceTier3;
      case SubscriptionTier.stealth:
        return '₹250 / 3 Months';
    }
  }

  // ── View gate ──────────────────────────────────────────────────────────

  /// Checks if [viewer] can open full details of [targetProfileId].
  ///
  /// Rules:
  /// - Free tier → always blocked
  /// - Already viewed profile → always allowed (re-view is free)
  /// - Tier3 → always allowed (unlimited, lifelong)
  /// - Tier1/2 → allowed if isSubscriptionActive AND quota not exhausted
  bool canViewProfile(UserProfile viewer, String targetProfileId) {
    return viewer.canViewProfile(targetProfileId);
  }

  /// Records that [viewer] has unlocked [targetProfileId].
  ///
  /// If the profile is already in [viewedProfileIds], returns unchanged
  /// (idempotent — no double-counting).
  UserProfile consumeView(UserProfile viewer, String targetProfileId) {
    if (viewer.viewedProfileIds.contains(targetProfileId)) return viewer;
    if (viewer.subscriptionTier == SubscriptionTier.free) return viewer;
    if (viewer.subscriptionTier == SubscriptionTier.tier3) {
      // Unlimited: record for history but no quota impact
      final updated = List<String>.from(viewer.viewedProfileIds)
        ..add(targetProfileId);
      return viewer.copyWith(viewedProfileIds: updated);
    }
    if (!viewer.isSubscriptionActive) return viewer;
    if (viewer.viewsRemaining <= 0) return viewer;

    final updated = List<String>.from(viewer.viewedProfileIds)
      ..add(targetProfileId);
    return viewer.copyWith(viewedProfileIds: updated);
  }

  // ── Priority listing sort ──────────────────────────────────────────────

  /// Sorts [profiles] by priority score descending.
  ///
  /// Tier3 (Lifelong/VIP) profiles are ALWAYS pinned at the absolute top
  /// across all search results, discovery tabs, and matching lists.
  List<UserProfile> sortByPriority(List<UserProfile> profiles) {
    final sorted = List<UserProfile>.from(profiles);
    sorted.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return sorted;
  }

  // ── Subscription activation (for mock upgrade flow) ───────────────────

  /// Activates a subscription tier on [user].
  /// Sets start date to now, end date based on tier duration.
  UserProfile activateTier(UserProfile user, SubscriptionTier tier) {
    final now = DateTime.now();
    DateTime? endDate;
    switch (tier) {
      case SubscriptionTier.tier1:
        endDate = DateTime(now.year, now.month + 3, now.day);
        break;
      case SubscriptionTier.tier2:
        endDate = DateTime(now.year, now.month + 6, now.day);
        break;
      case SubscriptionTier.tier3:
        endDate = DateTime(now.year + 1, now.month, now.day);
        break;
      case SubscriptionTier.free:
        break;
      case SubscriptionTier.stealth:
        endDate = DateTime(now.year, now.month + 3, now.day);
        break;
    }
    return user.copyWith(
      subscriptionTier: tier,
      viewedProfileIds: [],
      subscriptionStartDate: now,
      subscriptionEndDate: endDate,
    );
  }

  // ── Malayalam status text helpers ─────────────────────────────────────

  String quotaText(UserProfile user) => quotaLabel(user);

  String extensionText(UserProfile user) => extensionAlert(user);

  /// Full Malayalam status breakdown for the subscription info chip.
  String statusSummary(UserProfile user) {
    if (user.subscriptionTier == SubscriptionTier.free) {
      return kNoSubscriptionMsg;
    }
    if (user.subscriptionTier == SubscriptionTier.tier3) {
      return 'ആജീവനാന്ത അംഗത്വം • അൺലിമിറ്റഡ് • VIP';
      // "Lifelong membership • Unlimited • VIP"
    }
    final ext = extensionText(user);
    final quota = quotaText(user);
    if (ext.isNotEmpty) return '$quota\n$ext';
    return quota;
  }
}
