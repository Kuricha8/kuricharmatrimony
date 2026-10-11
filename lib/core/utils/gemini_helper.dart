import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiHelper {
  static const String _model = 'gemini-2.0-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // ── Bio Generator ──────────────────────────────────────────────────────────
  /// Generates a matrimony profile bio in [language] ('english' or 'malayalam').
  static Future<String?> generateBio({
    required String name,
    required String job,
    required String familyValues,
    String language = 'english',
  }) async {
    final langNote = language == 'malayalam'
        ? 'Write entirely in fluent Malayalam script.'
        : 'Write in clear, warm English.';
    final prompt =
        'You are a matrimony profile assistant for the Kurichiyar community. '
        'Write a warm, respectful 3-4 sentence profile bio for a person named $name '
        'who works as a $job and values: $familyValues. '
        'Keep it modest, family-oriented, and community-appropriate. $langNote';

    return _callGemini(prompt);
  }

  // ── Feed Moderation ────────────────────────────────────────────────────────
  /// Returns true if the [text] is safe to publish. False if inappropriate.
  static Future<({bool isSafe, String? reason})> moderateText(
    String text,
  ) async {
    final prompt =
        'You are a content moderator for a traditional community matrimony app. '
        'Analyze the following post and respond with exactly one JSON object: '
        '{"safe": true} or {"safe": false, "reason": "brief reason"}. '
        'Flag: profanity, sexual content, hate speech, spam, or harassment. '
        'Post: "$text"';

    final response = await _callGemini(prompt);
    if (response == null) return (isSafe: true, reason: null);

    try {
      final jsonStr = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      final safe = parsed['safe'] as bool? ?? true;
      return (isSafe: safe, reason: parsed['reason'] as String?);
    } catch (_) {
      return (isSafe: true, reason: null);
    }
  }

  // ── Internal HTTP call ─────────────────────────────────────────────────────
  static Future<String?> _callGemini(String prompt) async {
    if (_apiKey.isEmpty) {
      debugPrint('GeminiHelper: GEMINI_API_KEY not set in .env');
      return null;
    }
    try {
      final uri = Uri.parse('$_baseUrl?key=$_apiKey');
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 300},
      });

      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['candidates']?[0]?['content']?['parts']?[0]?['text']
            as String?;
      } else {
        debugPrint('Gemini error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('GeminiHelper error: $e');
      return null;
    }
  }
}
