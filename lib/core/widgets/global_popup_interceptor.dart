import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class GlobalPopupInterceptor extends StatefulWidget {
  final Widget child;

  const GlobalPopupInterceptor({super.key, required this.child});

  @override
  State<GlobalPopupInterceptor> createState() => _GlobalPopupInterceptorState();
}

class _GlobalPopupInterceptorState extends State<GlobalPopupInterceptor> {
  RealtimeChannel? _announcementChannel;

  @override
  void initState() {
    super.initState();
    _checkActiveAnnouncements();
    _listenToRealtimeAnnouncements();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_announcementChannel!);
    super.dispose();
  }

  Future<void> _checkActiveAnnouncements() async {
    try {
      final res = await Supabase.instance.client
          .from('admin_popups')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null) {
        _processAnnouncement(res);
      }
    } catch (e) {
      debugPrint('Error fetching announcements: $e');
    }
  }

  void _listenToRealtimeAnnouncements() {
    _announcementChannel = Supabase.instance.client
        .channel('public:admin_popups')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'admin_popups',
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord['is_active'] == true) {
              _processAnnouncement(newRecord);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'admin_popups',
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord['is_active'] == true) {
              _processAnnouncement(newRecord);
            }
          },
        )
        .subscribe();
  }

  Future<void> _processAnnouncement(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedIds = prefs.getStringList('dismissed_popups') ?? [];

    final id = record['id'].toString();
    if (dismissedIds.contains(id)) return;

    final targetAudience = record['target_audience']?.toString() ?? 'all';
    final user = Supabase.instance.client.auth.currentUser;
    final isLoggedIn = user != null;

    if (targetAudience == 'registered' && !isLoggedIn) return;
    if (targetAudience == 'guest' && isLoggedIn) return;

    if (!mounted) return;
    _showAnnouncementPopup(record, id, prefs, dismissedIds);
  }

  void _showAnnouncementPopup(
    Map<String, dynamic> record,
    String id,
    SharedPreferences prefs,
    List<String> dismissedIds,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Announcement",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return AnnouncementModal(
          title: record['title']?.toString() ?? 'Announcement',
          message: record['message']?.toString(),
          imageUrl: record['image_url']?.toString(),
          audioUrl: record['audio_url']?.toString(),
          onDismiss: () {
            dismissedIds.add(id);
            prefs.setStringList('dismissed_popups', dismissedIds);
            Navigator.of(context).pop();
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(opacity: anim1.value, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class AnnouncementModal extends StatefulWidget {
  final String title;
  final String? message;
  final String? imageUrl;
  final String? audioUrl;
  final VoidCallback onDismiss;

  const AnnouncementModal({
    super.key,
    required this.title,
    this.message,
    this.imageUrl,
    this.audioUrl,
    required this.onDismiss,
  });

  @override
  State<AnnouncementModal> createState() => _AnnouncementModalState();
}

class _AnnouncementModalState extends State<AnnouncementModal> {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.setSourceUrl(widget.audioUrl!);

      _audioPlayer!.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      });
      _audioPlayer!.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _audioPlayer!.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_audioPlayer == null) return;
    if (_isPlaying) {
      await _audioPlayer!.pause();
    } else {
      await _audioPlayer!.resume();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
              Image.network(
                widget.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              )
            else
              Container(
                width: double.infinity,
                height: 80,
                color: const Color(0xFF000080),
                child: const Icon(
                  Icons.campaign,
                  color: Colors.white,
                  size: 40,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  if (widget.message != null && widget.message!.isNotEmpty)
                    Text(
                      widget.message!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  if (widget.audioUrl != null &&
                      widget.audioUrl!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                            ),
                            color: const Color(0xFF000080),
                            iconSize: 36,
                            onPressed: _togglePlayPause,
                          ),
                          Expanded(
                            child: Slider(
                              value: _position.inSeconds.toDouble(),
                              max: _duration.inSeconds.toDouble() > 0
                                  ? _duration.inSeconds.toDouble()
                                  : 1.0,
                              onChanged: (val) {
                                _audioPlayer?.seek(
                                  Duration(seconds: val.toInt()),
                                );
                              },
                              activeColor: const Color(0xFF000080),
                              inactiveColor: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000080),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Got it!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
