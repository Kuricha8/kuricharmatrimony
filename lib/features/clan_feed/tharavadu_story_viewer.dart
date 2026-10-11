import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../../core/services/status_view_tracking_service.dart';
import '../../core/utils/mock_data.dart';
import '../tharavadu_status/ui/widgets/status_viewers_bottom_sheet.dart';

class TharavaduStoryViewer extends StatefulWidget {
  final Clan clan;
  final List<TharavadStory> statuses;
  final VoidCallback onStoryViewed;

  const TharavaduStoryViewer({
    super.key,
    required this.clan,
    required this.statuses,
    required this.onStoryViewed,
  });

  @override
  State<TharavaduStoryViewer> createState() => _TharavaduStoryViewerState();
}

class _TharavaduStoryViewerState extends State<TharavaduStoryViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentIndex = 0;
  bool _isPaused = false;
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _playStory();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _playStory() {
    _animationController.reset();
    _animationController.forward();
    widget.onStoryViewed();
    if (widget.statuses.isNotEmpty && _currentIndex < widget.statuses.length) {
      final story = widget.statuses[_currentIndex];
      StatusViewTrackingService.instance.recordStatusView(
        statusId: story.id,
        authorId: story.creatorId,
      );
    }
  }

  Future<void> _openViewersSheet(String statusId, StatusViewData data) async {
    _animationController.stop();
    setState(() => _isPaused = true);
    await StatusViewersBottomSheet.show(
      context,
      statusId: statusId,
      initialData: data,
    );
    if (mounted) {
      setState(() => _isPaused = false);
      _animationController.forward();
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.statuses.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _playStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _playStory();
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (_isPaused) {
      FocusScope.of(context).unfocus();
      setState(() {
        _isPaused = false;
      });
      _animationController.forward();
      return;
    }
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dx = details.globalPosition.dx;
    if (dx < screenWidth / 3) {
      _previousStory();
    } else {
      _nextStory();
    }
  }

  void _sendReply(String text, TharavadStory story) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _replyController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _isPaused = false;
    });
    _animationController.forward();

    try {
      final currentUser = MockData().currentUser;
      if (currentUser == null) return;

      // Insert notification for status creator
      await Supabase.instance.client.from('notifications').insert({
        'user_id': story.creatorId,
        'title': 'സ്റ്റാറ്റസ് മറുപടി',
        'body': '${currentUser.name} replied to your status: "$trimmed"',
        'type': 'new_message',
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('മറുപടി അയച്ചു!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending status reply: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reply: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.statuses.isEmpty)
  { return const Scaffold(backgroundColor: Colors.black); }

    final currentStatus = (widget.statuses.isNotEmpty &&
            _currentIndex < widget.statuses.length)
        ? widget.statuses[_currentIndex]
        : null;
    final bool isAuthor = currentStatus != null &&
        StatusViewTrackingService.instance
            .isStatusOwner(currentStatus.creatorId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onLongPressStart: (_) => _animationController.stop(),
        onLongPressEnd: (_) => _animationController.forward(),
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < -150) {
            if (isAuthor) {
              final cached = StatusViewTrackingService.instance
                  .getCachedViewData(currentStatus.id);
              _openViewersSheet(currentStatus.id, cached);
            }
          }
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.statuses.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final status = widget.statuses[index];
                return _buildStoryContent(status);
              },
            ),

            // Progress bars
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(
                  widget.statuses.length,
                  (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          double value = 0.0;
                          if (index < _currentIndex) {
                            value = 1.0;
                          } else if (index == _currentIndex) {
                            value = _animationController.value;
                          }
                          return LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            minHeight: 2,
                            borderRadius: BorderRadius.circular(1),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 25,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        widget.clan.imageUrl != null &&
                            widget.clan.imageUrl!.isNotEmpty
                        ? NetworkImage(widget.clan.imageUrl!)
                        : null,
                    backgroundColor: Colors.grey.shade800,
                    child:
                        widget.clan.imageUrl == null ||
                            widget.clan.imageUrl!.isEmpty
                        ? const Icon(Icons.group, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.clan.nameMl.isNotEmpty
                        ? widget.clan.nameMl
                        : widget.clan.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
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
                      .streamStatusViewData(currentStatus.id),
                  initialData: StatusViewTrackingService.instance
                      .getCachedViewData(currentStatus.id),
                  builder: (context, snapshot) {
                    final viewData = snapshot.data ?? const StatusViewData();

                    return Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            _openViewersSheet(currentStatus.id, viewData),
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

            // Reply input for viewer (when not author)
            if (!isAuthor && currentStatus != null)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {}, // Absorb taps
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText:
                                'Reply to ${widget.clan.nameMl.isNotEmpty ? widget.clan.nameMl : widget.clan.name}...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Colors.white24,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.black45,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          onTap: () {
                            _animationController.stop();
                            setState(() {
                              _isPaused = true;
                            });
                          },
                          onSubmitted: (text) {
                            _sendReply(text, widget.statuses[_currentIndex]);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () {
                          _sendReply(
                            _replyController.text,
                            widget.statuses[_currentIndex],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(TharavadStory status) {
    final bool hasContentCaption = status.content.isNotEmpty;

    if (status.isVideo) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_fill, color: Colors.white, size: 80),
              SizedBox(height: 20),
              Text('Video Story', style: TextStyle(color: Colors.white)),
            ],
          ),
          if (hasContentCaption)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    } else {
      if (status.mediaUrl == null || status.mediaUrl!.isEmpty) {
        return Container(
          color: const Color(0xFF000080),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Text(
              status.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(status.mediaUrl!, fit: BoxFit.cover),
          if (hasContentCaption)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    }
  }
}
