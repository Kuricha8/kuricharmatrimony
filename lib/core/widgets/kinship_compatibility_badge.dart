import 'package:flutter/material.dart';
import '../services/kinship_service.dart';

/// Reusable Compatibility Badge displaying Kurichiyar Kinship & Moiety status
class KinshipCompatibilityBadge extends StatelessWidget {
  final KinshipCompatibilityResult result;
  final bool isCompact;
  final VoidCallback? onTap;

  const KinshipCompatibilityBadge({
    super.key,
    required this.result,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: result.badgeBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: result.badgeBorderColor,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                result.isAllowed
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                size: 16,
                color: result.badgeColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  result.badgeText,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: result.badgeColor,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Detailed Breakdown View
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: result.badgeBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.badgeBorderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: result.badgeColor.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Status Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: result.badgeColor.withAlpha(20),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(
                  result.isAllowed
                      ? Icons.check_circle_rounded
                      : Icons.warning_rounded,
                  color: result.badgeColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.badgeText,
                    style: TextStyle(
                      color: result.badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Moiety Comparison Pill Strip
                Row(
                  children: [
                    Expanded(
                      child: _buildLineageChip(
                        role: 'വരൻ (Groom)',
                        tharavadu: result.groomTharavaduName,
                        moiety: result.groomClanGroup,
                        isBandhu: result.groomClanGroup == 'ബന്ധു',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        result.isAllowed
                            ? Icons.swap_horiz_rounded
                            : Icons.block_rounded,
                        color: result.badgeColor,
                        size: 22,
                      ),
                    ),
                    Expanded(
                      child: _buildLineageChip(
                        role: 'വധു (Bride)',
                        tharavadu: result.brideTharavaduName,
                        moiety: result.brideClanGroup,
                        isBandhu: result.brideClanGroup == 'ബന്ധു',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Detailed Customary Reason
                Text(
                  result.detailedReason,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Colors.grey.shade800,
                  ),
                ),

                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Rule Breakdown Checklist
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.ruleBreakdown.map((rule) {
                    final bool isSuccess = rule.endsWith('✓');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isSuccess
                                ? Icons.check_circle_outline
                                : Icons.highlight_off_rounded,
                            size: 15,
                            color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              rule,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isSuccess
                                    ? Colors.green.shade900
                                    : Colors.red.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineageChip({
    required String role,
    required String tharavadu,
    required String moiety,
    required bool isBandhu,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            tharavadu,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isBandhu ? Colors.blue.shade50 : Colors.purple.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isBandhu ? Colors.blue.shade200 : Colors.purple.shade200,
              ),
            ),
            child: Text(
              moiety,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isBandhu ? Colors.blue.shade900 : Colors.purple.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
