import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class DigiPinService {
  // ഇന്ത്യ പോസ്റ്റിന്റെ ഔദ്യോഗിക 4x4 DIGIPIN ഗ്രിഡ് മാട്രിക്സ്
  static const List<List<String>> _grid = [
    ['F', 'C', '9', '8'],
    ['J', '3', '2', '7'],
    ['K', '4', '5', '6'],
    ['L', 'M', 'P', 'T'],
  ];

  // ഇന്ത്യയുടെ ഔദ്യോഗിക ജിയോഗ്രാഫിക് അതിരുകൾ (Official Bounding Box)
  static const double minLat = 2.5;
  static const double maxLat = 38.5;
  static const double minLon = 63.5;
  static const double maxLon = 99.5;

  /// Latitude, Longitude എന്നിവയെ കൃത്യമായ 10 അക്ക DIGIPIN ആക്കുന്നു
  static String encode(double lat, double lon) {
    if (lat < minLat || lat > maxLat || lon < minLon || lon > maxLon) {
      return "INVALID";
    }

    double currentMinLat = minLat;
    double currentMaxLat = maxLat;
    double currentMinLon = minLon;
    double currentMaxLon = maxLon;

    final StringBuffer pin = StringBuffer();

    // 10 ലെവലുകളിലായി ഗ്രിഡ് വിഭജിക്കുന്നു
    for (int level = 0; level < 10; level++) {
      final double latStep = (currentMaxLat - currentMinLat) / 4.0;
      final double lonStep = (currentMaxLon - currentMinLon) / 4.0;

      final int row = ((currentMaxLat - lat) / latStep).floor().clamp(0, 3);
      final int col = ((lon - currentMinLon) / lonStep).floor().clamp(0, 3);

      pin.write(_grid[row][col]);

      // ബൗണ്ടറി അടുത്ത ലെവലിലേക്ക് ചുരുക്കുന്നു
      currentMaxLat = currentMaxLat - (row * latStep);
      currentMinLat = currentMaxLat - latStep;
      currentMinLon = currentMinLon + (col * lonStep);
      currentMaxLon = currentMinLon + lonStep;
    }

    final String raw = pin.toString();
    // ഔദ്യോഗിക ഫോർമാറ്റ്: XXX-XXX-XXXX (ഉദാ: 4MP-K6P-J5L3)
    if (raw.length >= 10) {
      return "${raw.substring(0, 3)}-${raw.substring(3, 6)}-${raw.substring(6, 10)}";
    }
    return raw;
  }

  /// Alias for backward compatibility
  static String getDigiPin(double lat, double lon) => encode(lat, lon);

  /// Decodes a 10-character DIGIPIN back into approximate (lat, lon) coordinates
  static ({double lat, double lng})? decode(String? digipin) {
    if (digipin == null) return null;
    final cleaned = digipin.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (cleaned.length != 10) return null;

    double currentMinLat = minLat;
    double currentMaxLat = maxLat;
    double currentMinLon = minLon;
    double currentMaxLon = maxLon;

    for (int i = 0; i < cleaned.length; i++) {
      final ch = cleaned[i];
      int row = -1, col = -1;
      for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
          if (_grid[r][c] == ch) {
            row = r;
            col = c;
            break;
          }
        }
        if (row != -1) break;
      }
      if (row == -1 || col == -1) return null;

      final double latStep = (currentMaxLat - currentMinLat) / 4.0;
      final double lonStep = (currentMaxLon - currentMinLon) / 4.0;

      final double nextMaxLat = currentMaxLat - (row * latStep);
      final double nextMinLat = nextMaxLat - latStep;
      final double nextMinLon = currentMinLon + (col * lonStep);
      final double nextMaxLon = nextMinLon + lonStep;

      currentMaxLat = nextMaxLat;
      currentMinLat = nextMinLat;
      currentMinLon = nextMinLon;
      currentMaxLon = nextMaxLon;
    }

    final double lat = (currentMinLat + currentMaxLat) / 2.0;
    final double lng = (currentMinLon + currentMaxLon) / 2.0;
    return (lat: lat, lng: lng);
  }

  /// ഫോണിലെ GPS ലൊക്കേഷൻ എടുത്ത് DIGIPIN ആക്കുന്ന ഫംഗ്ഷൻ
  static Future<String?> fetchCurrentDigiPin({BuildContext? context}) async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ലൊക്കേഷൻ സർവീസ് (GPS) ഓൺ ചെയ്യുക')),
          );
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      return encode(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('DIGIPIN Error: $e');
      return null;
    }
  }
}
