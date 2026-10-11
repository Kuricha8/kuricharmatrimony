import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 31+ Live Animated Natural Atmospheric Overlay Presets
class AtmospherePreset {
  final String id;
  final String name;
  final String icon;
  final String category;

  const AtmospherePreset({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
  });

  static const List<AtmospherePreset> all = [
    AtmospherePreset(
      id: 'none',
      name: 'ഇല്ല (None)',
      icon: '🚫',
      category: 'General',
    ),
    AtmospherePreset(
      id: 'leaves_green',
      name: '🍃 പച്ച ഇലകൾ (Falling Green Leaves)',
      icon: '🍃',
      category: 'Nature',
    ),
    AtmospherePreset(
      id: 'leaves_autumn',
      name: '🍂 സ്വർണ്ണ ഇലകൾ (Golden Autumn Leaves)',
      icon: '🍂',
      category: 'Nature',
    ),
    AtmospherePreset(
      id: 'clouds_drift',
      name: '☁️ വെള്ളിമേഘങ്ങൾ (Floating Clouds)',
      icon: '☁️',
      category: 'Weather',
    ),
    AtmospherePreset(
      id: 'monsoon_rain',
      name: '🌧️ ഇടവപ്പാതി മഴ (Monsoon Drizzle)',
      icon: '🌧️',
      category: 'Weather',
    ),
    AtmospherePreset(
      id: 'water_ripple',
      name: '🌊 ജലതരംഗങ്ങൾ (Water Ripples & Mist)',
      icon: '🌊',
      category: 'Water',
    ),
    AtmospherePreset(
      id: 'warm_bokeh',
      name: '🪔 ബോക്കെ പ്രഭാവലയം (Warm Golden Bokeh)',
      icon: '🪔',
      category: 'Light',
    ),
    AtmospherePreset(
      id: 'cherry_blossom',
      name: '🌸 പൂവിതളുകൾ (Cherry Blossom Petals)',
      icon: '🌸',
      category: 'Flowers',
    ),
    AtmospherePreset(
      id: 'kanikonna',
      name: '🌼 കണിക്കൊന്ന (Cassia / Kanikonna)',
      icon: '🌼',
      category: 'Flowers',
    ),
    AtmospherePreset(
      id: 'starlight_twinkle',
      name: '✨ മിന്നിത്തിളങ്ങുന്ന താരങ്ങൾ (Starlight)',
      icon: '✨',
      category: 'Space',
    ),
    AtmospherePreset(
      id: 'mountain_fog',
      name: '🌫️ മലനിരകളിലെ കോടമഞ്ഞ് (Mountain Fog)',
      icon: '🌫️',
      category: 'Weather',
    ),
    AtmospherePreset(
      id: 'sunbeam_rays',
      name: '☀️ സൂര്യകിരണങ്ങൾ (Sunbeam Rays)',
      icon: '☀️',
      category: 'Light',
    ),
    AtmospherePreset(
      id: 'fireflies_glow',
      name: '🔥 മിന്നാമിനുങ്ങുകൾ (Fireflies Ember)',
      icon: '🔥',
      category: 'Nature',
    ),
    AtmospherePreset(
      id: 'bamboo_shadow',
      name: '🌿 മുളങ്കാട് തണൽ (Bamboo Breeze Shadow)',
      icon: '🌿',
      category: 'Shadows',
    ),
    AtmospherePreset(
      id: 'coconut_shadow',
      name: '🌴 തെങ്ങോല നിഴലുകൾ (Coconut Frond Breeze)',
      icon: '🌴',
      category: 'Shadows',
    ),
    AtmospherePreset(
      id: 'glass_condensation',
      name: '💧 ഗ്ലാസ്സിലെ മഴത്തുള്ളികൾ (Glass Droplets)',
      icon: '💧',
      category: 'Water',
    ),
    AtmospherePreset(
      id: 'rainbow_flare',
      name: '🌈 മഴവില്ല് പ്രഭ (Rainbow Flare)',
      icon: '🌈',
      category: 'Light',
    ),
    AtmospherePreset(
      id: 'flying_birds',
      name: '🕊️ പറന്നുയരുന്ന പക്ഷികൾ (Flying Birds)',
      icon: '🕊️',
      category: 'Nature',
    ),
    AtmospherePreset(
      id: 'soft_snowflakes',
      name: '❄️ മഞ്ഞുതുള്ളികൾ (Soft Snowflakes)',
      icon: '❄️',
      category: 'Weather',
    ),
    AtmospherePreset(
      id: 'aurora_borealis',
      name: '🔮 ധ്രുവദീപ്തി (Aurora Borealis)',
      icon: '🔮',
      category: 'Light',
    ),
    AtmospherePreset(
      id: 'candlelight_ambient',
      name: '🕯️ നിലവിളക്ക് പ്രഭ (Candlelight Glow)',
      icon: '🕯️',
      category: 'Light',
    ),
    AtmospherePreset(
      id: 'paddy_grass',
      name: '🌾 നെൽപ്പാട കാറ്റ് (Swaying Paddy Grass)',
      icon: '🌾',
      category: 'Nature',
    ),
    AtmospherePreset(
      id: 'ocean_foam',
      name: '🌊 കടൽത്തീരം (Ocean Shore Drift)',
      icon: '🌊',
      category: 'Water',
    ),
    AtmospherePreset(
      id: 'peacock_particles',
      name: '🦚 മയിൽപ്പീലി പ്രഭ (Peacock Feather Aura)',
      icon: '🦚',
      category: 'Aura',
    ),
    AtmospherePreset(
      id: 'thunder_flash',
      name: '⚡ മിന്നൽ വെളിച്ചം (Distant Horizon Lightning)',
      icon: '⚡',
      category: 'Weather',
    ),
    AtmospherePreset(
      id: 'moonlight_beam',
      name: '🌙 നിലാക്കീറ് (Moonlight Ray Beam)',
      icon: '🌙',
      category: 'Light',
    ),
    AtmospherePreset(
      id: 'hibiscus_petals',
      name: '🌺 ചെമ്പരത്തി ഇതളുകൾ (Rose / Hibiscus)',
      icon: '🌺',
      category: 'Flowers',
    ),
    AtmospherePreset(
      id: 'sparkler_flashes',
      name: '🎆 പൂത്തിരി നാളങ്ങൾ (Sparkler Flashes)',
      icon: '🎆',
      category: 'Light',
    ),
    AtmospherePreset(
      id: 'cosmic_dust',
      name: '🌌 നക്ഷത്രധൂളി (Milky Way Cosmic Dust)',
      icon: '🌌',
      category: 'Space',
    ),
    AtmospherePreset(
      id: 'canopy_flicker',
      name: '🍃 കാട്ടുച്ചൂട് (Forest Canopy Sun Flicker)',
      icon: '🍃',
      category: 'Light',
    ),
    AtmospherePreset(
      id: 'wind_streaks',
      name: '💨 ഇളംകാറ്റ് വരകൾ (Gentle Wind Streaks)',
      icon: '💨',
      category: 'Weather',
    ),
    AtmospherePreset(
      id: 'floating_bubbles',
      name: '🫧 കുമിളകൾ (Translucent Bubbles)',
      icon: '🫧',
      category: 'General',
    ),
  ];

