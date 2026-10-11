import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../core/models/enums.dart';
import '../../core/utils/mock_data.dart';

class PaymentSuccessCelebrationScreen extends StatefulWidget {
  final String planName;
  final SubscriptionTier tier;
  final VoidCallback? onDone;

  const PaymentSuccessCelebrationScreen({
    super.key,
    this.planName = 'പ്രീമിയം പ്ലാൻ',
    this.tier = SubscriptionTier.tier1,
    this.onDone,
  });

  /// Static helper to trigger the full-screen celebration modal
  static Future<void> show(
    BuildContext context, {
    String planName = 'പ്രീമിയം പ്ലാൻ',
    SubscriptionTier tier = SubscriptionTier.tier1,
    VoidCallback? onDone,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'PaymentCelebration',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return PaymentSuccessCelebrationScreen(
          planName: planName,
          tier: tier,
          onDone: onDone,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<PaymentSuccessCelebrationScreen> createState() =>
      _PaymentSuccessCelebrationScreenState();
}

class _PaymentSuccessCelebrationScreenState
    extends State<PaymentSuccessCelebrationScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();

    // 1. Confetti setup — blast from top
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _confettiController.play();

    // 2. Pulsing Glow Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 12.0, end: 32.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleProceed() async {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);

    try {
      // 1. Refresh global profile and subscription state
      await MockData().activateSubscription(widget.tier);

      if (!mounted) return;

      // 2. Custom onDone callback or Navigate to Dashboard/Home
      if (widget.onDone != null) {
        widget.onDone!();
      } else {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      debugPrint('Error proceeding after payment celebration: $e');
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            // ── Full-Screen Emerald Green Gradient
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF042013),
                    Color(0xFF0F5132),
                    Color(0xFF198754),
                    Color(0xFF0B3B24),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // ── Center Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Animated Glowing Checkmark Icon Ring
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF66BB6A,
                                  ).withValues(alpha: 0.65),
                                  blurRadius: _glowAnimation.value,
                                  spreadRadius: _glowAnimation.value * 0.4,
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  blurRadius: _glowAnimation.value * 1.5,
                                  spreadRadius: _glowAnimation.value * 0.2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF0F5132),
                                size: 90,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 36),

                    // Title
                    const Text(
                      'അഭിനന്ദനങ്ങൾ! 🎉',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Subtitle
                    Text(
                      widget.planName.isNotEmpty
                          ? 'താങ്കളുടെ ${widget.planName} വിജയകരമായി ആക്റ്റീവ് ആയിരിക്കുന്നു.'
                          : 'താങ്കളുടെ പ്രീമിയം പ്ലാൻ വിജയകരമായി ആക്റ്റീവ് ആയിരിക്കുന്നു.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFE8F5E9),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Unlocked Perks Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.verified_rounded,
                            color: Color(0xFFFFD700),
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'എല്ലാ പ്രീമിയം ഫീച്ചറുകളും അൺലോക്ക് ആയി',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Action Button: "തുടങ്ങാം ->"
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isDismissing ? null : _handleProceed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F5132),
                          elevation: 6,
                          shadowColor: Colors.black.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isDismissing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF0F5132),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'തുടങ്ങാം',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 22),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── Full-Screen Top Confetti Blast
            Positioned(
              top: 0,
              left: size.width / 2,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                blastDirection: pi / 2, // Shoot downwards
                emissionFrequency: 0.08,
                numberOfParticles: 40,
                maxBlastForce: 25,
                minBlastForce: 10,
                gravity: 0.25,
                colors: const [
                  Colors.white,
                  Color(0xFFFFD700), // Gold
                  Color(0xFFFF5722), // Deep Orange
                  Color(0xFF29B6F6), // Sky Blue
                  Color(0xFFE91E63), // Pink
                  Color(0xFF81C784), // Light Green
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
