class ClanFeedComment {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? userName;
  final String? userPhotoUrl;

  const ClanFeedComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.userName,
    this.userPhotoUrl,
  });

  factory ClanFeedComment.fromMap(Map<String, dynamic> map) {
    return ClanFeedComment(
      id: map['id']?.toString() ?? '',
      postId: map['post_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      content: map['content'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      userName: map['user_name'],
      userPhotoUrl: map['user_photo_url'],
    );
  }
}

class ClanPost {
  final String id;
  final String creatorId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByMe;

  const ClanPost({
    required this.id,
    required this.creatorId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLikedByMe = false,
  });

  factory ClanPost.fromMap(Map<String, dynamic> map, String currentUserId) {
    int views = map['views_count'] ?? 0;
    int likes = map['likes_count'] ?? 0;
    int comments = map['comments_count'] ?? 0;
    bool isLiked = map['is_liked_by_me'] ?? false;

    return ClanPost(
      id: map['id'] as String,
      creatorId: map['creator_id'] as String,
      content: map['content'] as String,
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.parse(map['created_at']),
      viewsCount: views,
      likesCount: likes,
      commentsCount: comments,
      isLikedByMe: isLiked,
    );
  }
}
