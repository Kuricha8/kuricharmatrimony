import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecurityTickerService extends ChangeNotifier {
  static final SecurityTickerService instance = SecurityTickerService._();
  SecurityTickerService._();

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _subscription;

  String text =
      '🛡️ കുറിച്ച്യർ മാട്രിമോണി AI സെക്യൂരിറ്റി - സുരക്ഷിത പ്ലാറ്റ്ഫോം';
  Color bgColor = const Color(0xFF00104A);
  Color textColor = const Color(0xFF00FFCC);
  bool isEnabled = true;
  int speedSeconds = 20;

  void init() {
    fetchSettings();
    _subscribe();
  }

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      String clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) clean = 'FF$clean';
      if (clean.length == 8) return Color(int.parse('0x$clean'));
    } catch (_) {}
    return fallback;
  }

  Future<void> fetchSettings() async {
    try {
      final res = await _supabase
          .from('admin_app_settings')
          .select('key, value')
          .inFilter('key', [
            'security_ticker_text',
            'security_ticker_bg_color',
            'security_ticker_text_color',
            'security_ticker_enabled',
            'security_ticker_speed',
          ]);

      final Map<String, String> map = {
        for (var r in (res as List))
          r['key'] as String: r['value']?.toString() ?? '',
      };

      if (map.containsKey('security_ticker_text') &&
          map['security_ticker_text']!.isNotEmpty) {
        text = map['security_ticker_text']!;
      }
      if (map.containsKey('security_ticker_bg_color')) {
        bgColor = _parseColor(
          map['security_ticker_bg_color'],
          const Color(0xFF00104A),
        );
      }
      if (map.containsKey('security_ticker_text_color')) {
        textColor = _parseColor(
          map['security_ticker_text_color'],
          const Color(0xFF00FFCC),
        );
      }
      if (map.containsKey('security_ticker_enabled')) {
        isEnabled = map['security_ticker_enabled']?.toLowerCase() != 'false';
      }
      if (map.containsKey('security_ticker_speed')) {
        speedSeconds = int.tryParse(map['security_ticker_speed']!) ?? 20;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching security ticker settings: $e');
    }
  }

  void _subscribe() {
    _subscription?.unsubscribe();
    _subscription = _supabase
        .channel('public:security_ticker_settings')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'admin_app_settings',
          callback: (payload) {
            final key = payload.newRecord['key']?.toString();
            if (key != null && key.startsWith('security_ticker_')) {
              fetchSettings();
            }
          },
        )
        .subscribe();
  }

  Future<void> saveSettings({
    required String newText,
    required String newBgColorHex,
    required String newTextColorHex,
    required bool newIsEnabled,
    required int newSpeed,
  }) async {
    final now = DateTime.now().toIso8601String();
    final updates = [
      {'key': 'security_ticker_text', 'value': newText, 'updated_at': now},
      {
        'key': 'security_ticker_bg_color',
        'value': newBgColorHex,
        'updated_at': now,
      },
      {
        'key': 'security_ticker_text_color',
        'value': newTextColorHex,
        'updated_at': now,
      },
      {
        'key': 'security_ticker_enabled',
        'value': newIsEnabled.toString(),
        'updated_at': now,
      },
      {
        'key': 'security_ticker_speed',
        'value': newSpeed.toString(),
        'updated_at': now,
      },
    ];

    for (final u in updates) {
      await _supabase.from('admin_app_settings').upsert(u);
    }

    text = newText;
    bgColor = _parseColor(newBgColorHex, bgColor);
    textColor = _parseColor(newTextColorHex, textColor);
    isEnabled = newIsEnabled;
    speedSeconds = newSpeed;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}
