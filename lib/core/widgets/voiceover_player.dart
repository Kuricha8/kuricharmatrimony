import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class VoiceoverPlayer {
  static final VoiceoverPlayer instance = VoiceoverPlayer._internal();
  VoiceoverPlayer._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  int _playbackId = 0;

  VoidCallback? _onStart;
  VoidCallback? _onComplete;
  VoidCallback? _onError;

  Future<void> init() async {
    // Request audio focus
    await _flutterTts
        .setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ], IosTextToSpeechAudioMode.defaultMode);

    // Set default speech parameters for fallback native TTS
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Attempt to set Malayalam (ml-IN) strictly and target the default native female voice
    try {
      await _flutterTts.setLanguage("ml-IN");
      debugPrint("VoiceoverPlayer: Malayalam language (ml-IN) set.");

      final List<dynamic>? voices = await _flutterTts.getVoices;
      if (voices != null) {
        final mlVoices = voices.where((v) {
          final String? locale = v['locale'] as String?;
          return (locale != null &&
              (locale.toLowerCase() == 'ml-in' ||
                  locale.toLowerCase() == 'ml_in'));
        }).toList();

        if (mlVoices.isNotEmpty) {
          // Sort Malayalam voices to prioritize high-quality natural female voices
          mlVoices.sort((a, b) {
            int scoreA = 0;
            int scoreB = 0;

            final String nameA = (a['name'] as String? ?? '').toLowerCase();
            final String genderA = (a['gender'] as String? ?? '').toLowerCase();
            final String nameB = (b['name'] as String? ?? '').toLowerCase();
            final String genderB = (b['gender'] as String? ?? '').toLowerCase();

            // 1. Gender Preference: Female (Google TTS uses "mlf" for Malayalam Female)
            if (genderA == 'female' ||
                nameA.contains('female') ||
                nameA.contains('mlf')) {
              scoreA += 10;
            }
            if (genderB == 'female' ||
                nameB.contains('female') ||
                nameB.contains('mlf')) {
              scoreB += 10;
            }

            // 2. Quality/Accent Preference: Enhanced/Network/Premium/Wavenet voices (much more natural)
            if (nameA.contains('network') ||
                nameA.contains('enhanced') ||
                nameA.contains('premium') ||
                nameA.contains('wavenet')) {
              scoreA += 5;
            }
            if (nameB.contains('network') ||
                nameB.contains('enhanced') ||
                nameB.contains('premium') ||
                nameB.contains('wavenet')) {
              scoreB += 5;
            }

            // Descending order (highest score first)
            return scoreB.compareTo(scoreA);
          });

          final selectedVoice = mlVoices.first;
          await _flutterTts.setVoice({
            "name": selectedVoice['name'] as String,
            "locale": selectedVoice['locale'] as String,
          });
          debugPrint(
            "VoiceoverPlayer: Selected Malayalam voice for local fallback: ${selectedVoice['name']}",
          );
        }
      }
    } catch (e) {
      debugPrint(
        "VoiceoverPlayer: Error setting Malayalam language or female voice preference: $e",
      );
    }
  }

  void setHandlers({
    required VoidCallback onStart,
    required VoidCallback onComplete,
    required VoidCallback onError,
  }) {
    _onStart = onStart;
    _onComplete = onComplete;
    _onError = onError;

    // Set handlers for native TTS fallback
    _flutterTts.setStartHandler(onStart);
    _flutterTts.setCompletionHandler(onComplete);
    _flutterTts.setErrorHandler((msg) => onError());
  }

  List<String> _splitText(String text, int maxLength) {
    List<String> chunks = [];
    final List<String> words = text.split(RegExp(r'\s+'));

    String currentChunk = "";
    for (final String word in words) {
      if (word.isEmpty) continue;
      if (currentChunk.isEmpty) {
        currentChunk = word;
      } else if (currentChunk.length + word.length + 1 <= maxLength) {
        currentChunk += ' $word';
      } else {
        chunks.add(currentChunk);
        currentChunk = word;
      }
    }
    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk);
    }
    return chunks;
  }

  Future<void> speak(String text) async {
    final currentId = ++_playbackId;
    _isPlaying = true;
    _onStart?.call();

    // Check connectivity
    bool isOnline = false;
    try {
      final dynamic result = await Connectivity().checkConnectivity();
      if (result is List) {
        isOnline =
            result.isNotEmpty && !result.contains(ConnectivityResult.none);
      } else if (result is ConnectivityResult) {
        isOnline = result != ConnectivityResult.none;
      }
    } catch (e) {
      debugPrint("VoiceoverPlayer: Connectivity check failed: $e");
    }

    if (isOnline) {
      try {
        final chunks = _splitText(text, 150);
        final tempDir = await getTemporaryDirectory();

        for (int i = 0; i < chunks.length; i++) {
          if (!_isPlaying || currentId != _playbackId) return;
          final chunk = chunks[i];
          final encodedText = Uri.encodeComponent(chunk);
          final url =
              "https://translate.google.com/translate_tts?ie=UTF-8&tl=ml&client=tw-ob&q=$encodedText";

          final response = await http.get(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            },
          );

          if (response.statusCode == 200) {
            if (!_isPlaying || currentId != _playbackId) return;
            final file = File('${tempDir.path}/tts_chunk_${currentId}_$i.mp3');
            await file.writeAsBytes(response.bodyBytes);

            if (!_isPlaying || currentId != _playbackId) return;
            await _audioPlayer.play(DeviceFileSource(file.path));

            // Wait for completion of this chunk
            await _audioPlayer.onPlayerComplete.first;
          } else {
            throw Exception(
              "Failed to fetch Google Translate TTS chunk, status: ${response.statusCode}",
            );
          }
        }

        if (_isPlaying && currentId == _playbackId) {
          _isPlaying = false;
          _onComplete?.call();
        }
        return;
      } catch (e) {
        debugPrint(
          "VoiceoverPlayer: Online natural TTS failed, falling back to local: $e",
        );
      }
    }

    // Offline native fallback
    if (!_isPlaying || currentId != _playbackId) return;
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("VoiceoverPlayer: Fallback local TTS failed: $e");
      if (currentId == _playbackId) {
        _isPlaying = false;
        _onError?.call();
      }
    }
  }

  Future<void> speakThug(String text) async {
    final currentId = ++_playbackId;
    _isPlaying = true;
    _onStart?.call();

    // For Thug dialogues, we use local TTS exclusively to manipulate pitch and speed
    // for a deeper, punchier delivery.
    try {
      await _flutterTts.setLanguage("ml-IN");
      await _flutterTts.setPitch(0.6); // Deeper voice
      await _flutterTts.setSpeechRate(0.65); // Slightly faster, punchy
      await _flutterTts.setVolume(1.0);

      await _flutterTts.speak(text);

      // Reset after
      await Future.delayed(const Duration(seconds: 3));
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
    } catch (e) {
      debugPrint("VoiceoverPlayer: Thug TTS failed: $e");
      if (currentId == _playbackId) {
        _isPlaying = false;
        _onError?.call();
      }
    }
  }

  Future<void> stop() async {
    _isPlaying = false;
    _playbackId++;
    await _audioPlayer.stop();
    await _flutterTts.stop();
  }
}
