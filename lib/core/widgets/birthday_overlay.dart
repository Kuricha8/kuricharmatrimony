import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BirthdayOverlay extends StatefulWidget {
  final String? profilePhotoUrl;
  final VoidCallback onClose;

  const BirthdayOverlay({
    super.key,
    this.profilePhotoUrl,
    required this.onClose,
  });

  @override
  State<BirthdayOverlay> createState() => _BirthdayOverlayState();
}

class _BirthdayOverlayState extends State<BirthdayOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 10),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti raining from top center
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // Straight down
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                    'Happy Birthday!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 1.seconds)
                  .slideY(begin: -0.5, end: 0),

              const SizedBox(height: 48),

              // Profile Photo with Glow
              Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.yellowAccent.withValues(alpha: 0.6),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          widget.profilePhotoUrl != null &&
                              widget.profilePhotoUrl!.isNotEmpty
                          ? NetworkImage(widget.profilePhotoUrl!)
                          : const AssetImage('assets/images/placeholder.png')
                                as ImageProvider,
                      onBackgroundImageError: (exception, stackTrace) {},
                      child:
                          widget.profilePhotoUrl == null ||
                              widget.profilePhotoUrl!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2.seconds, color: Colors.white)
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.05, 1.05),
                    duration: 1.seconds,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.05, 1.05),
                    end: const Offset(1, 1),
                    duration: 1.seconds,
                    curve: Curves.easeInOut,
                  ),

              const SizedBox(height: 64),

              ElevatedButton(
                onPressed: widget.onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Thank You!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ).animate().fadeIn(delay: 2.seconds),
            ],
          ),
        ],
      ),
    );
  }
}
