import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import '../../core/widgets/watermarked_image.dart';
import '../../core/widgets/status_atmosphere_overlay.dart';
import '../../core/widgets/unified_like_button.dart';
import '../../core/widgets/unified_comment_bar.dart';
import 'admin_custom_ad_widget.dart';
import 'audio_player_widget.dart';
import 'tharavadu_list.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/widgets/native_ad_card.dart';

class ClanFeedPostCard extends StatefulWidget {
  final StatusPost post;
  final UserProfile creator;
  final UserProfile currentUser;
  final MockData mockData;
  final bool isExpanded;
  final List<String> comments;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onAddComment;
  final VoidCallback onMute;
  final bool isGoogleAdTurn;
  final bool showAd;

  const ClanFeedPostCard({
    super.key,
    required this.post,
    required this.creator,
    required this.currentUser,
    required this.mockData,
    required this.isExpanded,
    required this.comments,
    required this.onToggleExpand,
    required this.onAddComment,
    required this.onMute,
    this.isGoogleAdTurn = false,
    this.showAd = false,
  });

  @override
  State<ClanFeedPostCard> createState() => _ClanFeedPostCardState();
}

class _ClanFeedPostCardState extends State<ClanFeedPostCard> {
  @override
  void initState() {
    super.initState();
    _trackView();
  }

  void _trackView() async {
    final me = widget.currentUser.id;
    final post = widget.post;
    if (me != post.creatorId && !post.viewers.contains(me)) {
      try {
        final newViewers = List<String>.from(post.viewers)..add(me);
        await Supabase.instance.client
            .from('clan_feed_posts')
            .update({'views': newViewers})
            .eq('id', post.id);
      } catch (e) {
        // ignore
      }
    }
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) {
      return 'കാലാവധി കഴിഞ്ഞു';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return 'അവസാനിക്കാൻ: $hours മണിക്കൂർ $minutes മിനിറ്റ്';
  }

