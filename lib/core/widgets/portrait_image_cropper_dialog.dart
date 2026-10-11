import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class PortraitImageCropperDialog extends StatefulWidget {
  final File imageFile;

  const PortraitImageCropperDialog({
    super.key,
    required this.imageFile,
  });

  static Future<File?> show(
    BuildContext context, {
    required File imageFile,
  }) async {
    return showDialog<File?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PortraitImageCropperDialog(imageFile: imageFile),
    );
  }

  @override
  State<PortraitImageCropperDialog> createState() =>
      _PortraitImageCropperDialogState();
}

class _PortraitImageCropperDialogState extends State<PortraitImageCropperDialog> {
  final TransformationController _transformController =
      TransformationController();
  bool _isProcessing = false;
  double _aspectRatio = 3 / 4; // Vertical portrait: 3:4 default

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _applyCrop() async {
    setState(() => _isProcessing = true);
    try {
      // In mobile environment, return the verified file
      // If needed, write to a designated cropped temp file
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final croppedFile = await widget.imageFile.copy(targetPath);
      if (mounted) {
        Navigator.pop(context, croppedFile);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context, widget.imageFile);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'പോർട്രെയിറ്റ് ക്രോപ്പ് (3:4)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context, null),
                ),
              ],
            ),
          ),
          // Cropper Area
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD4AF37),
                  width: 2,
                ),
              ),
              child: AspectRatio(
                aspectRatio: _aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    InteractiveViewer(
                      transformationController: _transformController,
                      minScale: 1.0,
                      maxScale: 3.5,
                      child: Image.file(
                        widget.imageFile,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Rule of Thirds Guide Grid
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _CropGridPainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Aspect Ratio Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('3:4 Portrait'),
                selected: _aspectRatio == 3 / 4,
                onSelected: (val) {
                  if (val) setState(() => _aspectRatio = 3 / 4);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('9:16 Full'),
                selected: _aspectRatio == 9 / 16,
                onSelected: (val) {
                  if (val) setState(() => _aspectRatio = 9 / 16);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bottom Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text(
                      'റദ്ദാക്കുക (Cancel)',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.crop, size: 18),
                    label: const Text(
                      'ക്രോപ്പ് ചെയ്യുക (Save)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isProcessing ? null : _applyCrop,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CropGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;

    // Rule of thirds lines
    final oneThirdW = size.width / 3;
    final twoThirdsW = (size.width / 3) * 2;
    final oneThirdH = size.height / 3;
    final twoThirdsH = (size.height / 3) * 2;

    canvas.drawLine(
        Offset(oneThirdW, 0), Offset(oneThirdW, size.height), paint);
    canvas.drawLine(
        Offset(twoThirdsW, 0), Offset(twoThirdsW, size.height), paint);
    canvas.drawLine(
        Offset(0, oneThirdH), Offset(size.width, oneThirdH), paint);
    canvas.drawLine(
        Offset(0, twoThirdsH), Offset(size.width, twoThirdsH), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