  static AtmospherePreset getById(String? id) {
    if (id == null || id.isEmpty || id == 'none') {
      return all.first;
    }
    return all.firstWhere((p) => p.id == id, orElse: () => all.first);
  }
}

/// Dynamic Animated Particle & Shader Engine for Canvas
class StatusAtmosphereOverlay extends StatefulWidget {
  final String presetId;
  final bool isAudioActive;
  final double intensity;

  const StatusAtmosphereOverlay({
    super.key,
    required this.presetId,
    this.isAudioActive = false,
    this.intensity = 1.0,
  });

  @override
  State<StatusAtmosphereOverlay> createState() =>
      _StatusAtmosphereOverlayState();
}

class _StatusAtmosphereOverlayState extends State<StatusAtmosphereOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _initParticles();
  }

  @override
  void didUpdateWidget(StatusAtmosphereOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presetId != widget.presetId) {
      _initParticles();
    }
  }

  void _initParticles() {
    _particles.clear();
    final count = _getParticleCount(widget.presetId);
    for (int i = 0; i < count; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          speed: 0.15 + _random.nextDouble() * 0.35,
          size: 3.0 + _random.nextDouble() * 12.0,
          rotation: _random.nextDouble() * 2 * math.pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 2.0,
          swayAmplitude: 0.02 + _random.nextDouble() * 0.05,
          swayFrequency: 1.0 + _random.nextDouble() * 3.0,
          opacity: 0.3 + _random.nextDouble() * 0.7,
          seed: _random.nextDouble() * 100,
        ),
      );
    }
  }

  int _getParticleCount(String id) {
    switch (id) {
      case 'monsoon_rain':
        return 70;
      case 'starlight_twinkle':
      case 'cosmic_dust':
      case 'sparkler_flashes':
        return 45;
      case 'leaves_green':
      case 'leaves_autumn':
      case 'cherry_blossom':
      case 'kanikonna':
      case 'hibiscus_petals':
      case 'fireflies_glow':
      case 'soft_snowflakes':
      case 'floating_bubbles':
        return 28;
      case 'flying_birds':
        return 6;
      default:
        return 20;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.presetId == 'none' || widget.presetId.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _AtmosphereCustomPainter(
              presetId: widget.presetId,
              progress: _controller.value,
              particles: _particles,
              isAudioActive: widget.isAudioActive,
              intensity: widget.intensity,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  double speed;
  double size;
  double rotation;
  double rotationSpeed;
  double swayAmplitude;
  double swayFrequency;
  double opacity;
  double seed;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.swayAmplitude,
    required this.swayFrequency,
    required this.opacity,
    required this.seed,
  });
}

