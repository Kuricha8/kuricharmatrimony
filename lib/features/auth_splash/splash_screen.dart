import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../core/widgets/logo_widget.dart';
import '../dashboard/dashboard_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLogoAnimate = false;
  bool _isTextAnimate = false;

  @override
  void initState() {
    super.initState();
    // Start Logo Animation
    Timer(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isLogoAnimate = true);
    });

    // Start Text Animation after 500ms delay
    Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isTextAnimate = true);
    });

    // Navigate to next screen after 3 seconds (+ initial delay)
    Timer(const Duration(milliseconds: 3600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const DashboardShell(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Rich Gradient Background (Dark Royal Blue to Deep Midnight Blue)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A1128), Color(0xFF000411)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Subtle Traditional Watermark Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: CustomPaint(painter: TraditionalPatternPainter()),
            ),
          ),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 2. Animated Logo with 3D Flip and Scale
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: _isLogoAnimate ? 1.0 : 0.0,
                  ),
                  duration: const Duration(milliseconds: 1800),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015) // Perspective
                        ..rotateY((1 - value) * math.pi * 2) // Spinning flip
                        ..scaleByDouble(value, value, value, 1.0), // Scale up
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFFD700,
                          ).withValues(alpha: 0.25),
                          blurRadius: 50,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const LogoWidget(width: 95, height: 95),
                  ),
                ),
                const SizedBox(height: 45),

                // 3. Elegant Text Appearance with Gold/White Palette
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 1200),
                  opacity: _isTextAnimate ? 1 : 0,
                  curve: Curves.easeIn,
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFBF5B7),
                            Color(0xFFD4AF37),
                            Color(0xFFFFD700),
                            Color(0xFFD4AF37),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'KURICHIYAR MATRIMONY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Preserving Heritage, Connecting Souls',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.2,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Circular Loading Indicator and Transition Footer
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 1500),
              opacity: _isTextAnimate ? 1 : 0,
              child: Column(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'TRUSTED COMMUNITY NETWORK',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TraditionalPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4;

    const double spacing = 75.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        final center = Offset(x, y);
        final path = Path()
          ..moveTo(center.dx, center.dy - 12)
          ..lineTo(center.dx + 12, center.dy)
          ..lineTo(center.dx, center.dy + 12)
          ..lineTo(center.dx - 12, center.dy)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
