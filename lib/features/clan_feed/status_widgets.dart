import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/utils/mock_data.dart';
import 'dart:async';
import 'dart:io';

class StatusCircle extends StatelessWidget {
  final List<StatusPost> userStatuses;
  final UserProfile user;
  final VoidCallback onTap;

  const StatusCircle({
    super.key,
    required this.userStatuses,
    required this.user,
    required this.onTap,
  });

  Color _getRingColor() {
    final me = MockData().currentUser;
    if (me == null) return Colors.grey;

    // Check if all statuses are viewed by me
    final allViewed = userStatuses.every(
      (s) => s.views.any((v) => v.viewerIdHash == me.id),
    );
    if (allViewed) return Colors.grey.shade400;

    // Colorful rings for unread
    final colors = [
      const Color(0xFFFFD700), // Yellow
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFF9800), // Orange
      const Color(0xFF009688), // Teal
    ];

    // Use user ID hash to pick a consistent color for this user's circle
    final index = user.id.hashCode.abs() % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = _getRingColor();

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 3),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    (user.photoUrl.isNotEmpty &&
                        user.photoUrl.startsWith('http'))
                    ? NetworkImage(user.photoUrl) as ImageProvider
                    : (user.photoUrl.isNotEmpty &&
                          File(user.photoUrl).existsSync())
                    ? FileImage(File(user.photoUrl)) as ImageProvider
                    : const AssetImage('assets/images/default_avatar.png'),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 70,
              child: Text(
                user.name.split(' ')[0],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusViewer extends StatefulWidget {
  final List<UserProfile> users;
  final Map<String, List<StatusPost>> groupedStatuses;
  final int initialUserIndex;

  const StatusViewer({
    super.key,
    required this.users,
    required this.groupedStatuses,
    required this.initialUserIndex,
  });

  @override
  State<StatusViewer> createState() => _StatusViewerState();
}

class _StatusViewerState extends State<StatusViewer> {
  late int _currentUserIndex;
  int _currentIndex = 0;
  double _progress = 0.0;
  Timer? _timer;
  static const _duration = Duration(seconds: 5);
  bool _isMediaLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUserIndex = widget.initialUserIndex;
    _checkAndSetMediaLoading();
    _markCurrentAsViewed();
    _startTimer();
  }

  List<StatusPost> get _currentStatuses {
    if (_currentUserIndex >= widget.users.length || _currentUserIndex < 0)
  { return []; }
    final userId = widget.users[_currentUserIndex].id;
    return widget.groupedStatuses[userId] ?? [];
  }

  UserProfile get _currentUser {
    return widget.users[_currentUserIndex];
  }

  void _checkAndSetMediaLoading() {
    final statuses = _currentStatuses;
    if (statuses.isEmpty || _currentIndex >= statuses.length) {
      _isMediaLoading = false;
      return;
    }
    final status = statuses[_currentIndex];
    _isMediaLoading =
        status.postType == PostType.photo && status.feedPhotoUrl != null;
  }

  void _markCurrentAsViewed() {
    final me = MockData().currentUser;
    final statuses = _currentStatuses;
    if (me != null && statuses.isNotEmpty && _currentIndex < statuses.length) {
      MockData().viewStatusPost(statuses[_currentIndex].id, me);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isMediaLoading) {
        // Pause progression while loading
        return;
      }
      setState(() {
        _progress += 50 / _duration.inMilliseconds;
        if (_progress >= 1.0) {
          _timer?.cancel();
          _nextStatus();
        }
      });
    });
  }

  void _nextStatus() {
    final statuses = _currentStatuses;
    if (_currentIndex < statuses.length - 1) {
      setState(() {
        _currentIndex++;
        _progress = 0.0;
        _checkAndSetMediaLoading();
      });
      _markCurrentAsViewed();
      _startTimer();
    } else if (_currentUserIndex < widget.users.length - 1) {
      setState(() {
        _currentUserIndex++;
        _currentIndex = 0;
        _progress = 0.0;
        _checkAndSetMediaLoading();
      });
      _markCurrentAsViewed();
      _startTimer();
    } else {
      _timer?.cancel();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _previousStatus() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _progress = 0.0;
        _checkAndSetMediaLoading();
      });
      _markCurrentAsViewed();
      _startTimer();
    } else if (_currentUserIndex > 0) {
      setState(() {
        _currentUserIndex--;
        _currentIndex = _currentStatuses.length - 1;
        _progress = 0.0;
        _checkAndSetMediaLoading();
      });
      _markCurrentAsViewed();
      _startTimer();
    }
  }

  void _onMediaLoadError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Skip corrupt status
        _nextStatus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statuses = _currentStatuses;
    if (statuses.isEmpty || _currentIndex >= statuses.length) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final currentStatus = statuses[_currentIndex];
    final user = _currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Content
          Center(child: _buildStatusContent(currentStatus)),

          // View Count for Owner
          if (MockData().currentUser?.id == user.id)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.remove_red_eye_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${currentStatus.views.length} Views',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top Bars & User Info
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Progress Bars
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: List.generate(
                      statuses.length,
                      (index) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: LinearProgressIndicator(
                            value: index < _currentIndex
                                ? 1.0
                                : (index == _currentIndex ? _progress : 0.0),
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                            minHeight: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // User Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey,
                        backgroundImage:
                            (user.photoUrl.isNotEmpty &&
                                user.photoUrl.startsWith('http'))
                            ? NetworkImage(user.photoUrl) as ImageProvider
                            : (user.photoUrl.isNotEmpty &&
                                  File(user.photoUrl).existsSync())
                            ? FileImage(File(user.photoUrl)) as ImageProvider
                            : const AssetImage(
                                'assets/images/default_avatar.png',
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.notifications_off_outlined,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    MockData().muteUser(user.id);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${user.name} muted.'),
                                      ),
                                    );
                                  },
                                  tooltip: 'Mute Status',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                            Text(
                              '${currentStatus.createdAt.hour}:${currentStatus.createdAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Taps
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _previousStatus,
                  child: Container(color: Colors.transparent),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _nextStatus,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusContent(StatusPost status) {
    if (status.postType == PostType.photo) {
      if (status.feedPhotoUrl == null || status.feedPhotoUrl!.isEmpty) {
        _onMediaLoadError();
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      }
      return Image.network(
        status.feedPhotoUrl!,
        fit: BoxFit.contain,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            if (_isMediaLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _isMediaLoading = false;
                  });
                }
              });
            }
            return child;
          }
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          _onMediaLoadError();
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        },
      );
    } else if (status.postType == PostType.video && status.videoUrl != null) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_fill, color: Colors.white, size: 80),
          SizedBox(height: 20),
          Text(
            'Video Status Playing...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      );
    } else if (status.postType == PostType.promotion) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000080), Color(0xFF000040)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'KURICHIYAR MATRIMONY',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 46,
                    backgroundImage:
                        (_currentUser.photoUrl.isNotEmpty &&
                            _currentUser.photoUrl.startsWith('http'))
                        ? NetworkImage(_currentUser.photoUrl) as ImageProvider
                        : (_currentUser.photoUrl.isNotEmpty &&
                              File(_currentUser.photoUrl).existsSync())
                        ? FileImage(File(_currentUser.photoUrl))
                              as ImageProvider
                        : const AssetImage('assets/images/default_avatar.png'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _currentUser.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_currentUser.age} Years • ${_currentUser.job}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(
                  _currentUser.region,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Interested? Check my profile in Matches!',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Text Status
      final bgColor = status.backgroundColor != null
          ? Color(int.parse(status.backgroundColor!.replaceFirst('#', '0xFF')))
          : Colors.indigo;
      final textColor = status.textColor != null
          ? Color(int.parse(status.textColor!.replaceFirst('#', '0xFF')))
          : Colors.white;

      return Container(
        color: bgColor,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(40),
        child: Text(
          status.content,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}
