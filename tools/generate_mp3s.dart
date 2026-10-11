// ignore_for_file: avoid_print
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final files = {
    'compatible.mp3': 'നിങ്ങൾക്ക് വിവാഹം കഴിക്കാം. ഇത് ഉത്തമമായ ഒരു ബന്ധമാണ്.',
    'incompatible.mp3': 'ക്ഷമിക്കണം, ഗോത്ര നിയമപ്രകാരം നിങ്ങൾക്ക് വിവാഹം കഴിക്കാൻ പാടുള്ളതല്ല.',
  };
  
  final dir = Directory('assets/audio');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  for (var entry in files.entries) {
    final encodedText = Uri.encodeComponent(entry.value);
    final url = "https://translate.google.com/translate_tts?ie=UTF-8&tl=ml&client=tw-ob&q=$encodedText";
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'Mozilla/5.0'
    });
    if (response.statusCode == 200) {
      await File('assets/audio/${entry.key}').writeAsBytes(response.bodyBytes);
      print('Saved ${entry.key}');
    } else {
      print('Failed to save ${entry.key}');
    }
  }
}
