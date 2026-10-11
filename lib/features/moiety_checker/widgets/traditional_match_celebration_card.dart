import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/services/admin_moiety_prompt_service.dart';
import '../../../core/services/clan_matching_engine.dart';

/// Highly aesthetic traditional Kerala celebration card for Moiety Checker results.
///
/// Features:
/// 1. Yes Match:
///    - Cascading golden confetti & fragrant Jasmine petals shower animation.
///    - Background motif: Kerala Kalyana Mandapam, lit Nilavilakku & Dambathikal illustration.
///    - Border: Festive Kerala Kasavu golden zari & temple mural border.
///    - Typography: Glowing oversized Malayalam script ("അത്യുത്തമം! പൊരുത്തമുണ്ട്!").
///
/// 2. No Match:
///    - Warm terracotta, earthy brown & ochre heritage tones.
///    - Background motif: Kerala ancestral Tharavadu house illustration with heredity symbolism.
///    - Border: Carved teakwood & terracotta architectural border.
///    - Typography: Dignified, respectful oversized script ("പൊരുത്തം കാണുന്നില്ല").
///
/// 3. Floating glass overlay subtitle card strictly displaying the chosen Admin voice dialogue.
class TraditionalMatchCelebrationCard extends StatefulWidget {
  final bool isMatch;
  final MoietyMatchResult? matchResult;
  final AdminMoietyPrompt? prompt;
  final String dialogue;
  final bool isPlayingAudio;
  final VoidCallback onToggleSpeaker;
  final VoidCallback? onReplay;

  const TraditionalMatchCelebrationCard({
    super.key,
    required this.isMatch,
    this.matchResult,
    this.prompt,
    required this.dialogue,
    required this.isPlayingAudio,
    required this.onToggleSpeaker,
    this.onReplay,
  });

  @override
  State<TraditionalMatchCelebrationCard> createState() =>
      _TraditionalMatchCelebrationCardState();
}

