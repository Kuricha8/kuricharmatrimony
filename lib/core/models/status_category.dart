import 'package:flutter/material.dart';

/// Categories / Quick Badges for Tharavadu Statuses
enum StatusCategory {
  celebration(
    nameMalayalam: 'വിശേഷങ്ങൾ',
    labelFull: 'വിശേഷങ്ങൾ (Celebration)',
    color: Color(0xFF8E24AA), // Vibrant Purple
    icon: Icons.celebration_rounded,
  ),
  wedding(
    nameMalayalam: 'വിവാഹം',
    labelFull: 'വിവാഹം (Wedding)',
    color: Color(0xFFE91E63), // Romantic Rose Pink
    icon: Icons.favorite_rounded,
  ),
  notice(
    nameMalayalam: 'അറിയിപ്പ്',
    labelFull: 'അറിയിപ്പ് (Notice)',
    color: Color(0xFF000080), // Official Kurichiyar Navy Blue
    icon: Icons.campaign_rounded,
  ),
  obituary(
    nameMalayalam: 'അനുശോചനം',
    labelFull: 'അനുശോചനം (Obituary)',
    color: Color(0xFF455A64), // Respectful Charcoal
    icon: Icons.nightlight_round,
  );

  final String nameMalayalam;
  final String labelFull;
  final Color color;
  final IconData icon;

  const StatusCategory({
    required this.nameMalayalam,
    required this.labelFull,
    required this.color,
    required this.icon,
  });

  static StatusCategory? fromString(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final clean = val.toLowerCase().trim();
    if (clean.contains('celebrat') ||
        clean.contains('വിശേഷങ്ങൾ') ||
        clean.contains('വിശേഷം')) {
      return StatusCategory.celebration;
    }
    if (clean.contains('wedding') ||
        clean.contains('വിവാഹം') ||
        clean.contains('കല്യാണം') ||
        clean.contains('marriage')) {
      return StatusCategory.wedding;
    }
    if (clean.contains('notice') ||
        clean.contains('അറിയിപ്പ്') ||
        clean.contains('announcement')) {
      return StatusCategory.notice;
    }
    if (clean.contains('obituary') ||
        clean.contains('അനുശോചനം') ||
        clean.contains('മരണം') ||
        clean.contains('rip') ||
        clean.contains('condolence')) {
      return StatusCategory.obituary;
    }
    return null;
  }
}

/// Standalone badge widget displaying status category
class StatusCategoryBadge extends StatelessWidget {
  final StatusCategory category;
  final bool compact;
  final VoidCallback? onTap;

  const StatusCategoryBadge({
    super.key,
    required this.category,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: category.color.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            category.icon,
            size: compact ? 12 : 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            compact ? category.nameMalayalam : category.labelFull,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: badge,
      );
    }
    return badge;
  }
}
