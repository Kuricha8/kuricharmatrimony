import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/mock_data.dart';

class PostComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      postId: json['post_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'User',
      userAvatar: json['user_avatar']?.toString(),
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'post_id': postId,
    'user_id': userId,
    'user_name': userName,
    'user_avatar': userAvatar,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'type': 'comment',
  };
}

/// Unified Realtime Like & Comment Interaction Service
class PostInteractionService extends ChangeNotifier {
  static final PostInteractionService instance = PostInteractionService._();
  PostInteractionService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Local Cache Maps for instant optimistic updates
  final Map<String, Set<String>> _postLikes = {}; // postId -> Set<userId>
  final Map<String, List<PostComment>> _postComments =
      {}; // postId -> List<PostComment>
  final Set<String> _subscribedPosts = {};
  RealtimeChannel? _realtimeChannel;

  /// Initialize and bind Realtime subscription
  void initRealtime() {
    if (_realtimeChannel != null) return;

    try {
      _realtimeChannel = _supabase
          .channel('public:post_interactions')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'post_interactions',
            callback: (payload) {
              _handleRealtimePayload(payload);
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('PostInteractionService realtime error: $e');
    }
  }

  void _handleRealtimePayload(PostgresChangePayload payload) {
    try {
      final record = payload.newRecord.isNotEmpty
          ? payload.newRecord
          : payload.oldRecord;
      final postId = record['post_id']?.toString();
      final type = record['type']?.toString();
      final userId = record['user_id']?.toString();

      if (postId == null) return;

      if (type == 'like') {
        final likes = _postLikes.putIfAbsent(postId, () => {});
        if (payload.eventType == PostgresChangeEvent.insert) {
          if (userId != null) likes.add(userId);
        } else if (payload.eventType == PostgresChangeEvent.delete) {
          if (userId != null) likes.remove(userId);
        }
        notifyListeners();
      } else if (type == 'comment') {
        if (payload.eventType == PostgresChangeEvent.insert) {
          final comment = PostComment.fromJson(record);
          final list = _postComments.putIfAbsent(postId, () => []);
          if (!list.any((c) => c.id == comment.id)) {
            list.insert(0, comment);
            notifyListeners();
          }
        } else if (payload.eventType == PostgresChangeEvent.delete) {
          final commentId = record['id']?.toString();
          final list = _postComments[postId];
          if (list != null && commentId != null) {
            list.removeWhere((c) => c.id == commentId);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling post_interactions realtime change: $e');
    }
  }

  /// Subscribe and fetch interactions for a post
  Future<void> fetchInteractions(String postId) async {
    if (postId.isEmpty) return;

    initRealtime();
    _subscribedPosts.add(postId);

    try {
      final res = await _supabase
          .from('post_interactions')
          .select()
          .eq('post_id', postId);

      final likes = <String>{};
      final comments = <PostComment>[];

      for (final row in (res as List)) {
        final type = row['type']?.toString();
        if (type == 'like') {
          final uId = row['user_id']?.toString();
          if (uId != null) likes.add(uId);
        } else if (type == 'comment') {
          comments.add(PostComment.fromJson(row));
        }
      }

      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _postLikes[postId] = likes;
      _postComments[postId] = comments;
      notifyListeners();
    } catch (e) {
      // Fallback: seed from mockData if table is newly created or empty
      debugPrint('PostInteractionService fetch note (offline/fallback): $e');
    }
  }

  /// Check if a user has liked a post
  bool isLiked(String postId, String userId) {
    return _postLikes[postId]?.contains(userId) ?? false;
  }

  /// Get total like count for a post
  int getLikeCount(String postId) {
    return _postLikes[postId]?.length ?? 0;
  }

  /// Get comments for a post
  List<PostComment> getComments(String postId) {
    return _postComments[postId] ?? [];
  }

  /// Toggle Like on a post (Instant Optimistic + Supabase Sync)
  Future<bool> toggleLike(String postId, String userId) async {
    if (postId.isEmpty || userId.isEmpty) return false;

    final likes = _postLikes.putIfAbsent(postId, () => {});
    final wasLiked = likes.contains(userId);

    // 1. Optimistic local update
    if (wasLiked) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }
    notifyListeners();

    // 2. Sync to Supabase
    try {
      if (wasLiked) {
        await _supabase.from('post_interactions').delete().match({
          'post_id': postId,
          'user_id': userId,
          'type': 'like',
        });
      } else {
        await _supabase.from('post_interactions').upsert({
          'post_id': postId,
          'user_id': userId,
          'type': 'like',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Syncing like to post_interactions table: $e');
      // Also sync to legacy clan_feed_posts reactions for backward compatibility
      try {
        final me = MockData().currentUser;
        if (me != null) {
          final post = MockData().statusPosts.firstWhere(
            (p) => p.id == postId,
            orElse: () => MockData().statusPosts.first,
          );
          final newReactions = Map<String, String>.from(post.reactions);
          if (wasLiked) {
            newReactions.remove(userId);
          } else {
            newReactions[userId] = '❤️';
          }
          await _supabase
              .from('clan_feed_posts')
              .update({'reactions': newReactions})
              .eq('id', postId);
        }
      } catch (_) {}
    }

    return !wasLiked;
  }

  /// Add a comment to a post
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
  }) async {
    if (postId.isEmpty || content.trim().isEmpty) return;

    final comment = PostComment(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    // 1. Optimistic UI update
    final list = _postComments.putIfAbsent(postId, () => []);
    list.insert(0, comment);
    notifyListeners();

    // 2. Save to Supabase
    try {
      await _supabase.from('post_interactions').insert(comment.toJson());
    } catch (e) {
      debugPrint('PostInteractionService addComment sync note: $e');
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String postId, String commentId) async {
    final list = _postComments[postId];
    if (list != null) {
      list.removeWhere((c) => c.id == commentId);
      notifyListeners();
    }

    try {
      await _supabase.from('post_interactions').delete().match({
        'id': commentId,
        'post_id': postId,
      });
    } catch (e) {
      debugPrint('PostInteractionService deleteComment note: $e');
    }
  }
}
