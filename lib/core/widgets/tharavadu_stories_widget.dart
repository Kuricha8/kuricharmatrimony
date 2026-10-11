import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/models.dart';
import '../../core/models/story_model.dart';
import '../../core/utils/mock_data.dart';
import '../../features/clan_feed/tharavadu_list.dart';
import '../../features/tharavadu_status/ui/screens/story_creation_studio.dart';
import '../../features/tharavadu_status/ui/widgets/story_viewer_screen.dart';
import '../services/status_service.dart';
import 'tharavadu_members_status_sheet.dart';
import 'animated_gradient_avatar_ring.dart';

class TharavaduStoriesWidget extends StatefulWidget {
  final UserProfile? currentUser;
  const TharavaduStoriesWidget({super.key, this.currentUser});

  @override
  State<TharavaduStoriesWidget> createState() => _TharavaduStoriesWidgetState();
}

class _TharavaduStoriesWidgetState extends State<TharavaduStoriesWidget> {
  @override
  void initState() {
    super.initState();
    if (widget.currentUser != null && widget.currentUser?.role != 'guest') {
      StatusService.instance.subscribeToStatuses();
      StatusService.instance.fetchStatuses();
    }
  }

  int _getClanId(StatusPost p) {
    if (p.clanId > 0) return p.clanId;
    final pr = MockData().profiles.firstWhere(
      (u) => u.id == p.creatorId,
      orElse: () => UserProfile.guest(),
    );
    if (pr.motherClanId > 0) return pr.motherClanId;
    if (pr.fatherClanId > 0) return pr.fatherClanId;
    return (pr.motherTharavadu?.isNotEmpty == true
            ? getClanByName(pr.motherTharavadu!)?.id
            : null) ??
        0;
  }

  EphemeralStory _toStory(StatusPost s) {
    Map<String, dynamic> meta = {};
    String text = s.content.trim();
    String media = (s.feedPhotoUrl ?? s.videoUrl ?? '').trim();
    if (text.startsWith('{') && text.endsWith('}')) {
      try {
        final d = jsonDecode(text) as Map<String, dynamic>;
        meta.addAll(d);
        text =
            d['text']?.toString() ??
            d['caption']?.toString() ??
            d['content']?.toString() ??
            '';
        if (d['media_url'] != null && media.isEmpty)
  { media = d['media_url'].toString().trim(); }
      } catch (_) {}
    }
    if (s.backgroundColor != null && meta['backgroundColor'] == null)
  { meta['backgroundColor'] = s.backgroundColor; }
    if (s.creatorName != null && meta['author_name'] == null)
  { meta['author_name'] = s.creatorName; }
    if (s.creatorPhotoUrl != null && meta['author_avatar'] == null)
  { meta['author_avatar'] = s.creatorPhotoUrl; }
    final isMedia = media.isNotEmpty && !media.startsWith('{');
    final isAudio =
        s.postType == PostType.audio ||
        media.endsWith('.mp3') ||
        meta['audio_overlay'] != null;
    return EphemeralStory(
      id: s.id,
      userId: s.creatorId,
      storyType: isAudio ? StoryType.audioWave : StoryType.standard,
      mediaType: s.postType == PostType.video
          ? 'video'
          : (isMedia ? 'image' : (isAudio ? 'audio' : 'text')),
      mediaUrls: isMedia ? [media] : [],
      mediaDurationsMs: [s.videoDuration ?? (isAudio ? 15000 : 5000)],
      caption: text,
      metadata: meta,
      privacyType: PrivacyType.public,
      createdAt: s.createdAt,
      expiresAt: s.createdAt.add(const Duration(hours: 24)),
    );
  }

  void _showChooser(BuildContext context) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _btn(
            ctx,
            Icons.add_a_photo,
            'ഫോട്ടോ/വീഡിയോ',
            Colors.purple,
            StoryType.standard,
          ),
          _btn(
            ctx,
            Icons.text_fields,
            'ടെക്സ്റ്റ്',
            Colors.deepOrange,
            StoryType.standard,
          ),
          _btn(ctx, Icons.mic, 'വോയ്സ്', Colors.teal, StoryType.audioWave),
        ],
      ),
    ),
  );

  Widget _btn(
    BuildContext ctx,
    IconData icon,
    String label,
    Color color,
    StoryType type,
  ) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      if (ctx.mounted && Navigator.canPop(ctx)) {
        Navigator.pop(ctx);
      }
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoryCreationStudio(initialStoryType: type),
          ),
        );
      }
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null || widget.currentUser?.role == 'guest')
  { return const SizedBox.shrink(); }
    final me = widget.currentUser!;
    return ListenableBuilder(
      listenable: Listenable.merge([StatusService.instance, MockData()]),
      builder: (context, _) {
        final statusPosts = MockData().statusPosts
            .where((p) => !p.isExpired)
            .toList();
        final displayClans = allClans
            .where((c) => statusPosts.any((p) => _getClanId(p) == c.id))
            .toList();
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade200, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.donut_large,
                    size: 16,
                    color: Color(0xFF000080),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'തറവാട് സ്റ്റാറ്റസുകൾ (${statusPosts.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF5C3E00),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showChooser(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000080).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, size: 12, color: Color(0xFF000080)),
                          SizedBox(width: 2),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF000080),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayClans.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final String pUrl = me.photoUrl.trim();
                      final myPic = pUrl.startsWith('http')
                          ? NetworkImage(pUrl) as ImageProvider
                          : (pUrl.isNotEmpty && File(pUrl).existsSync()
                                ? FileImage(File(pUrl)) as ImageProvider
                                : const AssetImage(
                                    'assets/images/default_avatar.png',
                                  ));
                      final myStatuses = statusPosts
                          .where((p) => p.creatorId == me.id)
                          .toList();
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (myStatuses.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StoryViewerScreen(
                                  trays: [
                                    AuthorStoryTray(
                                      authorId: me.id,
                                      authorName: me.name,
                                      authorAvatar: me.photoUrl,
                                      hasUnseen: false,
                                      latestStoryTime:
                                          myStatuses.first.createdAt,
                                      stories: myStatuses
                                          .map(_toStory)
                                          .toList(),
                                    ),
                                  ],
                                  initialTrayIndex: 0,
                                ),
                              ),
                            );
                          } else {
                            _showChooser(context);
                          }
                        },
                        child: Column(
                          children: [
                            AnimatedGradientAvatarRing(
                              isMyStatus: true,
                              hasActiveStatus: myStatuses.isNotEmpty,
                              radius: 26,
                              borderWidth: 2.5,
                              child: CircleAvatar(
                                radius: 24,
                                backgroundImage: myPic,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'My Status',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final clan = displayClans[index - 1];
                    final name = clan.nameMl.isNotEmpty
                        ? clan.nameMl
                        : clan.name;
                    final clanStatuses = statusPosts
                        .where((p) => _getClanId(p) == clan.id)
                        .toList();
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => TharavaduMembersStatusSheet(
                            clan: clan,
                            clanStatuses: clanStatuses,
                            toStory: _toStory,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          AnimatedGradientAvatarRing(
                            paletteIndex: index - 1,
                            hasActiveStatus: clanStatuses.isNotEmpty,
                            radius: 26,
                            borderWidth: 2.5,
                            child: CircleAvatar(
                              radius: 24,
                              backgroundImage:
                                  clan.imageUrl != null &&
                                      clan.imageUrl!.startsWith('http')
                                  ? NetworkImage(clan.imageUrl!)
                                  : const AssetImage(
                                      'assets/images/default_avatar.png',
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 58,
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF000080),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
