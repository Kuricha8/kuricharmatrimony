import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class PaymentCelebrationDialog extends StatefulWidget {
  final String? planName;
  final String? title;
  final String? customSubtitle;
  final String? badgeText;
  final String? buttonText;
  final VoidCallback? onDone;

  const PaymentCelebrationDialog({
    super.key,
    this.planName,
    this.title,
    this.customSubtitle,
    this.badgeText,
    this.buttonText,
    this.onDone,
  });

  @override
  State<PaymentCelebrationDialog> createState() =>
      _PaymentCelebrationDialogState();
}

class _PaymentCelebrationDialogState extends State<PaymentCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Confetti Animation setup
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _confettiController.play();

    // 2. Pulsing Glow Animation setup
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 8.0, end: 24.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleDone() {
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // ── Main Dialog Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 48),
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    widget.title ?? 'അഭിനന്ദനങ്ങൾ! 🎉',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2E7D32),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    widget.customSubtitle ??
                        (widget.planName != null && widget.planName!.isNotEmpty
                            ? 'താങ്കളുടെ ${widget.planName} വിജയകരമായി ആക്റ്റീവ് ആയിരിക്കുന്നു.'
                            : 'താങ്കളുടെ പ്രീമിയം പ്ലാൻ വിജയകരമായി ആക്റ്റീവ് ആയിരിക്കുന്നു.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Features reminder badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.badgeText ??
                                'എല്ലാ പ്രീമിയം ഫീച്ചറുകളും അൺലോക്ക് ആയി',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _handleDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(
                          0xFF2E7D32,
                        ).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.buttonText ?? 'തുടങ്ങാം',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Big Green Animated Icon with Pulsing Glow Effect
            Positioned(
              top: 0,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4CAF50,
                            ).withValues(alpha: 0.5),
                            blurRadius: _glowAnimation.value,
                            spreadRadius: _glowAnimation.value * 0.35,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Colorful Confetti Blast from Top/Center
            Positioned(
              top: -20,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                blastDirection: -pi / 2,
                emissionFrequency: 0.08,
                numberOfParticles: 35,
                maxBlastForce: 20,
                minBlastForce: 8,
                gravity: 0.25,
                colors: const [
                  Color(0xFF2E7D32),
                  Color(0xFFFFB300),
                  Color(0xFF1E88E5),
                  Color(0xFFE91E63),
                  Color(0xFF9C27B0),
                  Color(0xFFFF6F00),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
