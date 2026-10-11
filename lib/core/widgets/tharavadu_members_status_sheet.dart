import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/models/story_model.dart';
import '../../features/tharavadu_status/ui/widgets/story_viewer_screen.dart';
import 'animated_gradient_avatar_ring.dart';

class TharavaduMembersStatusSheet extends StatelessWidget {
  final Clan clan;
  final List<StatusPost> clanStatuses;
  final EphemeralStory Function(StatusPost) toStory;

  const TharavaduMembersStatusSheet({
    super.key,
    required this.clan,
    required this.clanStatuses,
    required this.toStory,
  });

  @override
  Widget build(BuildContext context) {
    // Group status posts by creatorId
    final Map<String, List<StatusPost>> grouped = {};
    for (var post in clanStatuses) {
      grouped.putIfAbsent(post.creatorId, () => []).add(post);
    }

    // Build AuthorStoryTray for each creator
    final List<AuthorStoryTray> trays = [];
    grouped.forEach((creatorId, posts) {
      // Sort posts by creation time ascending
      posts.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final firstPost = posts.first;
      trays.add(
        AuthorStoryTray(
          authorId: creatorId,
          authorName: firstPost.creatorName ?? 'Member',
          authorAvatar: firstPost.creatorPhotoUrl,
          hasUnseen: true,
          latestStoryTime: posts.last.createdAt,
          stories: posts.map(toStory).toList(),
        ),
      );
    });

    // Sort trays by latest story time descending
    trays.sort((a, b) => b.latestStoryTime.compareTo(a.latestStoryTime));

    final String clanName = clan.nameMl.isNotEmpty ? clan.nameMl : clan.name;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle/Grab bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      clan.imageUrl != null && clan.imageUrl!.startsWith('http')
                      ? NetworkImage(clan.imageUrl!)
                      : const AssetImage('assets/images/default_avatar.png')
                            as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clanName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080),
                        ),
                      ),
                      Text(
                        '${trays.length} active status updates',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 1),
          // Member Statuses List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
              itemCount: trays.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final tray = trays[index];
                final timeText = _formatTimeAgo(tray.latestStoryTime);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: AnimatedGradientAvatarRing(
                    paletteIndex: index,
                    hasActiveStatus: true,
                    radius: 26,
                    borderWidth: 2.5,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage:
                          tray.authorAvatar != null &&
                              tray.authorAvatar!.startsWith('http')
                          ? NetworkImage(tray.authorAvatar!)
                          : const AssetImage('assets/images/default_avatar.png')
                                as ImageProvider,
                    ),
                  ),
                  title: Text(
                    tray.authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    timeText,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // Close bottom sheet
                    Navigator.pop(context);
                    // Navigate to story viewer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoryViewerScreen(
                          trays: trays,
                          initialTrayIndex: index,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
