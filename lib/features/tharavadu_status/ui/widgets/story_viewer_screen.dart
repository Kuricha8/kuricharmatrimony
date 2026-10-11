import 'package:flutter/material.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/status_view_model.dart';
import '../../../../core/services/status_view_tracking_service.dart';
import 'status_viewers_bottom_sheet.dart';

/// Full-featured WhatsApp-style Story Status Viewer with view tracking,
/// owner bottom bar, swipe-up gesture, and minimal viewers sheet.
class StoryViewerScreen extends StatefulWidget {
  final List<AuthorStoryTray> trays;
  final int initialTrayIndex;

  const StoryViewerScreen({
    super.key,
    required this.trays,
    this.initialTrayIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _trayIndex;
  int _storyIndex = 0;
  late AnimationController _animController;
  bool _isPaused = false;
  final TextEditingController _replyController = TextEditingController();

  AuthorStoryTray get _currentTray => widget.trays[_trayIndex];
  EphemeralStory get _currentStory => _currentTray.stories[_storyIndex];

  Duration get _currentStoryDuration {
    if (_currentStory.mediaDurationsMs.isNotEmpty) {
      final ms = _currentStory.mediaDurationsMs.first;
      if (ms > 500) return Duration(milliseconds: ms);
    }
    return const Duration(seconds: 5);
  }

  @override
  void initState() {
    super.initState();
    _trayIndex = widget.initialTrayIndex;
    _animController = AnimationController(
      vsync: this,
      duration: _currentStoryDuration,
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _playCurrentStory();
  }

  @override
  void dispose() {
    _animController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _playCurrentStory() {
    _animController.duration = _currentStoryDuration;
    _animController.reset();
    _animController.forward();

    // WhatsApp-style status view tracking
    StatusViewTrackingService.instance.recordStatusView(
      statusId: _currentStory.id,
      authorId: _currentStory.userId,
    );
  }

  void _nextStory() {
    if (_storyIndex < _currentTray.stories.length - 1) {
      setState(() {
        _storyIndex++;
      });
      _playCurrentStory();
    } else if (_trayIndex < widget.trays.length - 1) {
      setState(() {
        _trayIndex++;
        _storyIndex = 0;
      });
      _playCurrentStory();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_storyIndex > 0) {
      setState(() {
        _storyIndex--;
      });
      _playCurrentStory();
    } else if (_trayIndex > 0) {
      setState(() {
        _trayIndex--;
        _storyIndex = widget.trays[_trayIndex].stories.length - 1;
      });
      _playCurrentStory();
    } else {
      _playCurrentStory();
    }
  }

  void _pause() {
    if (!_isPaused) {
      _isPaused = true;
      _animController.stop();
    }
  }

  void _resume() {
    if (_isPaused) {
      _isPaused = false;
      _animController.forward();
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (_isPaused) {
      FocusScope.of(context).unfocus();
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

  Future<void> _openViewersSheet(StatusViewData viewData) async {
    _pause();
    await StatusViewersBottomSheet.show(
      context,
      statusId: _currentStory.id,
      initialData: viewData,
    );
    if (mounted) {
      _resume();
    }
  }

  String _formatMalayalamTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ഇപ്പോൾ';
    if (diff.inMinutes < 60) return '${diff.inMinutes} മിനിറ്റ് മുൻപ്';
    if (diff.inHours < 24) return '${diff.inHours} മണിക്കൂർ മുൻപ്';
    return '1 ദിവസം മുൻപ്';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trays.isEmpty || _currentTray.stories.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final story = _currentStory;
    final tray = _currentTray;

    // Check if the current logged-in user is the status author
    final bool isAuthor =
        StatusViewTrackingService.instance.isStatusOwner(story.userId) ||
            StatusViewTrackingService.instance.isStatusOwner(tray.authorId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onVerticalDragEnd: (details) {
          // Detect swipe up to open viewers sheet
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
            // ── Main Story Media/Content ──
            _buildStoryMedia(story),

            // Top gradient protection for progress & header
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

            // Bottom gradient protection for caption & bottom bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 180,
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
                  tray.stories.length,
                  (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, _) {
                          double value = 0.0;
                          if (index < _storyIndex) {
                            value = 1.0;
                          } else if (index == _storyIndex) {
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

            // ── Top Header (Author Avatar, Name, Time, Close) ──
            Positioned(
              top: topPadding + 22,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: const Color(0xFF1E3A8A),
                    backgroundImage: (tray.authorAvatar != null &&
                            tray.authorAvatar!.isNotEmpty &&
                            tray.authorAvatar!.startsWith('http'))
                        ? NetworkImage(tray.authorAvatar!)
                        : null,
                    child: (tray.authorAvatar == null ||
                            tray.authorAvatar!.isEmpty ||
                            !tray.authorAvatar!.startsWith('http'))
                        ? const Icon(Icons.person, color: Colors.white, size: 22)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tray.authorName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 4),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
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

            // ── Bottom Caption Text Overlay (if non-empty) ──
            if (story.caption != null && story.caption!.trim().isNotEmpty)
              Positioned(
                bottom: isAuthor
                    ? bottomPadding + 64
                    : bottomPadding + 24,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    story.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // ── Status Owner Bottom Bar (Story Viewer) ──
            // Only visible if the current logged-in user is the status author (status.author_id == currentUser.uid)
            if (isAuthor)
              Positioned(
                bottom: bottomPadding + 14,
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

  Widget _buildStoryMedia(EphemeralStory story) {
    if (story.mediaUrls.isNotEmpty) {
      final url = story.mediaUrls.first;
      if (url.startsWith('http')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildTextBackground(story),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          },
        );
      }
    }

    if (story.storyType == StoryType.audioWave) {
      return _buildAudioWaveBackground(story);
    }

    return _buildTextBackground(story);
  }

  Widget _buildAudioWaveBackground(EphemeralStory story) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F766E),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              story.caption ?? 'വോയ്സ് സ്റ്റാറ്റസ്',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextBackground(EphemeralStory story) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF0F172A),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Center(
        child: Text(
          story.caption ?? '',
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
