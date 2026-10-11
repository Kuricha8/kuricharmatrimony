/// Local, offline rule-based Support Chatbot engine for Kurichiyar Matrimony.
class RuleBasedChatbotService {
  RuleBasedChatbotService._();
  static final RuleBasedChatbotService instance = RuleBasedChatbotService._();

  /// Predefined quick action FAQ chips
  static const List<String> quickActionChips = [
    "Profile Approval Status",
    "Contact Unlock / ₹49 Payment",
    "Change Tharavadu / Clan Info",
    "No Matches Showing",
    "Edit Photos & Details",
    "Talk to Live Admin",
  ];

  /// Dictionary mapping exact chip choices & keywords to comprehensive answers
  String getResponse(String userQuery) {
    final cleanQuery = userQuery.trim().toLowerCase();

    // 1. Exact Chip Matches & Keyword Routing
    if (cleanQuery.contains("approval") ||
        cleanQuery.contains("approve") ||
        cleanQuery.contains("verification") ||
        cleanQuery.contains("verify")) {
      return "📌 **Profile Approval Info**:\n\n"
          "• New profiles are reviewed by Admin within 2-24 hours.\n"
          "• Ensure your Government ID & Tharavadu details are uploaded.\n"
          "• Tap 'Check Status / Refresh' on the Matches screen to pull the latest verification status from DB.";
    }

    if (cleanQuery.contains("contact") ||
        cleanQuery.contains("unlock") ||
        cleanQuery.contains("49") ||
        cleanQuery.contains("payment") ||
        cleanQuery.contains("pay") ||
        cleanQuery.contains("cashfree")) {
      return "💳 **Contact Unlock Paywall (₹49)**:\n\n"
          "• Unlocking a member's phone number costs a single platform fee of ₹49 via Cashfree.\n"
          "• Once paid, the contact is permanently saved to your unlocked list.\n"
          "• You will NEVER be charged twice for a previously unlocked contact.";
    }

    if (cleanQuery.contains("tharavadu") ||
        cleanQuery.contains("clan") ||
        cleanQuery.contains("lineage") ||
        cleanQuery.contains("moiety")) {
      return "🛡️ **Lineage & Tharavadu Rules**:\n\n"
          "• Both Father's Tharavadu & Mother's Tharavadu are required.\n"
          "• Same Mother's Tharavadu marriage is strictly forbidden by tribal custom.\n"
          "• Use the Lineage Compatibility Checker on the Matches screen to test 2 Tharavadus instantly.";
    }

    if (cleanQuery.contains("no matches") ||
        cleanQuery.contains("match") ||
        cleanQuery.contains("empty") ||
        cleanQuery.contains("showing")) {
      return "🔍 **Why are No Matches Showing?**:\n\n"
          "• Ensure your profile status is Approved.\n"
          "• Check your Partner Preferences (Age range, Religion/Panthi).\n"
          "• Custom Tharavadu Exclusions may filter out incompatible clans.";
    }

    if (cleanQuery.contains("photo") ||
        cleanQuery.contains("edit") ||
        cleanQuery.contains("detail") ||
        cleanQuery.contains("picture")) {
      return "📸 **Profile & Photo Editing**:\n\n"
          "• Go to Profile Tab -> Edit Profile.\n"
          "• Upload clear front-facing photos.\n"
          "• Profile updates will be saved immediately to your account.";
    }

    if (cleanQuery.contains("talk to live admin") ||
        cleanQuery.contains("admin") ||
        cleanQuery.contains("human") ||
        cleanQuery.contains("executive") ||
        cleanQuery.contains("person")) {
      return "👨‍💼 **Transferring to Live Support Executive**:\n\n"
          "Connecting you with our live support team... An admin has been notified and will reply to this chat thread shortly.";
    }

    // Default Fallback Response
    return "🤖 I couldn't find an exact answer for that query.\n\n"
        "Tap 'Talk to Live Admin' below or type 'Admin' to connect directly with our support team.";
  }

  /// Check if query triggers live admin escalation
  bool isEscalationRequested(String query) {
    final q = query.trim().toLowerCase();
    return q.contains("talk to live admin") ||
        q.contains("human") ||
        q.contains("executive") ||
        q.contains("person") ||
        q == "admin";
  }
}