  Widget _getClanAvatar(Clan? clan) {
    if (clan == null) return const CircleAvatar(child: Icon(Icons.person));
    final isPandi = clan.type == 'PANDI';
    final color = isPandi ? Colors.teal : Colors.indigo;
    final iconData = isPandi
        ? Icons.shield_outlined
        : Icons.diversity_3_outlined;
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(iconData, color: color),
    );
  }

  void _playVideoStatus(BuildContext context, StatusPost post) {
    if (post.videoUrl == null) return;
    showDialog(
      context: context,
      builder: (context) {
        return VideoPlayerDialog(videoUrl: post.videoUrl!);
      },
    );
  }

  void _showReportSheet(
    BuildContext context, {
    required String postId,
    required String reporterProfileId,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Report Content',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                title: const Text('Spam or misleading'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted.')),
                  );
                },
              ),
              ListTile(
                title: const Text('Inappropriate content'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted.')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    final post = widget.post;

    // Parse JSON metadata if post.content contains serialized status payload
    String displayCaption = post.content.trim();
    String? mediaUrl = post.feedPhotoUrl;
    String? videoUrl = post.videoUrl;
    String? audioUrl = post.feedAudioUrl;
    String? atmospherePreset;

    if (displayCaption.startsWith('{') && displayCaption.endsWith('}')) {
      try {
        final decoded = jsonDecode(displayCaption);
        if (decoded is Map<String, dynamic>) {
          displayCaption =
              decoded['caption']?.toString() ??
              decoded['text']?.toString() ??
              decoded['content']?.toString() ??
              '';

          if (decoded['media_urls'] is List &&
              (decoded['media_urls'] as List).isNotEmpty) {
            final firstMedia = decoded['media_urls'][0].toString();
            if (firstMedia.endsWith('.mp4') ||
                firstMedia.contains('video') ||
                decoded['media_type'] == 'video') {
              videoUrl ??= firstMedia;
            } else if (firstMedia.endsWith('.mp3') ||
                firstMedia.contains('audio') ||
                decoded['media_type'] == 'audio') {
              audioUrl ??= firstMedia;
            } else {
              mediaUrl ??= firstMedia;
            }
          } else if (decoded['media_url'] != null &&
              decoded['media_url'].toString().isNotEmpty) {
            final m = decoded['media_url'].toString();
            if (m.endsWith('.mp4') || m.contains('video')) {
              videoUrl ??= m;
            } else if (m.endsWith('.mp3') || m.contains('audio')) {
              audioUrl ??= m;
            } else {
              mediaUrl ??= m;
            }
          }

          if (decoded['audio_overlay'] != null) {
            if (decoded['audio_overlay'] is Map) {
              audioUrl ??= decoded['audio_overlay']['url']?.toString();
            } else if (decoded['audio_overlay'] is String) {
              audioUrl ??= decoded['audio_overlay'].toString();
            }
          }

          if (decoded['atmosphere_overlay'] != null) {
            atmospherePreset = decoded['atmosphere_overlay'].toString();
          } else if (decoded['frame_overlay'] != null &&
              decoded['frame_overlay'] is Map) {
            atmospherePreset = decoded['frame_overlay']['frame_asset_id']
                ?.toString();
          }
        }
      } catch (e) {
        debugPrint('Error decoding post JSON in ClanFeedPostCard: $e');
      }
    }

    final timeStr = _formatTimeRemaining(post.timeRemaining);
    final hasAudio = audioUrl != null && audioUrl.isNotEmpty;
    final isPandi = getClanById(post.clanId)?.type == 'PANDI';
    final cardBorderColor = isPandi
        ? Colors.teal.shade200
        : Colors.indigo.shade200;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cardBorderColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: _getClanAvatar(getClanById(post.clanId)),
            title: Text(
              getClanById(post.clanId)?.name ?? 'Unknown Clan',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  'Posted by: ${widget.creator.name} (ID: ${widget.creator.id.length > 8 ? widget.creator.id.substring(0, 8).toUpperCase() : widget.creator.id})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'report') {
                  _showReportSheet(
                    context,
                    postId: post.id,
                    reporterProfileId: widget.currentUser.id,
                  );
                } else if (val == 'mute') {
                  widget.onMute();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Text(
                    'Report Post',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const PopupMenuItem(value: 'mute', child: Text('Mute User')),
              ],
            ),
          ),

          if (mediaUrl != null && mediaUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: mediaUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => WatermarkedImage(
                          imageUrl: mediaUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (atmospherePreset != null &&
                          atmospherePreset != 'none')
                        Positioned.fill(
                          child: StatusAtmosphereOverlay(
                            presetId: atmospherePreset,
                            isAudioActive: hasAudio,
                          ),
                        ),
                      if (post.isProfilePhoto)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Tharavadu Profile Photo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          if (videoUrl != null && videoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () => _playVideoStatus(context, post),
                  child: Container(
                    height: 180,
                    color: Colors.black12,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 64,
                        color: Color(0xFF000080),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (displayCaption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                displayCaption,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
            ),

          if (audioUrl != null && audioUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AudioPlayerWidget(audioUrl: audioUrl),
            ),

          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        UnifiedLikeButton(postId: post.id, iconSize: 20),
                        const SizedBox(width: 14),
                        UnifiedCommentBar(postId: post.id, iconSize: 18),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 15,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.viewers.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () {
                            final shareLink =
                                'https://kurichiyarmatrimony.com/clan_feed/${post.clanId}/${post.id}';
                            final clanName =
                                getClanById(post.clanId)?.name ??
                                'our Tharavadu';
                            Share.share(
                              'Check out this update in $clanName! Open securely in the app:\n$shareLink',
                            );
                          },
                          icon: const Icon(
                            Icons.share,
                            size: 18,
                            color: Color(0xFF000080),
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'Share securely via WhatsApp',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showAd) {
      return Column(
        children: [
          widget.isGoogleAdTurn
              ? const NativeAdCard()
              : const AdminCustomAdWidget(),
          const SizedBox(height: 12),
          _buildCard(),
        ],
      );
    }
    return _buildCard();
  }
}

class VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerDialog({super.key, required this.videoUrl});

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  VideoPlayerController? _controller;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    Uri? uri;
    try {
      uri = Uri.parse(widget.videoUrl);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Invalid video URL';
        });
      }
      return;
    }

    try {
      // Robust caching: Download/Fetch from cache before initializing
      final file = await DefaultCacheManager().getSingleFile(uri.toString());
      _controller = VideoPlayerController.file(file);

      _controller!.addListener(() {
        if (mounted) {
          if (_controller!.value.hasError && !_hasError) {
            setState(() {
              _hasError = true;
              _errorMessage =
                  _controller!.value.errorDescription ??
                  'Unknown playback error';
            });
          } else {
            setState(() {});
          }
        }
      });

      await _controller!.initialize();
      if (mounted) {
        _controller!.play();
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error loading video: $error';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_hasError)
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'വീഡിയോ പ്ലേ ചെയ്യാൻ കഴിഞ്ഞില്ല\n(Failed to load video)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            )
          else if (_controller != null && _controller!.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            )
          else
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (!_hasError &&
              _controller != null &&
              _controller!.value.isInitialized)
            Positioned(
              bottom: 10,
              child: IconButton(
                icon: Icon(
                  _controller!.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.white,
                  size: 50,
                ),
                onPressed: () {
                  setState(() {
                    if (_controller!.value.isPlaying) {
                      _controller!.pause();
                    } else {
                      _controller!.play();
                    }
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
