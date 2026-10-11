import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'match_audio_service.dart';
import '../../core/models/models.dart';
import '../clan_feed/tharavadu_list.dart';

// ---------------------------------------------------------------------------
// Malayalam string constants — all visible text strictly in Malayalam
// ---------------------------------------------------------------------------
const _kTitle = 'അഭിനന്ദനങ്ങൾ!';
const _kSubtitle = 'ഒരു വിവാഹ പൊരുത്തം ലഭിച്ചിരിക്കുന്നു!';
const _kCompatible = 'അനുയോജ്യ പ്രൊഫൈൽ';
const _kVoicePlaying = 'മലയാളം ശബ്ദം പ്ലേ ആകുന്നു...';
const _kVoicePaused = 'ശബ്ദം നിർത്തിയിരിക്കുന്നു';
const _kVoiceComplete = 'ശബ്ദ സന്ദേശം പൂർത്തിയായി';
const _kVoiceLoading = 'ശബ്ദം ലോഡ് ആകുന്നു...';
const _kVoiceError = 'ശബ്ദം ലഭ്യമല്ല';
const _kReplay = 'വീണ്ടും കേൾക്കുക';
const _kChat = 'ചാറ്റ് ആരംഭിക്കുക';
const _kClose = 'അടയ്ക്കുക';
const _kFatherClan = 'പിതാവ്';
const _kMotherClan = 'മാതാവ്';
const _kAge = 'വയസ്സ്';
const _kRegion = 'പ്രദേശം';

// ---------------------------------------------------------------------------
// Entry point — call this to show the sheet
// ---------------------------------------------------------------------------
void showMatchSuccessSheet(
  BuildContext context,
  UserProfile profile, {
  String? customAudioUrl,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (_) => MatchSuccessSheet(
      profile: profile,
      customAudioUrl: customAudioUrl,
    ),
  );
}

// ---------------------------------------------------------------------------
// MatchSuccessSheet — Green themed, Malayalam UI, audio-synced waveform
// ---------------------------------------------------------------------------
class MatchSuccessSheet extends StatefulWidget {
  final UserProfile profile;
  final String? customAudioUrl;
  const MatchSuccessSheet({
    super.key,
    required this.profile,
    this.customAudioUrl,
  });

  @override
  State<MatchSuccessSheet> createState() => _MatchSuccessSheetState();
}