class _AtmosphereCustomPainter extends CustomPainter {
  final String presetId;
  final double progress;
  final List<_Particle> particles;
  final bool isAudioActive;
  final double intensity;

  _AtmosphereCustomPainter({
    required this.presetId,
    required this.progress,
    required this.particles,
    required this.isAudioActive,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Audio reactive amplitude booster
    final audioBoost = isAudioActive
        ? (1.0 + 0.35 * math.sin(progress * math.pi * 12).abs())
        : 1.0;
    final time = progress * 10 * audioBoost;

    switch (presetId) {
      case 'leaves_green':
        _paintFallingLeaves(
          canvas,
          size,
          time,
          const Color(0xFF4CAF50),
          const Color(0xFF81C784),
        );
        break;
      case 'leaves_autumn':
        _paintFallingLeaves(
          canvas,
          size,
          time,
          const Color(0xFFFF9800),
          const Color(0xFFFFD54F),
        );
        break;
      case 'clouds_drift':
        _paintFloatingClouds(canvas, size, time);
        break;
      case 'monsoon_rain':
        _paintMonsoonRain(canvas, size, time);
        break;
      case 'water_ripple':
        _paintWaterRipples(canvas, size, time);
        break;
      case 'warm_bokeh':
        _paintBokehGlow(canvas, size, time, Colors.amber);
        break;
      case 'cherry_blossom':
        _paintFallingLeaves(
          canvas,
          size,
          time,
          const Color(0xFFFF80AB),
          const Color(0xFFFF4081),
        );
        break;
      case 'kanikonna':
        _paintFallingLeaves(
          canvas,
          size,
          time,
          const Color(0xFFFFEB3B),
          const Color(0xFFFFC107),
        );
        break;
      case 'starlight_twinkle':
        _paintStarlight(canvas, size, time);
        break;
      case 'mountain_fog':
        _paintMountainFog(canvas, size, time);
        break;
      case 'sunbeam_rays':
        _paintSunbeamRays(canvas, size, time);
        break;
      case 'fireflies_glow':
        _paintFireflies(canvas, size, time);
        break;
      case 'bamboo_shadow':
        _paintSwayingShadows(canvas, size, time, isBamboo: true);
        break;
      case 'coconut_shadow':
        _paintSwayingShadows(canvas, size, time, isBamboo: false);
        break;
      case 'glass_condensation':
        _paintGlassCondensation(canvas, size, time);
        break;
      case 'rainbow_flare':
        _paintRainbowFlare(canvas, size, time);
        break;
      case 'flying_birds':
        _paintFlyingBirds(canvas, size, time);
        break;
      case 'soft_snowflakes':
        _paintSnowflakes(canvas, size, time);
        break;
      case 'aurora_borealis':
        _paintAurora(canvas, size, time);
        break;
      case 'candlelight_ambient':
        _paintCandlelight(canvas, size, time);
        break;
      case 'paddy_grass':
        _paintPaddyGrass(canvas, size, time);
        break;
      case 'ocean_foam':
        _paintOceanFoam(canvas, size, time);
        break;
      case 'peacock_particles':
        _paintPeacockParticles(canvas, size, time);
        break;
      case 'thunder_flash':
        _paintThunderFlash(canvas, size, time);
        break;
      case 'moonlight_beam':
        _paintMoonlightBeam(canvas, size, time);
        break;
      case 'hibiscus_petals':
        _paintFallingLeaves(
          canvas,
          size,
          time,
          const Color(0xFFE91E63),
          const Color(0xFFD81B60),
        );
        break;
      case 'sparkler_flashes':
        _paintSparklers(canvas, size, time);
        break;
      case 'cosmic_dust':
        _paintCosmicDust(canvas, size, time);
        break;
      case 'canopy_flicker':
        _paintCanopyFlicker(canvas, size, time);
        break;
      case 'wind_streaks':
        _paintWindStreaks(canvas, size, time);
        break;
      case 'floating_bubbles':
        _paintFloatingBubbles(canvas, size, time);
        break;
      default:
        break;
    }
  }

  void _paintFallingLeaves(
    Canvas canvas,
    Size size,
    double time,
    Color primaryColor,
    Color secondaryColor,
  ) {
    for (final p in particles) {
      final y = (p.y + (time * p.speed * 0.08)) % 1.0;
      final sway =
          math.sin((time * p.swayFrequency) + p.seed) * p.swayAmplitude;
      final x = (p.x + sway) % 1.0;
      final rotation = p.rotation + time * p.rotationSpeed * 0.3;

      final px = x * size.width;
      final py = y * size.height;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rotation);

      final paint = Paint()
        ..color = (p.seed % 2 == 0 ? primaryColor : secondaryColor).withValues(
          alpha: p.opacity * 0.85,
        )
        ..style = PaintingStyle.fill;

      final path = Path();
      final halfSize = p.size;
      path.moveTo(0, -halfSize);
      path.quadraticBezierTo(halfSize * 0.8, 0, 0, halfSize);
      path.quadraticBezierTo(-halfSize * 0.8, 0, 0, -halfSize);
      path.close();

      canvas.drawPath(path, paint);

      // Leaf vein
      final veinPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(0, -halfSize * 0.7),
        Offset(0, halfSize * 0.7),
        veinPaint,
      );

      canvas.restore();
    }
  }

  void _paintMonsoonRain(Canvas canvas, Size size, double time) {
    final rainPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (final p in particles) {
      final y = (p.y + (time * p.speed * 0.45)) % 1.0;
      final x = (p.x + (time * 0.08)) % 1.0;

      final px = x * size.width;
      final py = y * size.height;
      final length = p.size * 2.2;

      canvas.drawLine(
        Offset(px, py),
        Offset(px + length * 0.3, py + length),
        rainPaint,
      );
    }
  }

  void _paintFloatingClouds(Canvas canvas, Size size, double time) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);

    for (int i = 0; i < 4; i++) {
      final speed = 0.03 + i * 0.015;
      final x = ((i * 0.3) + time * speed) % 1.4 - 0.2;
      final y = 0.15 + (i * 0.22);
      final radius = size.width * (0.28 + (i % 2) * 0.1);

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        radius,
        cloudPaint,
      );
      canvas.drawCircle(
        Offset((x + 0.12) * size.width, (y - 0.03) * size.height),
        radius * 0.8,
        cloudPaint,
      );
    }
  }

  void _paintWaterRipples(Canvas canvas, Size size, double time) {
    final ripplePaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 5; i++) {
      final t = (time * 0.2 + i * 0.25) % 1.0;
      final radius = t * size.width * 0.6;
      final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.35;
      ripplePaint.color = Colors.cyanAccent.withValues(alpha: opacity);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.7),
          width: radius * 2,
          height: radius * 0.8,
        ),
        ripplePaint,
      );
    }
  }

  void _paintBokehGlow(Canvas canvas, Size size, double time, Color tint) {
    for (final p in particles) {
      final y = (p.y - (time * p.speed * 0.05)) % 1.0;
      final x = (p.x + math.sin(time + p.seed) * 0.02) % 1.0;
      final pulse = (0.5 + 0.5 * math.sin(time * 2.0 + p.seed)).clamp(0.2, 1.0);

      final px = x * size.width;
      final py = y * size.height;
      final radius = p.size * 2.5 * pulse;

      final paint = Paint()
        ..color = tint.withValues(alpha: p.opacity * 0.35 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4);

      canvas.drawCircle(Offset(px, py), radius, paint);
    }
  }

  void _paintStarlight(Canvas canvas, Size size, double time) {
    for (final p in particles) {
      final pulse = (0.3 + 0.7 * math.sin(time * 3.0 + p.seed)).clamp(0.0, 1.0);
      final px = p.x * size.width;
      final py = p.y * size.height;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity * pulse);
      canvas.drawCircle(Offset(px, py), p.size * 0.3 * pulse, paint);

      // Star sparkle cross
      if (p.size > 8) {
        final crossPaint = Paint()
          ..color = Colors.white.withValues(alpha: p.opacity * pulse * 0.6)
          ..strokeWidth = 1.0;
        final len = p.size * 0.8 * pulse;
        canvas.drawLine(Offset(px - len, py), Offset(px + len, py), crossPaint);
        canvas.drawLine(Offset(px, py - len), Offset(px, py + len), crossPaint);
      }
    }
  }

  void _paintMountainFog(Canvas canvas, Size size, double time) {
    final fogPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 45);

    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.5 + i * 0.2);
      final xOffset = math.sin(time * 0.2 + i) * size.width * 0.15;
      final rect = Rect.fromCenter(
        center: Offset(size.width * 0.5 + xOffset, y),
        width: size.width * 1.4,
        height: size.height * 0.35,
      );
      canvas.drawOval(rect, fogPaint);
    }
  }

  void _paintSunbeamRays(Canvas canvas, Size size, double time) {
    final rayPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.amber.withValues(alpha: 0.35),
          Colors.orangeAccent.withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    for (int i = 0; i < 4; i++) {
      final angleShift = math.sin(time * 0.3 + i * 0.8) * 0.08 * size.width;
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * (0.3 + i * 0.25) + angleShift, size.height)
        ..lineTo(size.width * (0.45 + i * 0.25) + angleShift, size.height)
        ..close();
      canvas.drawPath(path, rayPaint);
    }
  }

  void _paintFireflies(Canvas canvas, Size size, double time) {
    for (final p in particles) {
      final x = (p.x + math.sin(time * p.speed * 2.0 + p.seed) * 0.06) % 1.0;
      final y = (p.y + math.cos(time * p.speed * 1.5 + p.seed) * 0.06) % 1.0;
      final glow = (0.4 + 0.6 * math.sin(time * 4.0 + p.seed)).clamp(0.0, 1.0);

      final px = x * size.width;
      final py = y * size.height;

      final glowPaint = Paint()
        ..color = const Color(0xFF76FF03).withValues(alpha: glow * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(px, py), 6 * glow, glowPaint);

      final corePaint = Paint()
        ..color = const Color(0xFFCCFF90).withValues(alpha: glow);
      canvas.drawCircle(Offset(px, py), 2.5 * glow, corePaint);
    }
  }

  void _paintSwayingShadows(
    Canvas canvas,
    Size size,
    double time, {
    required bool isBamboo,
  }) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final sway = math.sin(time * 0.8) * 15;

    final path = Path();
    if (isBamboo) {
      // Bamboo cane and leafy shadows on corner
      path.moveTo(-20, 0);
      path.lineTo(40 + sway, size.height);
      path.lineTo(60 + sway, size.height);
      path.lineTo(0, 0);
      path.close();
    } else {
      // Coconut frond arching from top right
      path.moveTo(size.width, 0);
      path.quadraticBezierTo(
        size.width * 0.6 + sway,
        size.height * 0.3,
        size.width * 0.2 + sway,
        size.height * 0.4,
      );
      path.lineTo(size.width * 0.25 + sway, size.height * 0.45);
      path.quadraticBezierTo(
        size.width * 0.65 + sway,
        size.height * 0.35,
        size.width,
        40,
      );
      path.close();
    }
    canvas.drawPath(path, shadowPaint);
  }

  void _paintGlassCondensation(Canvas canvas, Size size, double time) {
    final dropPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    for (final p in particles) {
      final y = (p.y + (time * p.speed * 0.02)) % 1.0;
      final px = p.x * size.width;
      final py = y * size.height;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(px, py),
          width: p.size * 0.8,
          height: p.size * 1.3,
        ),
        dropPaint,
      );
    }
  }

  void _paintRainbowFlare(Canvas canvas, Size size, double time) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final sweep = math.sin(time * 0.3) * 0.2;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1.0 + sweep, -1.0),
        end: Alignment(1.0 + sweep, 1.0),
        colors: [
          Colors.red.withValues(alpha: 0.12),
          Colors.orange.withValues(alpha: 0.12),
          Colors.yellow.withValues(alpha: 0.12),
          Colors.green.withValues(alpha: 0.12),
          Colors.blue.withValues(alpha: 0.12),
          Colors.purple.withValues(alpha: 0.12),
        ],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);

    canvas.drawRect(rect, paint);
  }

  void _paintFlyingBirds(Canvas canvas, Size size, double time) {
    final birdPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 5; i++) {
      final speed = 0.06 + i * 0.01;
      final x = ((i * 0.22) + time * speed) % 1.3 - 0.15;
      final y = 0.15 + (i * 0.08) + math.sin(time * 2.0 + i) * 0.01;
      final flap = math.sin(time * 8.0 + i) * 6;

      final px = x * size.width;
      final py = y * size.height;

      final path = Path()
        ..moveTo(px - 10, py - flap)
        ..quadraticBezierTo(px - 5, py + flap * 0.3, px, py)
        ..quadraticBezierTo(px + 5, py + flap * 0.3, px + 10, py - flap);

      canvas.drawPath(path, birdPaint);
    }
  }

  void _paintSnowflakes(Canvas canvas, Size size, double time) {
    final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);

    for (final p in particles) {
      final y = (p.y + time * p.speed * 0.08) % 1.0;
      final x = (p.x + math.sin(time + p.seed) * 0.02) % 1.0;
      final px = x * size.width;
      final py = y * size.height;

      canvas.drawCircle(Offset(px, py), p.size * 0.4, snowPaint);
    }
  }

  void _paintAurora(Canvas canvas, Size size, double time) {
    final path = Path();
    path.moveTo(0, 0);

    for (double x = 0; x <= size.width; x += 20) {
      final y =
          size.height * 0.25 + math.sin((x / size.width * 4) + time * 0.8) * 40;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, 0);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.purpleAccent.withValues(alpha: 0.35),
          Colors.tealAccent.withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawPath(path, paint);
  }

  void _paintCandlelight(Canvas canvas, Size size, double time) {
    final flicker = (0.8 + 0.2 * math.sin(time * 12.0) * math.cos(time * 7.0))
        .clamp(0.5, 1.0);
    final paint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.orange.withValues(alpha: 0.3 * flicker),
              Colors.amber.withValues(alpha: 0.15 * flicker),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.8),
              radius: size.width * 0.6,
            ),
          )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _paintPaddyGrass(Canvas canvas, Size size, double time) {
    final grassPaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.45)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 25; i++) {
      final x = (i / 25.0) * size.width;
      final sway = math.sin(time * 2.0 + i) * 18;
      final height = 50.0 + (i % 5) * 12.0;

      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + sway, size.height - height),
        grassPaint,
      );
    }
  }

  void _paintOceanFoam(Canvas canvas, Size size, double time) {
    final waveT = (time * 0.2) % 1.0;
    final y = size.height * (0.85 - waveT * 0.1);
    final foamPaint = Paint()
      ..color = Colors.white.withValues(alpha: (1.0 - waveT) * 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final path = Path()..moveTo(0, y);
    for (double x = 0; x <= size.width; x += 30) {
      path.lineTo(x, y + math.sin((x / 50.0) + time * 2.0) * 10);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, foamPaint);
  }

  void _paintPeacockParticles(Canvas canvas, Size size, double time) {
    final colors = [
      const Color(0xFF00E5FF),
      const Color(0xFF00E676),
      const Color(0xFF651FFF),
    ];
    for (final p in particles) {
      final y = (p.y - time * p.speed * 0.05) % 1.0;
      final x = (p.x + math.sin(time * 1.5 + p.seed) * 0.03) % 1.0;
      final color = colors[(p.seed.toInt()) % colors.length];

      final px = x * size.width;
      final py = y * size.height;

      final paint = Paint()
        ..color = color.withValues(alpha: p.opacity * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(px, py), p.size * 0.5, paint);
    }
  }

  void _paintThunderFlash(Canvas canvas, Size size, double time) {
    // Flash every 4-5 seconds
    final flashCycle = (time % 4.0);
    if (flashCycle < 0.25) {
      final flashIntensity = (math.sin(flashCycle * math.pi / 0.25) * 0.35)
          .clamp(0.0, 0.4);
      final flashPaint = Paint()
        ..color = Colors.indigo.shade100.withValues(alpha: flashIntensity);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), flashPaint);
    }
  }

  void _paintMoonlightBeam(Canvas canvas, Size size, double time) {
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.lightBlue.shade100.withValues(alpha: 0.28),
          Colors.blue.shade300.withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);

    final path = Path()
      ..moveTo(size.width * 0.7, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.4, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, beamPaint);
  }

  void _paintSparklers(Canvas canvas, Size size, double time) {
    for (final p in particles) {
      final pulse = (0.2 + 0.8 * math.sin(time * 6.0 + p.seed)).clamp(0.0, 1.0);
      final px = p.x * size.width;
      final py = p.y * size.height;

      final paint = Paint()
        ..color = Colors.amberAccent.withValues(alpha: p.opacity * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(px, py), p.size * 0.35 * pulse, paint);
    }
  }

  void _paintCosmicDust(Canvas canvas, Size size, double time) {
    for (final p in particles) {
      final y = (p.y - time * p.speed * 0.02) % 1.0;
      final x = (p.x + time * p.speed * 0.02) % 1.0;
      final px = x * size.width;
      final py = y * size.height;

      final paint = Paint()
        ..color = const Color(0xFFE1BEE7).withValues(alpha: p.opacity * 0.5);
      canvas.drawCircle(Offset(px, py), p.size * 0.3, paint);
    }
  }

  void _paintCanopyFlicker(Canvas canvas, Size size, double time) {
    final flicker = math.sin(time * 1.5) * 0.15 + 0.15;
    final paint = Paint()
      ..color = Colors.yellow.withValues(alpha: flicker.clamp(0.05, 0.3))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.2),
      size.width * 0.4,
      paint,
    );
  }

  void _paintWindStreaks(Canvas canvas, Size size, double time) {
    final windPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final p in particles) {
      final x = (p.x + time * p.speed * 0.3) % 1.3 - 0.15;
      final y = p.y * size.height;
      final px = x * size.width;

      final path = Path()
        ..moveTo(px, y)
        ..quadraticBezierTo(
          px + 25,
          y + math.sin(time * 3.0 + p.seed) * 8,
          px + 50,
          y,
        );

      canvas.drawPath(path, windPaint);
    }
  }

  void _paintFloatingBubbles(Canvas canvas, Size size, double time) {
    for (final p in particles) {
      final y = (p.y - time * p.speed * 0.07) % 1.0;
      final x = (p.x + math.sin(time * 1.2 + p.seed) * 0.03) % 1.0;
      final px = x * size.width;
      final py = y * size.height;
      final radius = p.size;

      final bubblePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawCircle(Offset(px, py), radius, bubblePaint);

      // Highlight sheen
      final sheenPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
      canvas.drawCircle(
        Offset(px - radius * 0.3, py - radius * 0.3),
        radius * 0.25,
        sheenPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_AtmosphereCustomPainter oldDelegate) {
    return true; // Continuously animated for 60 FPS
  }
}
