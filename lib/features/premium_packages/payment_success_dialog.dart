import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class PaymentSuccessDialog extends StatefulWidget {
  final String planName;
  const PaymentSuccessDialog({super.key, required this.planName});

  @override
  State<PaymentSuccessDialog> createState() => _PaymentSuccessDialogState();
}

class _PaymentSuccessDialogState extends State<PaymentSuccessDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // 3 സെക്കൻഡ് നേരത്തേക്ക് കടലാസ് ചിതറാൻ
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
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
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // പോപ്പ്-അപ്പ് ബോക്സ്
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const CircleAvatar(
                radius: 36,
                backgroundColor: Colors.green,
                child: Icon(Icons.check, color: Colors.white, size: 45),
              ),
              const SizedBox(height: 16),
              const Text(
                'പേയ്മെന്റ് വിജയിച്ചു! 🎉',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'നിങ്ങളുടെ ${widget.planName} വിജയകരമായി ആക്റ്റീവ് ആയിരിക്കുന്നു.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'തുടങ്ങാം',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // മുകളിൽ നിന്ന് കടലാസ് ചിതറി വീഴുന്ന ആനിമേഷൻ
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: pi / 2, // താഴേക്ക് വീഴാൻ
          maxBlastForce: 5,
          minBlastForce: 2,
          emissionFrequency: 0.05,
          numberOfParticles: 25, // കടലാസ് കഷണങ്ങളുടെ എണ്ണം
          gravity: 0.2,
          colors: const [
            Colors.green,
            Colors.blue,
            Colors.pink,
            Colors.orange,
            Colors.purple,
            Colors.amber,
          ],
        ),
      ],
    );
  }
}