class _TraditionalMatchCelebrationCardState
    extends State<TraditionalMatchCelebrationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final List<_ShowerParticle> _particles;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    final rng = Random();
    // 36 particles (mix of Jasmine flowers and golden kasavu confetti)
    _particles = List.generate(36, (i) {
      return _ShowerParticle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 8.0 + rng.nextDouble() * 12.0,
        speed: 0.15 + rng.nextDouble() * 0.25,
        swaySpeed: 1.5 + rng.nextDouble() * 2.5,
        rotationSpeed: 0.5 + rng.nextDouble() * 2.0,
        swayAmplitude: 0.04 + rng.nextDouble() * 0.06,
        isJasmine: (i % 2 == 0),
        goldHueShift: rng.nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMatch = widget.isMatch;
    final bgAsset = isMatch
        ? 'assets/images/kerala_match_celebration.jpg'
        : 'assets/images/kerala_tharavadu_heritage.jpg';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isMatch
                ? const Color(0xFFFFA000).withValues(alpha: 0.28)
                : const Color(0xFF8D4925).withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // 1. Background Traditional Artwork
            Positioned.fill(
              child: Image.asset(
                bgAsset,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) {
                  return CustomPaint(
                    painter: _TraditionalArtworkFallbackPainter(isMatch: isMatch),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isMatch
                              ? [
                                  const Color(0xFF3E0A1E),
                                  const Color(0xFF1B020B),
                                  const Color(0xFF0F0107),
                                ]
                              : [
                                  const Color(0xFF3E2010),
                                  const Color(0xFF2A1408),
                                  const Color(0xFF1C0D05),
                                ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 2. Translucent Tint Gradient Overlay for Optimal Text Contrast
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMatch
                        ? [
                            const Color(0xBF240513), // Deep royal crimson tint
                            const Color(0xD918020D),
                            const Color(0xF20F0107),
                          ]
                        : [
                            const Color(0xB5321808), // Warm terracotta earth tint
                            const Color(0xD9220E04),
                            const Color(0xF2160902),
                          ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. Cascading Golden Confetti & Jasmine Flower Showers (Active on Yes Match)
            if (isMatch)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _JasmineConfettiPainter(
                        progress: _animController.value,
                        particles: _particles,
                      ),
                    );
                  },
                ),
              ),

            // 4. Kasavu / Temple Mural Border Frame
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _KasavuBorderPainter(isMatch: isMatch),
                ),
              ),
            ),

            // 5. Main Content Layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Auspicious Heritage Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isMatch
                              ? [
                                  const Color(0xFFFFD54F).withValues(alpha: 0.25),
                                  const Color(0xFFFFA000).withValues(alpha: 0.15),
                                ]
                              : [
                                  const Color(0xFFD49B5B).withValues(alpha: 0.25),
                                  const Color(0xFF8D4925).withValues(alpha: 0.15),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isMatch
                              ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                              : const Color(0xFFE07A5F).withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isMatch
                                ? Icons.auto_awesome
                                : Icons.account_balance,
                            size: 15,
                            color: isMatch
                                ? const Color(0xFFFFD700)
                                : const Color(0xFFFFCC80),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isMatch
                                ? 'കുറിച്ച്യർ ആചാര പൊരുത്തം'
                                : 'സമുദായ ആചാര മര്യാദ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isMatch
                                  ? const Color(0xFFFFE082)
                                  : const Color(0xFFFFE0B2),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Oversized Glowing Malayalam Typography
                  Center(
                    child: Column(
                      children: [
                        Text(
                          isMatch
                              ? 'അത്യുത്തമം! പൊരുത്തമുണ്ട്!'
                              : 'പൊരുത്തം കാണുന്നില്ല',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: isMatch
                                ? const Color(0xFFFFF9C4)
                                : const Color(0xFFFFE0B2),
                            height: 1.25,
                            shadows: [
                              Shadow(
                                color: isMatch
                                    ? const Color(0xFFFFD700)
                                    : const Color(0xFFE65100),
                                blurRadius: 20,
                              ),
                              Shadow(
                                color: isMatch
                                    ? const Color(0xFFFF8F00)
                                    : const Color(0xFF8D4925),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isMatch ? '(Yes Match! ✅)' : '(No Match ❌)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: isMatch
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFFFFAB91),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (widget.matchResult != null &&
                      widget.matchResult!.titleMl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        widget.matchResult!.titleMl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isMatch
                              ? Colors.white.withValues(alpha: 0.85)
                              : Colors.white.withValues(alpha: 0.80),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Floating Frosted Glass Overlay Subtitle Card
                  _buildFloatingGlassSubtitleCard(isMatch),
                ],
              ),
            ),

            // Sleek Circular Speaker Action Button (Top-Right Corner)
            Positioned(
              top: 14,
              right: 14,
              child: _buildCircularSpeakerButton(size: 40),
            ),
          ],
        ),
      ),
    );
  }

  /// Sleek Circular Speaker Action Button (Green on Active / Red on Mute)
  Widget _buildCircularSpeakerButton({double size = 40}) {
    final bool isPlaying = widget.isPlayingAudio;
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: isPlaying ? 'ശബ്ദം നിർത്തുക (Mute)' : 'ശബ്ദം കേൾക്കുക (Play)',
        child: InkWell(
          onTap: widget.onToggleSpeaker,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPlaying
                  ? const Color(0xFF1B5E20).withValues(alpha: 0.85)
                  : const Color(0xFF5D1010).withValues(alpha: 0.85),
              border: Border.all(
                color: isPlaying ? Colors.greenAccent : Colors.redAccent,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isPlaying
                      ? Colors.greenAccent.withValues(alpha: 0.55)
                      : Colors.redAccent.withValues(alpha: 0.40),
                  blurRadius: isPlaying ? 12 : 8,
                  spreadRadius: isPlaying ? 2 : 1,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                isPlaying
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: isPlaying ? Colors.greenAccent : Colors.redAccent,
                size: size * 0.52,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a floating frosted glass overlay with synchronized Malayalam subtitle dialogue
  Widget _buildFloatingGlassSubtitleCard(bool isMatch) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMatch
                  ? const Color(0xFFFFD700).withValues(alpha: 0.45)
                  : const Color(0xFFE07A5F).withValues(alpha: 0.40),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row inside Subtitle Card
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isMatch
                          ? const Color(0xFFFFD700).withValues(alpha: 0.20)
                          : const Color(0xFFE07A5F).withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isPlayingAudio
                          ? Icons.graphic_eq_rounded
                          : Icons.record_voice_over_rounded,
                      size: 16,
                      color: isMatch
                          ? const Color(0xFFFFE082)
                          : const Color(0xFFFFCC80),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isMatch
                          ? 'സന്ദേശം (Admin Voice Prompt)'
                          : 'ഉപദേശം (Admin Guidance)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isMatch
                            ? const Color(0xFFFFE082)
                            : const Color(0xFFFFCC80),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  // Sleek Circular Speaker Action Button next to Malayalam Subtitle
                  _buildCircularSpeakerButton(size: 34),
                ],
              ),

              const SizedBox(height: 10),

              // Malayalam Subtitle Text (Strictly synchronized with voice dialogue)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  widget.dialogue.isNotEmpty
                      ? widget.dialogue
                      : (isMatch
                          ? 'വിവാഹത്തിന് അനുമതിയുണ്ട്!'
                          : 'പൊരുത്തമില്ലായ്മ വ്യക്തമാണ്.'),
                  key: ValueKey<String>(widget.dialogue),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Particle model for cascading golden confetti ribbons & white Jasmine flowers
class _ShowerParticle {
  final double x;
  double y;
  final double size;
  final double speed;
  final double swaySpeed;
  final double rotationSpeed;
  final double swayAmplitude;
  final bool isJasmine;
  final double goldHueShift;

  _ShowerParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.swaySpeed,
    required this.rotationSpeed,
    required this.swayAmplitude,
    required this.isJasmine,
    required this.goldHueShift,
  });
}

