enum Gender { male, female }

enum MaritalStatus { first, remarriage2nd, remarriage3rdPlus }

enum AccountStatus {
  pending,
  agentReview,
  adminReview,
  approved,
  rejected,
  banned,
}

enum ClanPhotoStatus { pending, approved, rejected }

enum ProfileStatus { active, married }

/// Subscription tiers with pricing and view quotas.
/// Free    → no subscription, no full-detail access
/// tier1   → 3 months / ₹210  / 10  unique profile views (auto-extends until quota consumed)
/// tier2   → 6 months / ₹510  / 20  unique profile views (auto-extends until quota consumed)
/// tier3   → Lifelong / ₹3010 / unlimited views, no expiry, VIP priority listing + golden badge
enum SubscriptionTier { free, tier1, tier2, tier3, stealth }

/// Type of media attached to a clan feed post.
enum PostType { text, video, photo, audio, promotion }

/// Notification types
enum NotificationType {
  adminBroadcast,
  newMatch,
  interestAlert,
  newMessage,
  agreementSigned,
  paymentSuccess,
  subscriptionActive,
}

/// Mutual Agreement & Arbitration Logic status
enum DisputeStatus {
  none,
  pendingReview,
  resolvedBrideDefaulted,
  resolvedGroomDefaulted,
}
