import 'package:flutter/material.dart';
import '../../../core/services/matching_service.dart';
import '../controllers/matching_controller.dart';

class MatchingFilterBar extends StatelessWidget {
  final MatchingController controller;

  const MatchingFilterBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDualSelected =
        controller.poolCategory == MatchingPoolCategory.dualSameRecalculation;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('പ്രാഥമിക പൊരുത്തം (Primary)'),
                  selected: !isDualSelected,
                  selectedColor: const Color(0xFF000080),
                  labelStyle: TextStyle(
                    color: !isDualSelected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  avatar: Icon(
                    Icons.verified_outlined,
                    size: 16,
                    color: !isDualSelected ? Colors.white : Colors.white70,
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  onSelected: (val) {
                    if (val) {
                      controller.setPoolCategory(
                        MatchingPoolCategory.primaryStandard,
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('പുനർനിർണ്ണയ പൂൾ (Dual-Lineage)'),
                  selected: isDualSelected,
                  selectedColor: Colors.deepPurple.shade700,
                  labelStyle: TextStyle(
                    color: isDualSelected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  avatar: Icon(
                    Icons.diversity_3,
                    size: 16,
                    color: isDualSelected ? Colors.white : Colors.white70,
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  onSelected: (val) {
                    if (val) {
                      controller.setPoolCategory(
                        MatchingPoolCategory.dualSameRecalculation,
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: controller.goldTrustOnly,
                  avatar: Icon(
                    Icons.workspace_premium,
                    color: controller.goldTrustOnly
                        ? Colors.brown.shade900
                        : Colors.amber.shade200,
                    size: 16,
                  ),
                  label: Text(
                    '✨ ഗോൾഡ് ട്രസ്റ്റ്',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                      color: controller.goldTrustOnly
                          ? Colors.brown.shade900
                          : Colors.white,
                    ),
                  ),
                  selectedColor: const Color(0xFFFFD700),
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: controller.goldTrustOnly
                          ? Colors.amber.shade800
                          : Colors.white30,
                    ),
                  ),
                  onSelected: (val) => controller.setGoldTrustOnly(val),
                ),
              ],
            ),
          ),
          if (isDualSelected) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.deepPurple.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ഇരട്ട-പാരമ്പര്യ പുനർനിർണ്ണയ പൂൾ: മാതാപിതാക്കൾ ഒരേ കൂട്ടത്തിൽ (പന്തി/ബന്ധു) പെട്ടവരുടെ പരസ്പര പൂരക പൊരുത്തങ്ങൾ ഇവിടെ കാണാം.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
