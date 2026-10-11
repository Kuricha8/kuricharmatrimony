import 'package:flutter/material.dart';
import '../models/models.dart';
import 'watermarked_image.dart';

class CommunityContentCard extends StatelessWidget {
  final String title;
  final String content;
  final String? imageUrl;
  final String date;
  final IconData icon;
  final Color iconColor;
  final int? maxLines;

  const CommunityContentCard({
    super.key,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.date,
    required this.icon,
    this.iconColor = const Color(0xFF000080),
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            WatermarkedImage(imageUrl: imageUrl!, height: 150),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5C3E00),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  maxLines: maxLines ?? 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    date,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnnouncementsSection extends StatelessWidget {
  final List<Announcement> announcements;
  const AnnouncementsSection({super.key, required this.announcements});

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.campaign, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                'അറിയിപ്പുകൾ (Announcements)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 310,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final ann = announcements[index];
              final hasImage = ann.imageUrl != null && ann.imageUrl!.isNotEmpty;
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16, bottom: 8),
                child: CommunityContentCard(
                  title: 'Important Alert',
                  content: ann.message,
                  imageUrl: ann.imageUrl,
                  date:
                      '${ann.createdAt.day}/${ann.createdAt.month}/${ann.createdAt.year}',
                  icon: Icons.info_outline,
                  iconColor: Colors.orange,
                  maxLines: hasImage ? 2 : 6,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class HistorySection extends StatelessWidget {
  final List<CommunityHistory> history;
  const HistorySection({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.history_edu, color: Colors.teal, size: 24),
              SizedBox(width: 8),
              Text(
                'ചരിത്രം (Community History)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return CommunityContentCard(
              title: item.title,
              content: item.content,
              imageUrl: item.imageUrl,
              date: '${item.date.day}/${item.date.month}/${item.date.year}',
              icon: Icons.history_edu,
              iconColor: Colors.teal,
              maxLines: 8,
            );
          },
        ),
      ],
    );
  }
}
