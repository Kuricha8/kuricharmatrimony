import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

web.HTMLAudioElement? _sharedAudioElement;
bool _isAudioUnlocked = false;
int _activeAudioSessionId = 0;

// 1-sample 100% silent WAV data URI to unlock audio in Chrome Autoplay Policy synchronously
const String _kSilentWav =
    'data:audio/wav;base64,UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAEA';

web.HTMLAudioElement _getOrCreateAudioElement() {
  if (_sharedAudioElement == null) {
    _sharedAudioElement = web.HTMLAudioElement();
    try {
      _sharedAudioElement!.setAttribute('referrerpolicy', 'no-referrer');
      _sharedAudioElement!.removeAttribute('crossorigin');
    } catch (_) {}
  }
  return _sharedAudioElement!;
}

/// Immediately unlocks browser audio within a synchronous user gesture (click/tap).
/// Uses a 100% silent buffer (muted, volume 0.0) with ZERO audible click, pop, beep, or tone.
void unlockWebAudio() {
  if (_isAudioUnlocked) return;
  try {
    debugPrint('[WebAudioTtsHelper] Synchronously unlocking Chrome Autoplay Policy (100% silent)...');
    final audio = _getOrCreateAudioElement();
    audio.src = _kSilentWav;
    audio.muted = true;
    audio.volume = 0.0;
    final playPromise = audio.play();
    playPromise.toDart.then((_) {
      _isAudioUnlocked = true;
      audio.muted = false;
      audio.volume = 1.0;
      debugPrint('[WebAudioTtsHelper] Chrome audio successfully unlocked (silent)!');
    }).catchError((err) {
      debugPrint('[WebAudioTtsHelper] Audio unlock gesture note: $err');
      audio.muted = false;
      audio.volume = 1.0;
      return null;
    });
  } catch (e) {
    debugPrint('[WebAudioTtsHelper] Audio unlock synchronous error: $e');
  }
}

/// Plays remote audio URL via reusable HTML5 Audio element on Web (Chrome / browsers).
/// Cleanly catches any promise rejections without unhandled errors.
void playWebAudio(
  String url, {
  void Function()? onStart,
  void Function()? onComplete,
}) {
  stopWebAudioAndSpeech();
  final sessionId = ++_activeAudioSessionId;
  try {
    debugPrint('[WebAudioTtsHelper] Initializing HTML5 Audio element for URL: $url');
    final audio = _getOrCreateAudioElement();
    try {
      audio.setAttribute('referrerpolicy', 'no-referrer');
      audio.removeAttribute('crossorigin');
    } catch (_) {}
    audio.src = url;
    audio.volume = 1.0;
    audio.muted = false;

    audio.onplay = ((web.Event _) {
      if (sessionId == _activeAudioSessionId) {
        debugPrint('[WebAudioTtsHelper] HTML5 Audio playing: $url');
        onStart?.call();
      }
    }).toJS;

    audio.onended = ((web.Event _) {
      if (sessionId == _activeAudioSessionId) {
        debugPrint('[WebAudioTtsHelper] HTML5 Audio playback completed: $url');
        onComplete?.call();
      }
    }).toJS;

    audio.onerror = ((web.Event err) {
      if (sessionId == _activeAudioSessionId) {
        debugPrint('[WebAudioTtsHelper] HTML5 Audio error for $url: $err');
        onComplete?.call();
      }
    }).toJS;

    final playPromise = audio.play();
    playPromise.toDart.then((_) {
      debugPrint('[WebAudioTtsHelper] HTML5 Audio play promise resolved for: $url');
    }).catchError((err) {
      debugPrint('[WebAudioTtsHelper] HTML5 Audio play promise rejected: $err');
      if (sessionId == _activeAudioSessionId) {
        onComplete?.call();
      }
      return null;
    });
  } catch (e) {
    debugPrint('[WebAudioTtsHelper] HTML5 Audio play synchronous error: $e');
    onComplete?.call();
  }
}

