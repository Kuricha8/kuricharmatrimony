import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/post_interaction_service.dart';
import '../utils/mock_data.dart';

class UnifiedLikeButton extends StatefulWidget {
  final String postId;
  final String? userId;
  final bool isDarkTheme;
  final double iconSize;
  final TextStyle? textStyle;
  final VoidCallback? onLiked;

  const UnifiedLikeButton({
    super.key,
    required this.postId,
    this.userId,
    this.isDarkTheme = false,
    this.iconSize = 20,
    this.textStyle,
    this.onLiked,
  });

  @override
  State<UnifiedLikeButton> createState() => _UnifiedLikeButtonState();
}

class _UnifiedLikeButtonState extends State<UnifiedLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
        );

    PostInteractionService.instance.fetchInteractions(widget.postId);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _animController.forward(from: 0.0);

    final me = MockData().currentUser;
    final currentUserId = widget.userId ?? me?.id ?? 'guest_user';

    PostInteractionService.instance.toggleLike(widget.postId, currentUserId);
    widget.onLiked?.call();
  }

  @override
  Widget build(BuildContext context) {
    final me = MockData().currentUser;
    final currentUserId = widget.userId ?? me?.id ?? 'guest_user';

    return ListenableBuilder(
      listenable: PostInteractionService.instance,
      builder: (context, _) {
        final isLiked = PostInteractionService.instance.isLiked(
          widget.postId,
          currentUserId,
        );
        final likeCount = PostInteractionService.instance.getLikeCount(
          widget.postId,
        );

        final heartColor = isLiked
            ? Colors.redAccent
            : (widget.isDarkTheme ? Colors.white70 : const Color(0xFF000080));
        final countColor = widget.isDarkTheme
            ? Colors.white
            : Colors.grey.shade700;

        return GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: heartColor,
                  size: widget.iconSize,
                ),
              ),
              if (likeCount > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '$likeCount',
                  style:
                      widget.textStyle ??
                      TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: countColor,
                      ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
