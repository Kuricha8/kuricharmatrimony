import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/admin_config.dart';

class AppFooter extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const AppFooter({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
  });

  Future<void> _callAdmin(BuildContext context) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: AdminConfig.adminPhoneNumber,
    );
    if (!await launchUrl(launchUri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Branding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.brown.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Colors.brown.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Powered by Madhu & Rineesh',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Colors.brown.shade700,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Location & Contact Info
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              // Location
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Alakkamuttam, Kurichar',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),

              // Contact
              GestureDetector(
                onTap: () => _callAdmin(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      AdminConfig.formattedAdminPhone,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blue.shade300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