class _MatchSuccessSheetState extends State<MatchSuccessSheet>
    with TickerProviderStateMixin {
  final _audio = MatchAudioService.instance;

  // Playback state
  _AudioStatus _status = _AudioStatus.loading;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Waveform animation controllers — one per bar
  late final List<AnimationController> _barControllers;
  static const int _barCount = 7;

  // Stream subscriptions
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    _initWaveformControllers();
    _subscribeToAudioStreams();

    // TRIGGER FIX: start audio AFTER the first frame is drawn
    // This prevents the sheet from freezing during initState
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _audio.playMatchSuccess(customAudioUrl: widget.customAudioUrl);
    });
  }

  void _initWaveformControllers() {
    final rng = Random();
    _barControllers = List.generate(_barCount, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + rng.nextInt(400)),
      );
      // Stagger bar animations
      Future.delayed(Duration(milliseconds: i * 60), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
      return ctrl;
    });
  }

  void _subscribeToAudioStreams() {
    // STATE — drive UI status text and waveform pulsing
    _stateSub = _audio.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        switch (state) {
          case PlayerState.playing:
            _status = _AudioStatus.playing;
            _startWaveform();
            break;
          case PlayerState.paused:
            _status = _AudioStatus.paused;
            _pauseWaveform();
            break;
          case PlayerState.stopped:
          case PlayerState.disposed:
            _status = _AudioStatus.stopped;
            _stopWaveform();
            break;
          case PlayerState.completed:
            // handled by onPlayerComplete
            break;
        }
      });
    });

    // POSITION — update progress bar (fires ~200ms, never blocks UI thread)
    _positionSub = _audio.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });

    // DURATION — set total duration once source is loaded
    _durationSub = _audio.onDurationChanged.listen((dur) {
      if (!mounted) return;
      setState(() => _duration = dur);
    });

    // COMPLETE — state reset: flip to complete, stop waveform without locking UI
    _completeSub = _audio.onPlayerComplete.listen((_) {
      if (!mounted) return;
      // Use addPostFrameCallback to ensure setState runs outside build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _status = _AudioStatus.complete;
          _position = _duration;
        });
        _stopWaveform();
      });
    });
  }

  // Waveform control
  void _startWaveform() {
    for (final c in _barControllers) {
      if (!c.isAnimating) c.repeat(reverse: true);
    }
  }

  void _pauseWaveform() {
    for (final c in _barControllers) {
      c.stop();
    }
  }

  void _stopWaveform() {
    for (final c in _barControllers) {
      c.stop();
      c.value = 0.15;
    }
  }

  @override
  void dispose() {
    // Cancel all subscriptions first
    _stateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completeSub?.cancel();

    // Dispose waveform controllers
    for (final c in _barControllers) {
      c.dispose();
    }

    // STALL FIX: stop + dispose audio player synchronously-safe
    _audio.stop().then((_) => _audio.dispose());

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _statusText {
    switch (_status) {
      case _AudioStatus.loading:
        return _kVoiceLoading;
      case _AudioStatus.playing:
        return _kVoicePlaying;
      case _AudioStatus.paused:
        return _kVoicePaused;
      case _AudioStatus.stopped:
        return _kVoiceError;
      case _AudioStatus.complete:
        return _kVoiceComplete;
    }
  }

  Color get _statusColor {
    switch (_status) {
      case _AudioStatus.loading:
        return Colors.amber.shade700;
      case _AudioStatus.playing:
        return const Color(0xFF1B8C4E);
      case _AudioStatus.paused:
        return Colors.orange.shade700;
      case _AudioStatus.stopped:
        return Colors.grey.shade600;
      case _AudioStatus.complete:
        return const Color(0xFF1B8C4E);
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case _AudioStatus.loading:
        return Icons.hourglass_top;
      case _AudioStatus.playing:
        return Icons.volume_up;
      case _AudioStatus.paused:
        return Icons.volume_off;
      case _AudioStatus.stopped:
        return Icons.error_outline;
      case _AudioStatus.complete:
        return Icons.check_circle_outline;
    }
  }

  double get _progressValue {
    if (_duration.inMilliseconds == 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final fatherClan = getClanById(widget.profile.fatherClanId);
    final motherClan = getClanById(widget.profile.motherClanId);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          // STALL FIX: stop before the sheet is unmounted
          await _audio.stop();
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Green header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B8C4E), Color(0xFF0F5C33)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Animated confetti icon
                  const Icon(Icons.celebration, color: Colors.amber, size: 52)
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      )
                      .then()
                      .shimmer(duration: 1200.ms, color: Colors.amber.shade200),
                  const SizedBox(height: 12),
                  Text(
                    _kTitle,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 6),
                  Text(
                    _kSubtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 350.ms),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Compatible profile badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B8C4E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF1B8C4E).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF1B8C4E),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _kCompatible,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1B8C4E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 16),

                  // Profile row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(
                          0xFF1B8C4E,
                        ).withValues(alpha: 0.15),
                        child: const Icon(
                          Icons.person,
                          size: 32,
                          color: Color(0xFF1B8C4E),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.profile.name}, ${widget.profile.age} $_kAge',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0F3D21),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$_kFatherClan: ${fatherClan?.type ?? "PANDI"} (${fatherClan?.name ?? widget.profile.fatherTharavadu ?? "—"}) • $_kMotherClan: ${motherClan?.type ?? "BANDHU"} (${motherClan?.name ?? widget.profile.motherTharavadu ?? "—"})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '$_kRegion: ${widget.profile.region}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 20),

                  // ── Audio Player Panel ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FFF6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1B8C4E).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Status row: icon + Malayalam status text
                        Row(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                _statusIcon,
                                key: ValueKey(_status),
                                color: _statusColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  _statusText,
                                  key: ValueKey(_statusText),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _statusColor,
                                  ),
                                ),
                              ),
                            ),
                            // Duration text
                            if (_duration.inSeconds > 0)
                              Text(
                                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Waveform animation bars
                        SizedBox(
                          height: 36,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(_barCount, (i) {
                              return AnimatedBuilder(
                                animation: _barControllers[i],
                                builder: (context, _) {
                                  final baseHeight = 8.0 + (i % 3) * 6.0;
                                  final height = _status == _AudioStatus.playing
                                      ? baseHeight +
                                            _barControllers[i].value * 20
                                      : baseHeight;
                                  return Container(
                                    width: 5,
                                    height: height,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _status == _AudioStatus.playing
                                          ? const Color(0xFF1B8C4E)
                                          : const Color(
                                              0xFF1B8C4E,
                                            ).withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  );
                                },
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Progress bar — driven by onPositionChanged stream
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progressValue,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            color: const Color(0xFF1B8C4E),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Playback controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Play / Pause toggle
                            if (_status == _AudioStatus.playing)
                              IconButton(
                                onPressed: _audio.pause,
                                icon: const Icon(Icons.pause_circle_filled),
                                color: const Color(0xFF1B8C4E),
                                iconSize: 40,
                              )
                            else
                              IconButton(
                                onPressed: () {
                                  if (_status == _AudioStatus.complete) {
                                    _audio.playMatchSuccess();
                                  } else {
                                    _audio.resume();
                                  }
                                },
                                icon: const Icon(Icons.play_circle_filled),
                                color: const Color(0xFF1B8C4E),
                                iconSize: 40,
                              ),
                            const SizedBox(width: 16),
                            // Replay button — Malayalam label
                            OutlinedButton.icon(
                              onPressed: () async {
                                setState(() => _status = _AudioStatus.loading);
                                await _audio.playMatchSuccess();
                              },
                              icon: const Icon(Icons.replay, size: 16),
                              label: const Text(
                                _kReplay,
                                style: TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1B8C4E),
                                side: const BorderSide(
                                  color: Color(0xFF1B8C4E),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.15, end: 0),
                  const SizedBox(height: 20),

                  // CTA buttons (Malayalam)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text(
                      _kChat,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B8C4E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ).animate().fadeIn(delay: 650.ms),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      _kClose,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal enum for audio playback state
// ---------------------------------------------------------------------------
enum _AudioStatus { loading, playing, paused, stopped, complete }
