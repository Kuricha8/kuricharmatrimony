import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/post_interaction_service.dart';
import '../utils/mock_data.dart';

class UnifiedCommentBar extends StatelessWidget {
  final String postId;
  final bool isDarkTheme;
  final double iconSize;
  final VoidCallback? onOpen;

  const UnifiedCommentBar({
    super.key,
    required this.postId,
    this.isDarkTheme = false,
    this.iconSize = 18,
    this.onOpen,
  });

  void _showCommentsSheet(BuildContext context) {
    onOpen?.call();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheetContent(postId: postId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PostInteractionService.instance,
      builder: (context, _) {
        final comments = PostInteractionService.instance.getComments(postId);
        final iconColor = isDarkTheme
            ? Colors.white70
            : const Color(0xFF000080);
        final textColor = isDarkTheme ? Colors.white : Colors.grey.shade700;

        return GestureDetector(
          onTap: () => _showCommentsSheet(context),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.comment_outlined, size: iconSize, color: iconColor),
              if (comments.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  '${comments.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
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

class _CommentsSheetContent extends StatefulWidget {
  final String postId;
  const _CommentsSheetContent({required this.postId});

  @override
  State<_CommentsSheetContent> createState() => _CommentsSheetContentState();
}

class _CommentsSheetContentState extends State<_CommentsSheetContent> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    PostInteractionService.instance.fetchInteractions(widget.postId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final me = MockData().currentUser;
    final userId = me?.id ?? 'guest_user';
    final userName = me?.name.isNotEmpty == true
        ? me!.name
        : 'Community Member';
    final userAvatar = me?.photoUrl;

    setState(() => _isPosting = true);
    _commentController.clear();
    HapticFeedback.lightImpact();

    await PostInteractionService.instance.addComment(
      postId: widget.postId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: text,
    );

    if (mounted) {
      setState(() => _isPosting = false);
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'ഇപ്പോൾ (Just now)';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'അഭിപ്രായങ്ങൾ (Comments)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF000080),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 16),

          // Comments List
          Expanded(
            child: ListenableBuilder(
              listenable: PostInteractionService.instance,
              builder: (context, _) {
                final comments = PostInteractionService.instance.getComments(
                  widget.postId,
                );
                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'ഇതുവരെ അഭിപ്രായങ്ങൾ ഒന്നും വന്നിട്ടില്ല.\nആദ്യത്തെ അഭിപ്രായം എഴുതൂ!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: comments.length,
                  separatorBuilder: (_, _) => const Divider(height: 12),
                  itemBuilder: (context, idx) {
                    final comment = comments[idx];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.indigo.shade50,
                          backgroundImage:
                              comment.userAvatar != null &&
                                  comment.userAvatar!.startsWith('http')
                              ? NetworkImage(comment.userAvatar!)
                              : null,
                          child:
                              comment.userAvatar == null ||
                                  !comment.userAvatar!.startsWith('http')
                              ? Text(
                                  comment.userName.isNotEmpty
                                      ? comment.userName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF000080),
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    comment.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _formatTime(comment.createdAt),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                comment.content,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.3,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'ഒരു അഭിപ്രായം എഴുതൂ...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isPosting
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          onPressed: _submitComment,
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFF000080),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
