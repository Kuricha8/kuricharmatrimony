import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/agent_qr_crypto.dart';

class RegistrationQrScannerScreen extends StatefulWidget {
  const RegistrationQrScannerScreen({super.key});

  @override
  State<RegistrationQrScannerScreen> createState() =>
      _RegistrationQrScannerScreenState();
}

class _RegistrationQrScannerScreenState
    extends State<RegistrationQrScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.stop();
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _processScannedData(String data) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    debugPrint('=== [QR_SCANNER] Scanned Raw Data: $data ===');

    try {
      if (data.startsWith('KM_ENC:')) {
        cameraController
            .stop(); // Stop camera before opening dialog to prevent OOM/crash
        final encryptedBase64 = data.substring(7).trim();
        debugPrint(
          '=== [QR_SCANNER] Encrypted Base64 Payload Length: ${encryptedBase64.length} ===',
        );

        String? pin;
        if (mounted) {
          pin = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              final pinController = TextEditingController();
              final focusNode = FocusNode();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (focusNode.canRequestFocus) {
                  focusNode.requestFocus();
                }
              });

              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.lock, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Enter 4-Digit PIN'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This QR code is encrypted. Enter the 4-digit PIN to unlock it.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: pinController,
                      focusNode: focusNode,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'PIN',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (ctx.mounted && Navigator.canPop(ctx)) {
                        Navigator.pop(ctx, null);
                      }
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final input = pinController.text.trim().replaceAll(
                        RegExp(r'\s+'),
                        '',
                      );
                      if (ctx.mounted && Navigator.canPop(ctx)) {
                        Navigator.pop(ctx, input);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade900,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Unlock'),
                  ),
                ],
              );
            },
          );
        }

        final cleanPin = pin?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
        debugPrint(
          '=== [QR_SCANNER] User Entered PIN: "$cleanPin" (Length: ${cleanPin.length}) ===',
        );

        if (cleanPin.length != 4) {
          cameraController.start(); // Restart camera if cancelled
          setState(() => _isProcessing = false);
          return;
        }

        try {
          final res = AgentQrCryptoHelper.decryptRegistrationPayload(
            qrData: data,
            pin: cleanPin,
          );
          final decryptedJson = jsonEncode({
            'e': res.email,
            'p': res.password,
            'cp': res.confirmPassword,
            'sessionId': res.sessionId,
          });
          debugPrint(
            '=== [QR_SCANNER] Decryption & Verification SUCCESS: $decryptedJson ===',
          );
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context, decryptedJson);
          }
        } catch (e, stack) {
          debugPrint('=== [QR_SCANNER] Decryption FAILED: $e\n$stack ===');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e is FormatException
                      ? e.message
                      : 'Incorrect PIN or invalid QR code.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          cameraController.start(); // Restart camera on error
          setState(() => _isProcessing = false);
        }
        return;
      }

      // Basic validation for non-encrypted QR codes
      bool isValid = false;
      if (data.startsWith('{') && data.endsWith('}')) {
        isValid = true;
      } else if (data.contains('@') ||
          data.contains(',') ||
          data.contains(':')) {
        isValid = true;
      }

      if (!isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid QR Code format. Please scan a valid profile QR.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        return; // Do not pop, allow scanning again
      }

      if (mounted) {
        cameraController.stop();
        Navigator.pop(context, data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing QR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final BarcodeCapture? capture = await cameraController.analyzeImage(
        image.path,
      );
      final bool hasBarcode = capture != null && capture.barcodes.isNotEmpty;
      if (!hasBarcode && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No QR code found in the selected image.'),
          ),
        );
      } else if (hasBarcode && mounted) {
        final barcode = capture.barcodes.first;
        if (barcode.rawValue != null) {
          _processScannedData(barcode.rawValue!);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        cameraController.stop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code'),
          backgroundColor: Colors.indigo.shade900,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              cameraController.stop();
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: _pickImageFromGallery,
              tooltip: 'Upload from Gallery',
            ),
          ],
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _processScannedData(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),
            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Point camera at QR Code or tap gallery icon",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
