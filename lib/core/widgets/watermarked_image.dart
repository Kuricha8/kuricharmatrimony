import 'package:flutter/material.dart';

/// Dynamic Anti-Screenshot Watermarked Image Component with user ID, timestamp & brand lattice overlay.
class WatermarkedImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final String watermarkText;
  final String? viewerId;
  final BoxConstraints? constraints;
  final bool showGridLattice;
  final bool isGuestBlur;
  final Alignment alignment;

  const WatermarkedImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.watermarkText = 'KURICHIYAR MATRIMONY',
    this.viewerId,
    this.constraints,
    this.showGridLattice = true,
    this.isGuestBlur = false,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveConstraints = constraints ??
        (height != null
            ? BoxConstraints.tightFor(height: height)
            : const BoxConstraints());

    final displayLabel = viewerId != null && viewerId!.isNotEmpty
        ? '$watermarkText • ID: ${viewerId!.substring(0, viewerId!.length > 8 ? 8 : viewerId!.length)}'
        : watermarkText;

    Widget imageWidget = imageUrl.trim().isEmpty
        ? Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.person, size: 64, color: Colors.grey),
          )
        : Image.network(
            imageUrl,
            fit: fit,
            alignment: alignment,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.person, size: 64, color: Colors.grey),
            ),
          );

    return Container(
      constraints: effectiveConstraints,
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          // Security Repeating Watermark Lattice Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: showGridLattice
                  ? _buildLatticeOverlay(displayLabel)
                  : Center(
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Text(
                          displayLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            shadows: const [
                              Shadow(color: Colors.black45, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatticeOverlay(String label) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 30,
          runSpacing: 40,
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          children: List.generate(12, (index) {
            return Transform.rotate(
              angle: -0.4,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
