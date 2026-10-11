import 'package:flutter/material.dart';
import '../../../core/services/tharavadu_stories_service.dart';
import '../../../core/models/status_category.dart';
import '../../../core/models/status_view_model.dart';
import '../../../core/services/status_view_tracking_service.dart';
import '../../tharavadu_status/ui/widgets/status_viewers_bottom_sheet.dart';

/// Full-screen Instagram/WhatsApp-style Story Viewer for Tharavadu statuses.
///
/// Features:
/// - Top segmented progress bars (5 seconds per story).
/// - Hold to pause, tap right to advance, tap left to go back.
/// - Top header with Tharavadu avatar, name, time ago in Malayalam, and category badge.
/// - High-resolution image/media with semi-transparent bottom caption overlay.
/// - Auto-advance between stories and across Tharavadu groups.
class TharavaduStoryFullScreenViewer extends StatefulWidget {
  final List<TharavaduStoryGroup> storyGroups;
  final int initialGroupIndex;

  const TharavaduStoryFullScreenViewer({
    super.key,
    required this.storyGroups,
    this.initialGroupIndex = 0,
  });

  @override
  State<TharavaduStoryFullScreenViewer> createState() =>
      _TharavaduStoryFullScreenViewerState();
}

class _TharavaduStoryFullScreenViewerState
    extends State<TharavaduStoryFullScreenViewer>
    with SingleTickerProviderStateMixin {
  late int _groupIndex;
  int _storyIndex = 0;
  late AnimationController _animController;
  bool _isPaused = false;
  static const Duration _storyDuration = Duration(seconds: 5);

  TharavaduStoryGroup get _currentGroup => widget.storyGroups[_groupIndex];
  TharavaduStoryItem get _currentStory =>
      _currentGroup.stories[_storyIndex];

  @override
  void initState() {
    super.initState();
    _groupIndex = widget.initialGroupIndex;
    _animController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _startCurrentStory();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startCurrentStory() {
    _animController.reset();
    _animController.forward();
    // Mark as viewed in local service and Firestore view tracking
    TharavaduStoriesService.instance.markStoryViewed(_currentStory.id);
    StatusViewTrackingService.instance.recordStatusView(
      statusId: _currentStory.id,
      authorId: _currentStory.authorId,
    );
  }

  Future<void> _openViewersSheet(StatusViewData data) async {
    _pause();
    await StatusViewersBottomSheet.show(
      context,
      statusId: _currentStory.id,
      initialData: data,
    );
    if (mounted) {
      _resume();
    }
  }

  void _nextStory() {
    if (_storyIndex < _currentGroup.stories.length - 1) {
      setState(() {
        _storyIndex++;
      });
      _startCurrentStory();
    } else if (_groupIndex < widget.storyGroups.length - 1) {
      setState(() {
        _groupIndex++;
        _storyIndex = 0;
      });
      _startCurrentStory();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_storyIndex > 0) {
      setState(() {
        _storyIndex--;
      });
      _startCurrentStory();
    } else if (_groupIndex > 0) {
      setState(() {
        _groupIndex--;
        _storyIndex = widget.storyGroups[_groupIndex].stories.length - 1;
      });
      _startCurrentStory();
    } else {
      _startCurrentStory();
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (_isPaused) {
      _resume();
      return;
    }
    final screenWidth = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < screenWidth / 3) {
      _previousStory();
    } else {
      _nextStory();
    }
  }

  void _pause() {
    if (!_isPaused) {
      setState(() => _isPaused = true);
      _animController.stop();
    }
  }

  void _resume() {
    if (_isPaused) {
      setState(() => _isPaused = false);
      _animController.forward();
    }
  }

  String _formatMalayalamTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ഇപ്പോൾ (Just now)';
    if (diff.inMinutes < 60) return '${diff.inMinutes} മിനിറ്റ് മുൻപ്';
    if (diff.inHours < 24) return '${diff.inHours} മണിക്കൂർ മുൻപ്';
    return '1 ദിവസം മുൻപ്';
  }

  @override
  Widget build(BuildContext context) {
    final story = _currentStory;
    final group = _currentGroup;
    final topPadding = MediaQuery.of(context).padding.top;

    final bool isAuthor =
        StatusViewTrackingService.instance.isStatusOwner(story.authorId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -150) {
            if (isAuthor) {
              final cachedData = StatusViewTrackingService.instance
                  .getCachedViewData(story.id);
              _openViewersSheet(cachedData);
            }
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Story Media Content ──
            _buildStoryMedia(story),

            // Top gradient protection for bars & header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black87,
                      Colors.black45,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom gradient protection for caption
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black87,
                      Colors.black45,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Segmented Progress Bars ──
            Positioned(
              top: topPadding + 10,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(
                  group.stories.length,
                  (i) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, _) {
                          double value = 0.0;
                          if (i < _storyIndex) {
                            value = 1.0;
                          } else if (i == _storyIndex) {
                            value = _animController.value;
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 2.5,
                              backgroundColor: Colors.white30,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Top Header (Avatar, Tharavadu Name, Time Ago, Category, Close) ──
            Positioned(
              top: topPadding + 22,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF1E3A8A),
                    backgroundImage: group.clan.imageUrl != null &&
                            group.clan.imageUrl!.isNotEmpty
                        ? NetworkImage(group.clan.imageUrl!)
                        : null,
                    child: (group.clan.imageUrl == null ||
                            group.clan.imageUrl!.isEmpty)
                        ? const Icon(Icons.temple_hindu,
                            color: Colors.white, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                group.clan.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (story.category != null) ...[
                              const SizedBox(width: 8),
                              StatusCategoryBadge(
                                category: story.category!,
                                compact: true,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatMalayalamTimeAgo(story.createdAt),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 26),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Bottom Caption Text Overlay ──
            if (story.content.trim().isNotEmpty)
              Positioned(
                bottom: isAuthor
                    ? MediaQuery.of(context).padding.bottom + 64
                    : MediaQuery.of(context).padding.bottom + 24,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    story.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // ── Status Owner Bottom Bar (Story Viewer) ──
            if (isAuthor)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 14,
                left: 16,
                right: 16,
                child: StreamBuilder<StatusViewData>(
                  stream: StatusViewTrackingService.instance
                      .streamStatusViewData(story.id),
                  initialData: StatusViewTrackingService.instance
                      .getCachedViewData(story.id),
                  builder: (context, snapshot) {
                    final viewData = snapshot.data ?? const StatusViewData();

                    return Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openViewersSheet(viewData),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                color: Colors.white,
                                size: 19,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${viewData.viewCount} പേർ കണ്ടു',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_up,
                                color: Colors.white70,
                                size: 18,
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
        ),
      ),
    );
  }

  Widget _buildStoryMedia(TharavaduStoryItem story) {
    if (story.mediaUrl != null && story.mediaUrl!.isNotEmpty) {
      return Image.network(
        story.mediaUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildTextBackground(story),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
      );
    }
    return _buildTextBackground(story);
  }

  Widget _buildTextBackground(TharavaduStoryItem story) {
    final catColor = story.category?.color ?? const Color(0xFF1E3A8A);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            catColor,
            const Color(0xFF0F172A),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Text(
          story.content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.4,
            shadows: [
              Shadow(color: Colors.black87, blurRadius: 8),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
