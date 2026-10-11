import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'match_audio_pool_service.dart';
import 'smart_audio_selector.dart';

/// Singleton audio service for the Match Success Sheet.
///
/// Stall-prevention architecture:
/// - Single reusable [AudioPlayer] instance — avoids creating zombie players
/// - [playMatchSuccess] always calls [stop] first to release any locked handle
/// - Playback is launched via [WidgetsBinding.addPostFrameCallback] pattern
///   (caller responsibility) so audio starts AFTER the sheet frame is drawn
/// - [onPlayerStateChanged] stream drives all UI indicator updates
/// - [dispose] is idempotent — safe to call multiple times
class MatchAudioService {
  MatchAudioService._();
  static final MatchAudioService instance = MatchAudioService._();

  AudioPlayer? _player;
  bool _disposed = false;
  String? _lastAudioUrl;

  // ---------------------------------------------------------------------------
  // Public streams — subscribe in StatefulWidget to sync waveform & status text
  // ---------------------------------------------------------------------------

  /// Fires on every position tick (≈ 200 ms) — use for progress bar updates.
  Stream<Duration> get onPositionChanged =>
      _player?.onPositionChanged ?? const Stream.empty();

  /// Fires when duration is known (after source is loaded).
  Stream<Duration> get onDurationChanged =>
      _player?.onDurationChanged ?? const Stream.empty();

  /// Fires when playback state changes (playing, paused, stopped, completed).
  Stream<PlayerState> get onPlayerStateChanged =>
      _player?.onPlayerStateChanged ?? const Stream.empty();

  /// Fires once when the track finishes naturally.
  Stream<void> get onPlayerComplete =>
      _player?.onPlayerComplete ?? const Stream.empty();

  PlayerState get currentState => _player?.state ?? PlayerState.stopped;

  // ---------------------------------------------------------------------------
  // Core methods
  // ---------------------------------------------------------------------------

  /// Initialise (or re-initialise) the player and start the Malayalam voice track.
  ///
  /// **Stall fix**: always [stop]s first so the audio handle is never locked
  /// from a previous sheet open. Uses [ReleaseMode.stop] to auto-release
  /// OS resources on completion.
  Future<void> playMatchSuccess({String? customAudioUrl}) async {
    _lastAudioUrl = customAudioUrl;
    if (_disposed) _reset();

    try {
      _player ??= AudioPlayer();
      // 1. പഴയ ഓഡിയോ ഓടുന്നുണ്ടെങ്കിൽ പൂർണ്ണമായി നിർത്തുക
      await _player!.stop(); // release any locked handle
      await _player!.setReleaseMode(ReleaseMode.stop);

      // Resolve URL: Custom URL or smart selection with 2-hr cooldown
      String? targetUrl = customAudioUrl;
      if (targetUrl == null || targetUrl.isEmpty) {
        targetUrl = await SmartAudioSelector.getNextAudioUrl(isMatch: true);
        targetUrl ??= await MatchAudioPoolService.instance
            .getRandomSuccessAudioUrl();
      }

      // 2. പുതിയ ഓഡിയോ മാത്രം വ്യക്തമായി പ്ലേ ചെയ്യുക
      // Remote Firebase Storage or HTTPS audio URL
      if (targetUrl != null &&
          (targetUrl.startsWith('http://') ||
              targetUrl.startsWith('https://'))) {
        try {
          await _player!.play(
            UrlSource(targetUrl),
            volume: 1.0,
          );
          return;
        } catch (urlError) {
          debugPrint(
            '[MatchAudioService] Failed to stream remote URL ($targetUrl): $urlError',
          );
        }
      }

      // Remote audio unavailable or failed — strictly purge legacy asset fallback
      debugPrint(
        '[MatchAudioService] Remote audio not available or failed. Zero fallback sounds played.',
      );
    } catch (assetError) {
      debugPrint('[MatchAudioService] Audio playback note: $assetError');
    }
  }

  /// Replay from position zero — used by the replay button.
  Future<void> replay() async {
    try {
      await _player?.seek(Duration.zero);
      await _player?.resume();
    } catch (e) {
      debugPrint('[MatchAudioService] Replay error: $e');
      await playMatchSuccess(customAudioUrl: _lastAudioUrl);
    }
  }

  /// Pause playback without releasing the OS audio handle.
  Future<void> pause() async {
    try {
      await _player?.pause();
    } catch (e) {
      debugPrint('[MatchAudioService] Pause error: $e');
    }
  }

  /// Resume from paused position.
  Future<void> resume() async {
    try {
      await _player?.resume();
    } catch (e) {
      debugPrint('[MatchAudioService] Resume error: $e');
    }
  }

  /// Stop playback and release OS audio handle.
  /// **Must be called in State.dispose() or sheet WillPopScope.**
  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (e) {
      debugPrint('[MatchAudioService] Stop error: $e');
    }
  }

  /// Full teardown — disposes the player and marks this service as disposed.
  /// Safe to call multiple times.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _player?.stop();
      await _player?.dispose();
      _player = null;
    } catch (e) {
      debugPrint('[MatchAudioService] Dispose error: $e');
    }
  }

  void _reset() {
    _disposed = false;
    _player = null;
  }
}
