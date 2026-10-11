import 'package:flutter/material.dart';

/// Dynamic multi-language database adapter extension for `Map<String, dynamic>` and Models
extension LocalizedDbMap on Map<String, dynamic> {
  /// Extracts localized field value according to current active locale (e.g., name_ml, name_en, name_hi)
  String getLocalized(String field, BuildContext context) {
    try {
      final locale = Localizations.localeOf(
        context,
      ).languageCode; // 'ml', 'en', 'hi'
      final direct = this['${field}_$locale'];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString();
      }
      final mlFallback = this['${field}_ml'];
      if (mlFallback != null && mlFallback.toString().trim().isNotEmpty) {
        return mlFallback.toString();
      }
      final standard = this[field];
      if (standard != null && standard.toString().trim().isNotEmpty) {
        return standard.toString();
      }
    } catch (_) {}
    return '';
  }
}
