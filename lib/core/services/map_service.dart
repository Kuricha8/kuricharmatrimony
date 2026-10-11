import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service to handle launching Google Maps and location navigations
class MapService {
  /// Opens Google Maps using GPS coordinates or DIGIPIN/Pincode query
  static Future<bool> openGoogleMaps({
    double? lat,
    double? lng,
    String? digipin,
  }) async {
    Uri mapUri;
    if (lat != null && lng != null) {
      // കൃത്യമായ GPS കോർഡിനേറ്റ്സ് ഉണ്ടെങ്കിൽ
      mapUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    } else if (digipin != null && digipin.trim().isNotEmpty) {
      // DIGIPIN സെർച്ച് ചെയ്യാൻ
      mapUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(digipin.trim())}',
      );
    } else {
      debugPrint('No location coordinates or DIGIPIN provided.');
      return false;
    }

    try {
      if (await canLaunchUrl(mapUri)) {
        return await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback launch attempt
        return await launchUrl(mapUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching map: $e');
      return false;
    }
  }
}
