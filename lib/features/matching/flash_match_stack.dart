import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/global_features_service.dart';
import '../../core/services/matching_service.dart';
import '../../core/widgets/universal_profile_card.dart';
import 'match_success_sheet.dart';

class FlashMatchStack extends StatefulWidget {
  final List<UserProfile> candidates;
  const FlashMatchStack({super.key, required this.candidates});

  @override
  State<FlashMatchStack> createState() => _FlashMatchStackState();
}

class _FlashMatchStackState extends State<FlashMatchStack> {
  late List<UserProfile> _currentCandidates;
  final Map<String, int> _timers = {};
  Timer? _globalTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    final me = MockData().currentUser;
    _currentCandidates = me != null
        ? widget.candidates.where((c) => MatchingService.isMatchEligible(me, c)).toList()
        : List.from(widget.candidates);
    for (var c in _currentCandidates) {
      _timers[c.id] = 300; // 5 minutes in seconds
    }
    _startTimers();
  }

  void _startTimers() {
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        final toRemove = <String>[];
        for (var id in _timers.keys) {
          _timers[id] = _timers[id]! - 1;
          if (_timers[id]! <= 0) {
            toRemove.add(id);
            _markExpired(id);
          }
        }
        _currentCandidates.removeWhere((c) => toRemove.contains(c.id));
      });
    });
  }

  Future<void> _markExpired(String candidateId) async {
    final me = MockData().currentUser;
    if (me == null) return;
    try {
      await Supabase.instance.client.from('profile_matches').insert({
        'sender_id': me.id,
        'receiver_id': candidateId,
        'status': 'EXPIRED',
      });
      MockData().interactedProfileIds.add(candidateId);
    } catch (_) {}
  }

  Future<void> _handleAction(UserProfile candidate, String status) async {
    final me = MockData().currentUser;
    if (me == null) return;

    String? commentText;
    if (status == 'LIKED') {
      // Age Gap Warning Trigger Check
      final ageGap = candidate.age - me.age;
      if (ageGap >= 10 && GlobalFeaturesService.instance.muraMatchSystem) {
        final locale = Localizations.localeOf(context).languageCode;
        String title;
        String message;
        String proceedText;
        String cancelText;

        if (locale == 'ml') {
          title = 'പ്രായവ്യത്യാസ മുന്നറിയിപ്പ്';
          message =
              'തുടരണമെന്ന് ഉറപ്പാണോ? നിങ്ങൾ തമ്മിൽ 10 വർഷത്തിലധികം പ്രായവ്യത്യാസമുണ്ട്!\nനിങ്ങളുടെ പ്രായം: ${me.age}\nഅവരുടെ പ്രായം: ${candidate.age}\nതുടരാൻ പൂർണ്ണമായും സമ്മതിക്കുന്നുണ്ടോ?';
          proceedText = 'അതെ, തുടരുക';
          cancelText = 'അല്ല, റദ്ദാക്കുക';
        } else if (locale == 'hi') {
          title = 'आयु अंतर चेतावनी';
          message =
              'क्या आप वाकई आगे बढ़ना चाहते हैं? आपके बीच 10 वर्ष से अधिक का आयु अंतर है!\nआपकी आयु: ${me.age}\nउनकी आयु: ${candidate.age}\nक्या आप आगे बढ़ने के लिए पूरी तरह सहमत हैं?';
          proceedText = 'हां, आगे बढ़ें';
          cancelText = 'नहीं, रद्द करें';
        } else {
          title = 'Age Difference Warning';
          message =
              'Are you sure about this decision? There is an age difference of more than 10 years between you!\nYour Age: ${me.age}\nTheir Age: ${candidate.age}\nDo you fully consent to proceed?';
          proceedText = 'Yes, Proceed';
          cancelText = 'No, Cancel';
        }

        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(message, style: const TextStyle(fontSize: 15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  cancelText,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(proceedText),
              ),
            ],
          ),
        );
        if (proceed != true) return; // Abort Action Flow
      }

      if (status == 'LIKED') {
        HapticFeedback.lightImpact();
        // 1. പഴയ ഓഡിയോ ഓടുന്നുണ്ടെങ്കിൽ പൂർണ്ണമായി നിർത്തുക
        await _audioPlayer.stop();
        // 2. പുതിയ ഓഡിയോ മാത്രം വ്യക്തമായി പ്ലേ ചെയ്യുക
        await _audioPlayer.play(AssetSource('sounds/interest_sent.wav'));
      }

      if (!mounted) return;
      final commentController = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmLikeTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppLocalizations.of(context)!.confirmLikeMessage),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText:
                      'അവർക്ക് എന്തെങ്കിലും പറയാൻ താല്പര്യമുണ്ടോ? (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(AppLocalizations.of(context)!.thalperyamilla),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(ctx, commentController.text.trim()),
              child: Text(AppLocalizations.of(context)!.thalperyamundu),
            ),
          ],
        ),
      );
      if (result == null) return;
      commentText = result;
    }

    try {
      await Supabase.instance.client.from('profile_matches').insert({
        'sender_id': me.id,
        'receiver_id': candidate.id,
        'status': status,
        if (commentText != null && commentText.isNotEmpty)
          'interaction_comment': commentText,
      });

      MockData().interactedProfileIds.add(candidate.id);

      setState(() {
        _currentCandidates.removeWhere((c) => c.id == candidate.id);
        _timers.remove(candidate.id);
      });

      if (status == 'LIKED' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request Sent!'),
            backgroundColor: Colors.green,
          ),
        );
        showMatchSuccessSheet(context, candidate);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentCandidates.isEmpty) {
      return const Center(
        child: Text(
          'No more flash matches for now.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Top 5 Matches (മികച്ച പൊരുത്തങ്ങൾ)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 470,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _currentCandidates.length,
            itemBuilder: (context, index) {
              final candidate = _currentCandidates[index];
              final timeLeft = _timers[candidate.id] ?? 0;
              final minutes = timeLeft ~/ 60;
              final seconds = timeLeft % 60;

              final me = MockData().currentUser;
              final isPremium =
                  me != null && me.subscriptionTier != SubscriptionTier.free;
              final isLocked = !isPremium && index >= 2;

              return SizedBox(
                width: 270,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: UniversalProfileCard(
                    profile: candidate,
                    isGuest: isLocked,
                    isGrid: true,
                    aspectRatio: 4 / 5,
                    margin: EdgeInsets.zero,
                    topTrailingBadge: isLocked
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Locked',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$minutes:${seconds.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    actionFooter: isLocked
                        ? ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/subscription');
                            },
                            icon: const Icon(Icons.workspace_premium, size: 18),
                            label: const Text('Unlock Top Matches'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: const Size.fromHeight(40),
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _handleAction(candidate, 'PASSED'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey.shade700,
                                    side: BorderSide(
                                        color: Colors.grey.shade400),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Pass'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _handleAction(candidate, 'LIKED'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Connect'),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
