import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/legal_strings.dart';
import 'package:flutter/foundation.dart';

class LegalService {
  final SupabaseClient _supabase;

  LegalService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Fetches legal sections for a given [documentType] (e.g., 'terms', 'privacy', 'refund')
  /// and maps fields depending on the selected [languageCode].
  Future<List<LegalSection>> fetchLegalSections(
    String documentType,
    String languageCode,
  ) async {
    try {
      final response = await _supabase
          .from('legal_information')
          .select()
          .eq('document_type', documentType)
          .order('display_order', ascending: true);

      if (response.isEmpty) {
        return getLocalFallback(documentType);
      }

      return _mapToSections(response, languageCode);
    } catch (e) {
      debugPrint('Error fetching legal information: $e');
      return getLocalFallback(documentType);
    }
  }

  List<LegalSection> getLocalFallback(String documentType) {
    if (documentType == 'terms') return kTcSections;
    if (documentType == 'privacy') return kPrivacySections;
    if (documentType == 'refund') return kRefundSections;
    return [];
  }

  List<LegalSection> _mapToSections(List<dynamic> data, String languageCode) {
    return data.map((row) {
      String heading = '';
      String body = '';

      if (languageCode == 'ml') {
        heading = (row['title_ml'] ?? row['title_en'] ?? row['heading'] ?? '')
            .toString();
        body = (row['content_ml'] ?? row['content_en'] ?? row['body'] ?? '')
            .toString();
      } else if (languageCode == 'hi') {
        heading = (row['title_hi'] ?? row['title_en'] ?? row['heading'] ?? '')
            .toString();
        body = (row['content_hi'] ?? row['content_en'] ?? row['body'] ?? '')
            .toString();
      } else {
        heading = (row['title_en'] ?? row['title_ml'] ?? row['heading'] ?? '')
            .toString();
        body = (row['content_en'] ?? row['content_ml'] ?? row['body'] ?? '')
            .toString();
      }

      return LegalSection(heading: heading, body: body);
    }).toList();
  }
}