/// CustomPainter that animates cascading golden confetti & Jasmine flowers showers
class _JasmineConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ShowerParticle> particles;

  _JasmineConfettiPainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final petalPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;

    final petalCenterPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;

    final greenCalyxPaint = Paint()
      ..color = const Color(0xFF66BB6A).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    for (final p in particles) {
      // Calculate current vertical position and continuous loop
      final curY = (p.y + progress * p.speed) % 1.0;
      final curX = (p.x + sin((progress * p.swaySpeed + p.x) * 2 * pi) * p.swayAmplitude)
          .clamp(0.0, 1.0);

      final px = curX * size.width;
      final py = curY * size.height;
      final angle = (progress * p.rotationSpeed * 2 * pi) + p.x * 10;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(angle);

      if (p.isJasmine) {
        // Draw 5-Petal Kerala Jasmine Blossom (Mulla Poovu)
        final r = p.size * 0.45;
        // Tiny green calyx
        canvas.drawCircle(Offset.zero, r * 0.35, greenCalyxPaint);

        // 5 delicate white petals
        for (int i = 0; i < 5; i++) {
          final petalAngle = i * (2 * pi / 5);
          final ox = cos(petalAngle) * (r * 0.7);
          final oy = sin(petalAngle) * (r * 0.7);
          canvas.drawOval(
            Rect.fromCenter(center: Offset(ox, oy), width: r * 0.8, height: r * 1.3),
            petalPaint,
          );
        }
        // Golden center dot
        canvas.drawCircle(Offset.zero, r * 0.25, petalCenterPaint);
      } else {
        // Draw Kasavu Gold Confetti Ribbon / Flake
        final goldColor = p.goldHueShift > 0.5
            ? const Color(0xFFFFD700)
            : const Color(0xFFFFA000);
        final confettiPaint = Paint()
          ..color = goldColor.withValues(alpha: 0.85)
          ..style = PaintingStyle.fill;

        final w = p.size * 0.9;
        final h = p.size * 0.45 * (cos(angle * 2).abs() + 0.2); // 3D flip effect
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: h),
            const Radius.circular(2),
          ),
          confettiPaint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _JasmineConfettiPainter oldDelegate) => true;
}

