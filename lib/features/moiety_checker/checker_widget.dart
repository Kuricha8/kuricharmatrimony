import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:audioplayers/audioplayers.dart' hide Source;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../../core/services/clan_matching_engine.dart';
import '../../core/services/kinship_service.dart';
import '../../core/widgets/voiceover_player.dart';
import '../../core/services/admin_moiety_prompt_service.dart';
import '../../core/services/admin_moiety_audio_cache_service.dart';
import '../../core/services/web_audio_tts_helper.dart';
import 'checker_form_widget.dart';
import 'checker_action_buttons.dart';
import 'widgets/traditional_match_celebration_card.dart';

class CheckerWidget extends StatefulWidget {
  final bool isGuest;
  const CheckerWidget({super.key, this.isGuest = false});

  @override
  State<CheckerWidget> createState() => _CheckerWidgetState();
}

class _CheckerWidgetState extends State<CheckerWidget> {
  bool? _isCompatible;
  MoietyMatchResult? _matchResult;
  bool _isLoading = false;
  bool _isCheckingAd = false;
  int _clickCount = 0;
  String? _dialogue;
  AdminMoietyPrompt? _selectedPrompt;
  bool _isPlayingAudio = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _audioPlayer.onLog.listen((msg) {
      debugPrint('[CheckerWidget AudioPlayer LOG] $msg');
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      debugPrint('[CheckerWidget AudioPlayer STATE] $state');
      if (mounted) {
        setState(() {
          _isPlayingAudio = (state == PlayerState.playing);
        });
      }
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      debugPrint('[CheckerWidget AudioPlayer COMPLETE]');
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
        });
      }
    });
    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isPlayingAudio = true);
    });
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlayingAudio = false);
    });
    _flutterTts.setErrorHandler((_) {
      if (mounted) setState(() => _isPlayingAudio = false);
    });
  }

  @override
  void dispose() {
    _killAllAudio();
    _audioPlayer.dispose();
    _bgmPlayer.dispose();
    super.dispose();
  }

  /// Guaranteed Audio Cleanup & Stop:
  /// - Immediately pauses and resets the HTML5 Audio element / audio player.
  /// - Cancels any running Web Speech / TTS utterance (window.speechSynthesis.cancel()).
  /// - Ensures no background BGM or tone keeps looping endlessly.
  /// - Sets _isPlayingAudio to false (Speaker Muted).
  Future<void> _killAllAudio() async {
    debugPrint('[CheckerWidget] _killAllAudio() called -> halting all BGM, audio and speech.');
    stopWebAudioAndSpeech();
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    try {
      await _bgmPlayer.stop();
    } catch (_) {}
    try {
      await _flutterTts.stop();
    } catch (_) {}
    try {
      await VoiceoverPlayer.instance.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isPlayingAudio = false;
      });
    }
  }

  void _toggleSpeakerAudio() {
    if (_isPlayingAudio) {
      debugPrint('[CheckerWidget] Speaker button tapped while PLAYING -> Muting & Stopping all audio.');
      _killAllAudio();
    } else {
      debugPrint('[CheckerWidget] Speaker button tapped while MUTED -> Un-muting & playing prompt audio.');
      unlockWebAudio();
      if (_selectedPrompt != null) {
        _handlePromptAudioPlayback(
          prompt: _selectedPrompt!,
          speakerOn: true,
        );
      }
    }
  }

  Future<void> _checkCompatibility(
    Clan groomClan,
    Clan brideClan,
    bool speakerOn,
  ) async {
    // 1. Immediately unlock Chrome Autoplay Policy synchronously on user click
    unlockWebAudio();

    if (_isLoading || _isCheckingAd) return;

    // Complete Cutoff Protection: Immediately stop any running audio
    await _killAllAudio();

    // Premium bypass logic
    bool isPremium = false;
    if (!widget.isGuest) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          final res = await Supabase.instance.client
              .from('kurichiyar_profiles')
              .select('subscription_tier')
              .eq('id', userId)
              .maybeSingle();
          if (res != null) {
            final tier = res['subscription_tier']?.toString() ?? 'tier0';
            if (tier == 'tier1' || tier == 'tier2' || tier == 'tier3') {
              isPremium = true;
            }
          }
        }
      } catch (_) {}
    }

    if (isPremium) {
      return _executeMatchingLogic(groomClan, brideClan, speakerOn);
    }

    _clickCount++;
    if (_clickCount < 3) {
      return _executeMatchingLogic(groomClan, brideClan, speakerOn);
    }

    // 3rd click onwards: Load & Show Interstitial
    setState(() => _isCheckingAd = true);
    try {
      final res = await Supabase.instance.client
          .from('admin_app_settings')
          .select('key, value')
          .inFilter('key', ['admob_enabled', 'admob_interstitial_unit_id']);

      bool enabled = false;
      String adUnitId = '';
      for (var row in res) {
        if (row['key'] == 'admob_enabled') {
          enabled = row['value'].toString().toLowerCase() == 'true';
        }
        if (row['key'] == 'admob_interstitial_unit_id') {
          adUnitId = row['value'].toString();
        }
      }

      if (!enabled || adUnitId.isEmpty) {
        if (mounted) setState(() => _isCheckingAd = false);
        return _executeMatchingLogic(groomClan, brideClan, speakerOn);
      }

      bool adShown = false;
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                if (mounted) {
                  setState(() => _isCheckingAd = false);
                  _executeMatchingLogic(groomClan, brideClan, speakerOn);
                }
              },
              onAdFailedToShowFullScreenContent: (ad, err) {
                ad.dispose();
                if (mounted) {
                  setState(() => _isCheckingAd = false);
                  _executeMatchingLogic(groomClan, brideClan, speakerOn);
                }
              },
            );
            adShown = true;
            ad.show();
          },
          onAdFailedToLoad: (err) {
            debugPrint('Failed to load interstitial ad: ');
            if (mounted) {
              setState(() => _isCheckingAd = false);
              _executeMatchingLogic(groomClan, brideClan, speakerOn);
            }
          },
        ),
      );

      // Graceful timeout if the callback doesn't fire
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isCheckingAd && !adShown) {
          setState(() => _isCheckingAd = false);
          _executeMatchingLogic(groomClan, brideClan, speakerOn);
        }
      });
    } catch (e) {
      debugPrint('Error preparing interstitial: ');
      if (mounted) {
        setState(() => _isCheckingAd = false);
        _executeMatchingLogic(groomClan, brideClan, speakerOn);
      }
    }
  }

  Future<void> _executeMatchingLogic(
    Clan groomClan,
    Clan brideClan,
    bool speakerOn,
  ) async {
    // Immediately stop previous audio / speech when a new check starts
    await _killAllAudio();

    setState(() {
      _isLoading = true;
      _isCompatible = null;
      _matchResult = null;
      _dialogue = null;
      _selectedPrompt = null;
      _isPlayingAudio = false;
    });

    // 1. Kinship & Moiety Evaluation via KinshipService
    final kinshipResult = KinshipService.instance.checkMoietyCompatibility(
      groomClan,
      brideClan,
    );

    final matchResult = ClanMatchingEngine.instance.checkCompatibility(
      groomClanInput: groomClan,
      brideClanInput: brideClan,
    );

    final bool isMatch = kinshipResult.isAllowed;

    debugPrint('[CheckerWidget] ─── COMPATIBILITY EVALUATION ───');
    debugPrint(
      '  Groom: ${groomClan.displayName} (Group: ${groomClan.clanGroup}, Type: ${groomClan.type}, ID: ${groomClan.id}, Num: ${groomClan.tharavaduNumber})',
    );
    debugPrint(
      '  Bride: ${brideClan.displayName} (Group: ${brideClan.clanGroup}, Type: ${brideClan.type}, ID: ${brideClan.id}, Num: ${brideClan.tharavaduNumber})',
    );
    debugPrint(
      '  Kinship Result -> isAllowed: $isMatch, isSameMoiety: ${kinshipResult.isSameMoiety}, isRestricted: ${kinshipResult.isRestricted}',
    );
    if (!isMatch) {
      debugPrint('  Reason for No Match: ${kinshipResult.detailedReason}');
      for (final r in kinshipResult.ruleBreakdown) {
        debugPrint('    - $r');
      }
    }

    // 2. Dynamically fetch prompt strictly from Firestore Admin Database
    final AdminMoietyPrompt prompt = await AdminMoietyPromptService.instance.getPrompt(
      isMatch: isMatch,
    );

    debugPrint('[CheckerWidget] Dynamically selected Admin Prompt: $prompt');

    // 3. Guarantee Strict Synchronization: The subtitle text shown on screen
    // MUST strictly match the exact chosen Admin entry!
    final String chosenSubtitleText = prompt.text;

    if (mounted) {
      setState(() {
        _isCompatible = isMatch;
        _matchResult = matchResult;
        _isLoading = false;
        _selectedPrompt = prompt;
        _dialogue = chosenSubtitleText;
      });
    }

    // 4. Trigger audio/TTS playback for that exact chosen prompt
    await _handlePromptAudioPlayback(
      prompt: prompt,
      speakerOn: speakerOn,
    );
  }

  /// Handles voice dialogue playback directly for the chosen Admin entry.
  /// If remote audio URL exists, streams it.
  /// If remote audio fails or is absent, uses Malayalam TTS for the EXACT chosen prompt text.
  /// STRICTLY PURGES ALL LEGACY/LOCAL SOUNDS: Never plays car key, beep, or local fallback assets.
  /// Handles voice dialogue playback directly for the chosen Admin entry.
  /// Merges the chosen Admin voice dialogue with:
  /// - Yes Match: subtle, joyful traditional Nadaswaram & Melam wedding BGM softly in the background.
  /// - No Match: soft acoustic flute & tampura traditional strings BGM softly in the background.
  /// STRICTLY PURGES ALL LEGACY BEEP/CAR-KEY SOUNDS.
  Future<void> _handlePromptAudioPlayback({
    required AdminMoietyPrompt prompt,
    required bool speakerOn,
  }) async {
    final String resultType = prompt.isMatch ? 'Yes-Match' : 'No-Match';
    debugPrint('[CheckerWidget] ─── _handlePromptAudioPlayback START ───');
    debugPrint('[CheckerWidget] Result type: $resultType | Speaker: $speakerOn');
    debugPrint('[CheckerWidget] Prompt Text: "${prompt.text}" | URL: ${prompt.audioUrl}');

    if (!speakerOn) {
      debugPrint('[CheckerWidget] Speaker turned OFF by user. Audio playback skipped.');
      return;
    }

    try {
      // 1. പഴയ ഓഡിയോകൾ പൂർണ്ണമായി നിർത്തുക (Voice, BGM, and Web Speech/Audio)
      await _killAllAudio();

      // Seamless Autoplay: Immediately light up speaker button GREEN
      if (mounted) {
        setState(() => _isPlayingAudio = true);
      }

      // Web Platform (Chrome / Chromium / Browsers):
      if (kIsWeb) {
        debugPrint('[CheckerWidget Web] Speaking exact on-screen subtitle text: "${prompt.text}"');
        playMoietyResultAudioWeb(
          isMatch: prompt.isMatch,
          promptText: prompt.text,
          audioUrl: prompt.audioUrl,
          onStart: () {
            if (mounted) setState(() => _isPlayingAudio = true);
          },
          onComplete: () {
            if (mounted) setState(() => _isPlayingAudio = false);
          },
        );
        return;
      }

      // Mobile / Desktop native platforms:
      // Configure audio routing cleanly without throwing assertion errors.
      try {
        await _audioPlayer.setAudioContext(
          AudioContext(
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: const {},
            ),
            android: const AudioContextAndroid(
              isSpeakerphoneOn: true,
              stayAwake: true,
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            ),
          ),
        );
      } catch (ctxErr) {
        debugPrint('[CheckerWidget] AudioContext configuration note: $ctxErr');
      }

      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1.0);

      // 2. Dynamic Text-Content Hash Based Audio Caching:
      // - Computes MD5 of prompt.text -> prompt_${hash}.mp3
      // - If prompt was updated in Admin DB, hash changes -> downloads & caches new audio stream for exact text
      // - If unchanged, immediately plays from ultra-fast local cache
      final cachedFilePath = await AdminMoietyAudioCacheService.instance.getOrFetchCachedAudio(
        prompt: prompt,
      );

      if (cachedFilePath != null) {
        debugPrint('[CheckerWidget Native] Playing exact text-hash cached audio: $cachedFilePath');
        try {
          await _audioPlayer.play(DeviceFileSource(cachedFilePath), volume: 1.0);
          return;
        } catch (cachePlayErr) {
          debugPrint('[CheckerWidget Native] Cache playback error ($cachePlayErr). Falling back to TTS...');
        }
      }

      // 3. Remote Admin audio URL fallback
      final audioUrl = prompt.audioUrl?.trim();
      final bool hasAudioUrl = audioUrl != null &&
          audioUrl.isNotEmpty &&
          (audioUrl.startsWith('http://') || audioUrl.startsWith('https://'));

      if (hasAudioUrl) {
        debugPrint('[CheckerWidget Native] Playing remote Admin audio: $audioUrl');
        try {
          await _audioPlayer.play(UrlSource(audioUrl), volume: 1.0);
          return;
        } catch (urlErr) {
          debugPrint('[CheckerWidget Native] Remote audio failed ($urlErr). Falling back to TTS.');
        }
      }

      // 4. Device TTS speaking the exact on-screen text
      if (prompt.text.isNotEmpty) {
        debugPrint('[CheckerWidget Native] Speaking exact text via flutter_tts: "${prompt.text}"');
        try {
          await _flutterTts.setLanguage('ml-IN');
          await _flutterTts.setSpeechRate(0.5);
          await _flutterTts.setVolume(1.0);
          await _flutterTts.speak(prompt.text);
        } catch (_) {
          if (mounted) setState(() => _isPlayingAudio = false);
        }
      } else {
        if (mounted) setState(() => _isPlayingAudio = false);
      }
    } catch (e, stack) {
      debugPrint('[CheckerWidget] Playback error: $e\n$stack');
      if (mounted) setState(() => _isPlayingAudio = false);
    }
    debugPrint('[CheckerWidget] ─── _handlePromptAudioPlayback END ───');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckerFormWidget(
          onCheckCompatibility: _checkCompatibility,
          isCompatible: _isCompatible,
        ),
        if (_isLoading || _isCheckingAd)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                if (_isCheckingAd) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Preparing Ad...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        if (_isCompatible != null && !_isLoading && !_isCheckingAd) ...[
          const SizedBox(height: 24),
          _buildResultBox(),
        ],
        const SizedBox(height: 32),
        CheckerActionButtons(isGuest: widget.isGuest),
      ],
    );
  }

  Widget _buildResultBox() {
    return TraditionalMatchCelebrationCard(
      isMatch: _isCompatible!,
      matchResult: _matchResult,
      prompt: _selectedPrompt,
      dialogue: _dialogue ?? '',
      isPlayingAudio: _isPlayingAudio,
      onToggleSpeaker: _toggleSpeakerAudio,
      onReplay: _toggleSpeakerAudio,
    );
  }
}

// തറവാടിന്റെ കാറ്റഗറി അനുസരിച്ച് കളർ നൽകുന്ന ലോജിക്
Color getMoietyBadgeColor(String moietyGroup) {
  if (moietyGroup == 'ബന്ധു' || moietyGroup == 'Bandhu') {
    return Colors.green; // ബന്ധുവിന് പച്ച
  } else if (moietyGroup == 'പന്തി' || moietyGroup == 'Panthi') {
    return Colors.red; // പന്തിക്ക് ചുവപ്പ്
  }
  return Colors.grey;
}