/// Directly streams and plays Malayalam audio for the exact text using Google TTS stream:
/// - Bypasses browser window.speechSynthesis completely (no native Malayalam voice on Windows Chrome).
/// - Completely removes window.fetch, Blob, and createObjectURL (bypassing CORS completely).
/// - HTML Audio elements are NOT blocked by CORS!
/// - Uses referrerpolicy: 'no-referrer' so Google does not block with 404 anti-hotlinking.
void playMalayalamTtsStreamWeb(
  String text, {
  void Function()? onStart,
  void Function()? onComplete,
}) {
  stopWebAudioAndSpeech();
  final cleanText = text.trim();
  if (cleanText.isEmpty) {
    onComplete?.call();
    return;
  }

  final sessionId = ++_activeAudioSessionId;
  final ttsUrl =
      'https://translate.google.com/translate_tts?ie=UTF-8&q=${Uri.encodeComponent(cleanText)}&tl=ml&client=tw-ob';

  debugPrint('[WebAudioTtsHelper] Directly assigning Malayalam TTS to HTML5 Audio: $ttsUrl');

  try {
    // Notify onStart immediately so the speaker button lights up Green on autoplay/tap
    onStart?.call();

    final audio = _getOrCreateAudioElement();
    try {
      audio.setAttribute('referrerpolicy', 'no-referrer');
      audio.removeAttribute('crossorigin');
    } catch (_) {}
    audio.src = ttsUrl;
    audio.volume = 1.0;
    audio.muted = false;

    audio.onplay = ((web.Event _) {
      if (sessionId == _activeAudioSessionId) {
        debugPrint('[WebAudioTtsHelper] Malayalam TTS audio playing...');
        onStart?.call();
      }
    }).toJS;

    audio.onended = ((web.Event _) {
      if (sessionId == _activeAudioSessionId) {
        debugPrint('[WebAudioTtsHelper] Malayalam TTS playback completed.');
        onComplete?.call();
      }
    }).toJS;

    audio.onerror = ((web.Event err) {
      if (sessionId == _activeAudioSessionId) {
        debugPrint('[WebAudioTtsHelper] Malayalam TTS audio error: $err');
        onComplete?.call();
      }
    }).toJS;

    final playPromise = audio.play();
    playPromise.toDart.then((_) {
      debugPrint('[WebAudioTtsHelper] Malayalam TTS play promise resolved.');
    }).catchError((err) {
      debugPrint('[WebAudioTtsHelper] Malayalam TTS play promise rejected: $err');
      if (sessionId == _activeAudioSessionId) {
        onComplete?.call();
      }
      return null;
    });
  } catch (e) {
    debugPrint('[WebAudioTtsHelper] Error playing Malayalam TTS: $e');
    if (sessionId == _activeAudioSessionId) {
      onComplete?.call();
    }
  }
}

/// Speaks the EXACT Malayalam subtitle text displayed on screen.
void speakWebSubtitleText(
  String text, {
  void Function()? onStart,
  void Function()? onComplete,
}) {
  playMalayalamTtsStreamWeb(text, onStart: onStart, onComplete: onComplete);
}

/// Guaranteed, exact audio playback for Moiety Checker results:
/// 1. If remote audio URL exists from Admin DB, plays it via HTML5 Audio.
/// 2. If no remote URL: Directly streams the exact on-screen Malayalam subtitle text via Google TTS without CORS.
/// 3. Zero beep tones, zero chimes, and strictly reads the exact text written on screen.
void playMoietyResultAudioWeb({
  required bool isMatch,
  required String promptText,
  String? audioUrl,
  void Function()? onStart,
  void Function()? onComplete,
}) {
  stopWebAudioAndSpeech();

  final cleanText = promptText.trim();
  final trimmedUrl = audioUrl?.trim();
  final bool hasRemoteUrl = trimmedUrl != null &&
      trimmedUrl.isNotEmpty &&
      (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) &&
      !trimmedUrl.contains('translate.google.com');

  if (hasRemoteUrl) {
    debugPrint('[WebAudioTtsHelper] Playing remote Admin audio URL: $trimmedUrl');
    playWebAudio(trimmedUrl, onStart: onStart, onComplete: onComplete);
    return;
  }

  if (cleanText.isNotEmpty) {
    debugPrint('[WebAudioTtsHelper] Directly streaming exact Malayalam text: "$cleanText"');
    playMalayalamTtsStreamWeb(cleanText, onStart: onStart, onComplete: onComplete);
  } else {
    onComplete?.call();
  }
}

/// Stops any currently playing HTML5 Audio element and cancels speech synthesis immediately.
void stopWebAudioAndSpeech() {
  _activeAudioSessionId++;
  try {
    web.window.speechSynthesis.cancel();
  } catch (_) {}

  try {
    if (_sharedAudioElement != null) {
      _sharedAudioElement!.pause();
      _sharedAudioElement!.currentTime = 0;
      _sharedAudioElement!.src = '';
      debugPrint('[WebAudioTtsHelper] HTML5 Audio successfully paused and cleared.');
    }
  } catch (_) {}
}