/// CustomPainter rendering authentic Kerala Kasavu gold border & temple mural edge
class _KasavuBorderPainter extends CustomPainter {
  final bool isMatch;

  _KasavuBorderPainter({required this.isMatch});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const r = 22.0;

    // Outer double border
    final outerGoldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..shader = LinearGradient(
        colors: isMatch
            ? [
                const Color(0xFFBF953F),
                const Color(0xFFFCF6BA),
                const Color(0xFFB38728),
                const Color(0xFFFBF5B7),
                const Color(0xFFAA771C),
              ]
            : [
                const Color(0xFF8D4925),
                const Color(0xFFD35400),
                const Color(0xFF5C2C16),
                const Color(0xFFD49B5B),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(r)),
      outerGoldPaint,
    );

    // Inner thin border (Kasavu Kara effect)
    final innerGoldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = isMatch
          ? const Color(0xFFFFD700).withValues(alpha: 0.45)
          : const Color(0xFFE07A5F).withValues(alpha: 0.40);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(7), const Radius.circular(r - 5)),
      innerGoldPaint,
    );

    // Auspicious Corner Zari Accents
    final cornerAccentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = isMatch ? const Color(0xFFFFD700) : const Color(0xFFFFAB91);

    const cornerSize = 14.0;
    // Top-Left
    canvas.drawLine(const Offset(10, 10), const Offset(10 + cornerSize, 10), cornerAccentPaint);
    canvas.drawLine(const Offset(10, 10), const Offset(10, 10 + cornerSize), cornerAccentPaint);

    // Top-Right
    canvas.drawLine(Offset(size.width - 10, 10), Offset(size.width - 10 - cornerSize, 10), cornerAccentPaint);
    canvas.drawLine(Offset(size.width - 10, 10), Offset(size.width - 10, 10 + cornerSize), cornerAccentPaint);

    // Bottom-Left
    canvas.drawLine(Offset(10, size.height - 10), Offset(10 + cornerSize, size.height - 10), cornerAccentPaint);
    canvas.drawLine(Offset(10, size.height - 10), Offset(10, size.height - 10 - cornerSize), cornerAccentPaint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width - 10, size.height - 10), Offset(size.width - 10 - cornerSize, size.height - 10), cornerAccentPaint);
    canvas.drawLine(Offset(size.width - 10, size.height - 10), Offset(size.width - 10, size.height - 10 - cornerSize), cornerAccentPaint);
  }

  @override
  bool shouldRepaint(covariant _KasavuBorderPainter oldDelegate) =>
      oldDelegate.isMatch != isMatch;
}

class _TraditionalArtworkFallbackPainter extends CustomPainter {
  final bool isMatch;
  const _TraditionalArtworkFallbackPainter({required this.isMatch});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.35);

    // Warm radial glow in background
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: isMatch
            ? [
                const Color(0x33FFB300),
                const Color(0x15FF6F00),
                Colors.transparent,
              ]
            : [
                const Color(0x28FF7043),
                const Color(0x108D4925),
                Colors.transparent,
              ],
        radius: 0.8,
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.6));

    canvas.drawCircle(center, size.width * 0.6, glowPaint);

    // Decorative traditional temple arch / mandapam arches
    final archPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = isMatch
          ? const Color(0x22FFD700)
          : const Color(0x1FFFAB91);

    for (int i = 1; i <= 3; i++) {
      final r = size.width * (0.2 + i * 0.12);
      canvas.drawCircle(center, r, archPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TraditionalArtworkFallbackPainter oldDelegate) =>
      oldDelegate.isMatch != isMatch;
}

