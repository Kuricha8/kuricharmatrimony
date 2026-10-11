import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Predefined premium gradient palettes preventing adjacent color collisions
class AvatarRingPalettes {
  static const List<List<Color>> allPalettes = [
    // Palette 1: Sunset Fire (Coral Orange, Deep Red, Gold)
    [Color(0xFFFF512F), Color(0xFFDD2476), Color(0xFFFFD200)],
    // Palette 2: Electric Cyan (Neon Turquoise, Royal Blue, Violet)
    [Color(0xFF00F2FE), Color(0xFF4FACFE), Color(0xFF7F00FF)],
    // Palette 3: Emerald Glow (Mint Green, Electric Emerald, Lime)
    [Color(0xFF00F5A0), Color(0xFF00D9F5), Color(0xFFA8FF78)],
    // Palette 4: Cyber Violet (Neon Purple, Magenta, Bright Rose)
    [Color(0xFFB000FF), Color(0xFFFF007F), Color(0xFFFF416C)],
    // Palette 5: Golden Sunrise (Amber, Deep Gold, Warm Copper)
    [Color(0xFFFFB300), Color(0xFFFF7043), Color(0xFFFFD54F)],
  ];

  /// Special Theme for "My Status" or VIP group avatars
  static const List<Color> myStatusSpecial = [
    Color(0xFFFFD700), // Gold
    Color(0xFF00E676), // Emerald
    Color(0xFF00B0FF), // Electric Blue
    Color(0xFFFFD700),
  ];

  static List<Color> getPaletteForIndex(int index) {
    return allPalettes[index % allPalettes.length];
  }
}

/// High-performance rotating animated gradient ring widget for status and group avatars
class AnimatedGradientAvatarRing extends StatefulWidget {
  final Widget child;
  final double radius;
  final double borderWidth;
  final int paletteIndex;
  final bool isMyStatus;
  final bool hasActiveStatus;
  final Duration rotationDuration;

  const AnimatedGradientAvatarRing({
    super.key,
    required this.child,
    this.radius = 26,
    this.borderWidth = 2.5,
    this.paletteIndex = 0,
    this.isMyStatus = false,
    this.hasActiveStatus = true,
    this.rotationDuration = const Duration(seconds: 4),
  });

  @override
  State<AnimatedGradientAvatarRing> createState() =>
      _AnimatedGradientAvatarRingState();
}

class _AnimatedGradientAvatarRingState extends State<AnimatedGradientAvatarRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.rotationDuration,
    );
    if (widget.hasActiveStatus) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedGradientAvatarRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasActiveStatus && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.hasActiveStatus && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasActiveStatus) {
      // Inactive / No story state: simple clean border
      return Container(
        padding: EdgeInsets.all(widget.borderWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey.shade300,
            width: widget.borderWidth,
          ),
        ),
        child: widget.child,
      );
    }

    final colors = widget.isMyStatus
        ? AvatarRingPalettes.myStatusSpecial
        : AvatarRingPalettes.getPaletteForIndex(widget.paletteIndex);

    final glowColor = colors.first.withValues(alpha: 0.35);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: glowColor, blurRadius: 6, spreadRadius: 1),
            ],
          ),
          child: CustomPaint(
            painter: _SweepGradientRingPainter(
              colors: colors,
              angle: _controller.value * 2 * math.pi,
              strokeWidth: widget.borderWidth,
            ),
            child: Padding(
              padding: EdgeInsets.all(widget.borderWidth + 2),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _SweepGradientRingPainter extends CustomPainter {
  final List<Color> colors;
  final double angle;
  final double strokeWidth;

  _SweepGradientRingPainter({
    required this.colors,
    required this.angle,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        colors: colors,
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_SweepGradientRingPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.colors != colors;
  }
}
