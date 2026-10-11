import 'dart:ui';
import 'package:flutter/material.dart';

class GlobalFeatureShowcase extends StatelessWidget {
  const GlobalFeatureShowcase({super.key});

  Widget _buildGlassCard({
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container with circular glow
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 28),
              ),
              const SizedBox(width: 18),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Indicator for "Enabled"
              Icon(Icons.check_circle, color: accentColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1128),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Subtle background pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  childAspectRatio: 1,
                ),
                itemCount: 40,
                itemBuilder: (context, index) => const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFFBF5B7),
                          Color(0xFFD4AF37),
                          Color(0xFFFFD700),
                        ],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.verified_user,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Platform Security & Rules',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Active automated protections',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildGlassCard(
                  title: 'Guest Mode Security',
                  description:
                      'When enabled, profile images are heavily blurred for non-registered/guest users to protect member privacy.',
                  icon: Icons.blur_on,
                  accentColor: Colors.cyan,
                ),
                const SizedBox(height: 16),
                _buildGlassCard(
                  title: 'Moiety Compatibility Check',
                  description:
                      'Enforce traditional cross-moiety (Panthi & Bandhu) exogamy rules in calculations and the compatibility checker tool.',
                  icon: Icons.people_outline,
                  accentColor: Colors.pinkAccent,
                ),
                const SizedBox(height: 16),
                _buildGlassCard(
                  title: 'Mura Match Rules',
                  description:
                      'Enforce traditional age gap restrictions, marital history rules, and lineage checks in the partner matching system.',
                  icon: Icons.favorite_border,
                  accentColor: Colors.orangeAccent,
                ),
                const SizedBox(height: 16),
                _buildGlassCard(
                  title: 'Compatibility Quiz System',
                  description:
                      'Show compatibility scores and dynamic partner preference questionnaires on user profile detail pages.',
                  icon: Icons.question_answer_outlined,
                  accentColor: Colors.purpleAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
