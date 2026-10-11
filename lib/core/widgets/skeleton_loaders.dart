import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SkeletonProfileCard extends StatelessWidget {
  const SkeletonProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child:
          Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mock Image Area
                  Container(
                    height: 180,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Placeholder
                        Container(width: 200, height: 20, color: Colors.grey),
                        const SizedBox(height: 12),
                        // Father Clan Placeholder
                        Container(width: 150, height: 14, color: Colors.grey),
                        const SizedBox(height: 8),
                        // Mother Clan Placeholder
                        Container(width: 180, height: 14, color: Colors.grey),
                        const SizedBox(height: 12),
                        // Region Placeholder
                        Container(width: 100, height: 14, color: Colors.grey),
                        const SizedBox(height: 16),
                        // Actions Placeholder
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 120,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: const Duration(milliseconds: 1500),
                color: Colors.white54,
              ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;

  const SkeletonList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: count,
      physics:
          const NeverScrollableScrollPhysics(), // Usually skeleton lists are part of a scrollable view or don't need independent scrolling
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return const SkeletonProfileCard();
      },
    );
  }
}
