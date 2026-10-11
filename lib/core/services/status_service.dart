import 'dart:convert';
import 'package:flutter/painting.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../utils/mock_data.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'local_cache_service.dart';
import 'image_compression_service.dart';

class StatusService extends ChangeNotifier {
  static final StatusService instance = StatusService._();
  StatusService._();

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _statusChannel;

  List<StatusPost> _activeStatuses = [];
  List<StatusPost> get activeStatuses => _activeStatuses;
  List<StatusPost> get cachedStatuses => _activeStatuses;

  String? lastFetchError;
  int rowsFetched = 0;
  List<String> mappingErrors = [];
  int storiesLoadedCount = 0;
  bool isFetching = false;

  void addStatusLocally(StatusPost newStory) {
    _activeStatuses.removeWhere((s) => s.id == newStory.id);
    _activeStatuses.insert(0, newStory);
    MockData().statusPosts.removeWhere((s) => s.id == newStory.id);
    MockData().statusPosts.insert(0, newStory);
    notifyListeners();
    debugPrint('[StatusService] Prepending new status locally: ${newStory.id}');
  }

  Future<List<Map<String, dynamic>>> fetchActiveTharavaduTray() async {
    try {
      final response = await _supabase.rpc('get_active_tharavadu_tray');
      if (response != null && response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching active tharavadu tray RPC: $e');
      return [];
    }
  }

  Future<bool> uploadTharavaduStatus({
    required File file,
    required String userId,
    required String userName,
    required String tharavadName,
    String mediaType = 'image',
    String? caption,
  }) async {
    try {
      final extension = file.path.split('.').last;
      final fileName =
          'status_${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _supabase.storage.from('status_media').upload(fileName, file);
      final mediaUrl = _supabase.storage
          .from('status_media')
          .getPublicUrl(fileName);

      await _supabase.from('tharavadu_statuses').insert({
        'user_id': userId,
        'user_name': userName,
        'tharavad_name': tharavadName,
        'media_url': mediaUrl,
        'media_type': mediaType,
        'caption': caption ?? '',
      });

      await fetchStatuses();
      return true;
    } catch (e) {
      debugPrint('Error uploading tharavadu status: $e');
      return false;
    }
  }

  void subscribeToStatuses() {
    if (_statusChannel != null) return;

    _statusChannel = _supabase
        .channel('public:statuses_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'statuses',
          callback: (payload) {
            final deletedId = payload.oldRecord['id']?.toString();
            if (deletedId != null) {
              _activeStatuses.removeWhere((s) => s.id == deletedId);
              MockData().removeStatusPost(deletedId);
              MockData().removeTharavadStory(deletedId);
              notifyListeners();
              debugPrint('[StatusService Realtime] Deleted status: $deletedId');
            } else {
              fetchStatuses();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'statuses',
          callback: (payload) {
            try {
              final newRow = payload.newRecord;
              if (newRow.isNotEmpty) {
                final post = StatusPost.fromMap(newRow);
                addStatusLocally(post);
              }
            } catch (_) {}
            fetchStatuses();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'tharavad_stories',
          callback: (payload) {
            final deletedId = payload.oldRecord['id']?.toString();
            if (deletedId != null) {
              _activeStatuses.removeWhere((s) => s.id == deletedId);
              MockData().removeStatusPost(deletedId);
              MockData().removeTharavadStory(deletedId);
              notifyListeners();
            } else {
              fetchStatuses();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'tharavad_stories',
          callback: (payload) {
            fetchStatuses();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'user_stories',
          callback: (payload) {
            final deletedId = payload.oldRecord['id']?.toString();
            if (deletedId != null) {
              _activeStatuses.removeWhere((s) => s.id == deletedId);
              MockData().removeStatusPost(deletedId);
              MockData().removeTharavadStory(deletedId);
              notifyListeners();
            } else {
              fetchStatuses();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'user_stories',
          callback: (payload) {
            fetchStatuses();
          },
        )
        .subscribe();

    fetchStatuses();
  }

  void _logDiagnostic(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Future<void> fetchStatuses() async {
    isFetching = true;
    lastFetchError = null;
    mappingErrors = [];
    notifyListeners();

    try {
      List<dynamic> rawRows = [];
      final existingIds = <String>{};

      void addRows(String tableName, List<dynamic> rows) {
        debugPrint('DEBUG RAW STATUS COUNT ($tableName): ${rows.length}');
        for (final row in rows) {
          final id = row['id']?.toString();
          if (id != null && !existingIds.contains(id)) {
            existingIds.add(id);
            rawRows.add(row);
          } else if (id == null) {
            rawRows.add(row);
          }
        }
      }

      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      final cutoffIso = cutoff.toUtc().toIso8601String();

      // 1. stories table
      try {
        _logDiagnostic(
          '[DIAGNOSTIC] EXECUTING QUERY: supabase.from("stories").select("*")',
        );
        final res = await _supabase
            .from('stories')
            .select(
              '*, author:profiles(id, full_name, name, photo_url, avatar_url, tharavadu_name)',
            )
            .gte('created_at', cutoffIso)
            .order('created_at', ascending: false)
            .limit(15);
        _logDiagnostic(
          '[DIAGNOSTIC] RAW JSON RESPONSE FROM "stories": ${jsonEncode(res)}',
        );
        addRows('stories', res);
      } catch (e) {
        try {
          final res = await _supabase
              .from('stories')
              .select('*')
              .gte('created_at', cutoffIso)
              .order('created_at', ascending: false)
              .limit(15);
          addRows('stories', res);
        } catch (_) {}
      }

      // 2. tharavad_stories table
      try {
        _logDiagnostic(
          '[DIAGNOSTIC] EXECUTING QUERY: supabase.from("tharavad_stories").select("*")',
        );
        final res = await _supabase
            .from('tharavad_stories')
            .select(
              '*, author:kurichiyar_profiles(id, full_name, photo_url, mother_tharavadu)',
            )
            .gte('created_at', cutoffIso)
            .order('created_at', ascending: false)
            .limit(15);
        _logDiagnostic(
          '[DIAGNOSTIC] RAW JSON RESPONSE FROM "tharavad_stories": ${jsonEncode(res)}',
        );
        addRows('tharavad_stories', res);
      } catch (e) {
        try {
          final res = await _supabase
              .from('tharavad_stories')
              .select('*')
              .gte('created_at', cutoffIso)
              .order('created_at', ascending: false)
              .limit(15);
          addRows('tharavad_stories', res);
        } catch (_) {}
      }

      // 3. user_stories table
      try {
        _logDiagnostic(
          '[DIAGNOSTIC] EXECUTING QUERY: supabase.from("user_stories").select("*")',
        );
        final res = await _supabase
            .from('user_stories')
            .select('*')
            .gte('created_at', cutoffIso)
            .order('created_at', ascending: false)
            .limit(15);
        _logDiagnostic(
          '[DIAGNOSTIC] RAW JSON RESPONSE FROM "user_stories": ${jsonEncode(res)}',
        );
        if (res.isNotEmpty) {
          final mapped = res
              .map(
                (row) => {
                  'id': row['id']?.toString(),
                  'creator_id':
                      row['user_id']?.toString() ??
                      row['creator_id']?.toString(),
                  'clan_id': row['clan_id'] ?? row['tharavad_id'] ?? 0,
                  'content': row['content'] ?? row['caption'] ?? '',
                  'feed_photo_url': row['media_url'] ?? row['photo_url'],
                  'created_at': row['created_at'],
                  'expires_at': row['expires_at'],
                  'post_type': row['media_type'] ?? 'photo',
                  'creator_name': row['user_name'] ?? row['creator_name'],
                  'creator_photo_url': row['avatar_url'] ?? row['photo_url'],
                },
              )
              .toList();
          addRows('user_stories', mapped);
        }
      } catch (e) {
        _logDiagnostic('[DIAGNOSTIC] user_stories query skipped/error: $e');
      }

      // 4. statuses table
      try {
        _logDiagnostic(
          '[DIAGNOSTIC] EXECUTING QUERY: supabase.from("statuses").select("*")',
        );
        final res = await _supabase
            .from('statuses')
            .select(
              '*, author:profiles(id, full_name, name, photo_url, avatar_url, tharavadu_name)',
            )
            .gte('created_at', cutoffIso)
            .order('created_at', ascending: false)
            .limit(15);
        _logDiagnostic(
          '[DIAGNOSTIC] RAW JSON RESPONSE FROM "statuses": ${jsonEncode(res)}',
        );
        addRows('statuses', res);
      } catch (e) {
        try {
          final res = await _supabase
              .from('statuses')
              .select('*')
              .gte('created_at', cutoffIso)
              .order('created_at', ascending: false)
              .limit(15);
          addRows('statuses', res);
        } catch (_) {}
      }

      // 5. active_statuses view
      try {
        _logDiagnostic(
          '[DIAGNOSTIC] EXECUTING QUERY: supabase.from("active_statuses").select("*")',
        );
        final res = await _supabase
            .from('active_statuses')
            .select('*')
            .gte('created_at', cutoffIso)
            .order('created_at', ascending: false)
            .limit(15);
        _logDiagnostic(
          '[DIAGNOSTIC] RAW JSON RESPONSE FROM "active_statuses": ${jsonEncode(res)}',
        );
        addRows('active_statuses', res);
      } catch (e) {
        _logDiagnostic('[DIAGNOSTIC] active_statuses query skipped/error: $e');
      }

      // 6. tharavadu_statuses table
      try {
        _logDiagnostic(
          '[DIAGNOSTIC] EXECUTING QUERY: supabase.from("tharavadu_statuses").select("*")',
        );
        final res = await _supabase
            .from('tharavadu_statuses')
            .select(
              '*, author:profiles(id, full_name, name, photo_url, avatar_url, tharavadu_name)',
            )
            .gte('created_at', cutoffIso)
            .order('created_at', ascending: false)
            .limit(15);
        _logDiagnostic(
          '[DIAGNOSTIC] RAW JSON RESPONSE FROM "tharavadu_statuses": ${jsonEncode(res)}',
        );
        addRows('tharavadu_statuses', res);
      } catch (e) {
        try {
          final res = await _supabase
              .from('tharavadu_statuses')
              .select('*')
              .gte('created_at', cutoffIso)
              .order('created_at', ascending: false)
              .limit(15);
          addRows('tharavadu_statuses', res);
        } catch (_) {}
      }

      // 7. clan_feed_posts table
      if (rawRows.isEmpty) {
        try {
          _logDiagnostic(
            '[DIAGNOSTIC] EXECUTING QUERY: supabase.from("clan_feed_posts").select("*")',
          );
          final res = await _supabase
              .from('clan_feed_posts')
              .select('*')
              .gte('created_at', cutoffIso)
              .order('created_at', ascending: false)
              .limit(15);
          _logDiagnostic(
            '[DIAGNOSTIC] RAW JSON RESPONSE FROM "clan_feed_posts": ${jsonEncode(res)}',
          );
          addRows('clan_feed_posts', res);
        } catch (e) {
          _logDiagnostic(
            '[DIAGNOSTIC] clan_feed_posts query skipped/error: $e',
          );
        }
      }

      rowsFetched = rawRows.length;
      debugPrint('DEBUG RAW STATUS COUNT (TOTAL COMBINED): $rowsFetched');
      _logDiagnostic(
        '[DIAGNOSTIC] TOTAL RAW ROWS FETCHED ACROSS ALL TABLES: $rowsFetched',
      );

      final list = <StatusPost>[];
      for (int i = 0; i < rawRows.length; i++) {
        try {
          final jsonMap = Map<String, dynamic>.from(rawRows[i]);
          final post = StatusPost.fromMap(jsonMap);
          list.add(post);
        } catch (e) {
          final errStr = "Error parsing field in item #$i: $e";
          _logDiagnostic('[DIAGNOSTIC] $errStr');
          mappingErrors.add(errStr);
        }
      }

      // Batch Author Profile Enrichment across all active creators
      try {
        final creatorIds = list
            .where((p) => p.creatorId.isNotEmpty)
            .map((p) => p.creatorId)
            .toSet()
            .toList();

        if (creatorIds.isNotEmpty) {
          // A. Enrich from kurichiyar_profiles
          try {
            final kpRes = await _supabase
                .from('kurichiyar_profiles')
                .select(
                  'id, full_name, photo_url, mother_tharavadu, father_tharavadu, gender',
                )
                .inFilter('id', creatorIds);

            final Map<String, Map<String, dynamic>> profileMap = {
              for (var r in (kpRes as List)) r['id']?.toString() ?? '': r,
            };

            for (int i = 0; i < list.length; i++) {
              final p = list[i];
              final prof = profileMap[p.creatorId];
              if (prof != null) {
                final resolvedName =
                    (prof['full_name'] != null &&
                        prof['full_name'].toString().isNotEmpty)
                    ? prof['full_name'].toString()
                    : p.creatorName;
                final resolvedPhoto =
                    (prof['photo_url'] != null &&
                        prof['photo_url'].toString().isNotEmpty)
                    ? prof['photo_url'].toString()
                    : p.creatorPhotoUrl;
                final resolvedTharavadu =
                    prof['mother_tharavadu']?.toString() ?? p.creatorTharavadu;

                list[i] = p.copyWith(
                  creatorName: resolvedName,
                  creatorPhotoUrl: resolvedPhoto,
                  creatorTharavadu: resolvedTharavadu,
                );
              }
            }
          } catch (e) {
            _logDiagnostic(
              '[DIAGNOSTIC] kurichiyar_profiles enrichment skipped: $e',
            );
          }

          // B. Enrich from profiles table
          try {
            final pRes = await _supabase
                .from('profiles')
                .select('*')
                .inFilter('id', creatorIds);

            final Map<String, Map<String, dynamic>> pMap = {
              for (var r in (pRes as List)) r['id']?.toString() ?? '': r,
            };

            for (int i = 0; i < list.length; i++) {
              final p = list[i];
              final prof = pMap[p.creatorId];
              if (prof != null) {
                final name = prof['full_name'] ?? prof['name'];
                final photo = prof['photo_url'] ?? prof['avatar_url'];
                list[i] = p.copyWith(
                  creatorName: (p.creatorName == null || p.creatorName!.isEmpty)
                      ? name?.toString()
                      : p.creatorName,
                  creatorPhotoUrl:
                      (p.creatorPhotoUrl == null || p.creatorPhotoUrl!.isEmpty)
                      ? photo?.toString()
                      : p.creatorPhotoUrl,
                  creatorTharavadu:
                      (p.creatorTharavadu == null ||
                          p.creatorTharavadu!.isEmpty)
                      ? prof['tharavadu_name']?.toString()
                      : p.creatorTharavadu,
                );
              }
            }
          } catch (e) {
            _logDiagnostic('[DIAGNOSTIC] profiles enrichment skipped: $e');
          }
        }
      } catch (e) {
        _logDiagnostic(
          '[DIAGNOSTIC] Author profile enrichment batch error: $e',
        );
      }

      // Anti-stale filtering against persistent deleted blacklist
      final deletedIds = LocalCacheService.instance.getDeletedStatusIds();
      final activeList = list.where((p) => !deletedIds.contains(p.id)).toList();

      _activeStatuses = activeList;
      storiesLoadedCount = activeList.length;
      debugPrint('DEBUG MAPPED STATUS POSTS COUNT: $storiesLoadedCount');
      _logDiagnostic(
        '[StatusService] [DIAGNOSTIC] Fetched $rowsFetched raw rows, $storiesLoadedCount active status posts successfully mapped (deleted blacklist filtered: ${deletedIds.length})',
      );

      MockData().updateStatusPosts(activeList);

      // Update disk cache
      try {
        await LocalCacheService.instance.cacheStatuses(
          activeList.map((p) => p.toMap()).toList(),
        );
      } catch (e) {
        debugPrint('[StatusService] Error caching active statuses to disk: $e');
      }
    } catch (e) {
      lastFetchError = e.toString();
      _logDiagnostic(
        '[DIAGNOSTIC] Error fetching active statuses from Supabase: $e',
      );
    } finally {
      isFetching = false;
      notifyListeners();
    }
  }

  Future<String?> _uploadFileIfNeeded(
    String? localPath,
    String bucket,
    String prefix,
  ) async {
    if (localPath == null || localPath.isEmpty) return null;
    if (localPath.startsWith('http')) return localPath; // Already uploaded

    try {
      final file = File(localPath);
      if (!file.existsSync()) {
        return localPath; // Fallback to string if not a real file
      }

      final fileSizeInBytes = await file.length();
      final fileSizeInMb = fileSizeInBytes / (1024 * 1024);
      debugPrint(
        'Attempting to upload file to bucket "$bucket". Size: ${fileSizeInMb.toStringAsFixed(2)} MB',
      );

      if (fileSizeInMb > 50) {
        debugPrint(
          'WARNING: File is larger than 50MB! This may exceed default Supabase Storage limits.',
        );
      }

      final extension = localPath.split('.').last.toLowerCase();
      File uploadFile = file;
      if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        uploadFile = await ImageCompressionService.compressImageFile(file);
      }
      final fileName =
          '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      await _supabase.storage.from(bucket).upload(fileName, uploadFile);
      return _supabase.storage.from(bucket).getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Failed to upload file to storage: $e');
      return localPath; // Return local path/fallback
    }
  }

  Future<void> createStatus(StatusPost post) async {
    try {
      // 1. Immediately prepend to local active list
      addStatusLocally(post);

      // 2. Upload media files if they are local paths
      String? photoUrl = await _uploadFileIfNeeded(
        post.feedPhotoUrl,
        'status_media',
        'status_photo',
      );
      String? videoUrl = await _uploadFileIfNeeded(
        post.videoUrl,
        'status_media',
        'status_video',
      );
      String? audioUrl = await _uploadFileIfNeeded(
        post.feedAudioUrl,
        'status_media',
        'status_audio',
      );

      final updatedPost = post.copyWith(
        feedPhotoUrl: photoUrl,
        videoUrl: videoUrl,
        feedAudioUrl: audioUrl,
      );
      addStatusLocally(updatedPost);

      // 3. Insert into the statuses table
      await _supabase.from('statuses').insert({
        'creator_id': updatedPost.creatorId,
        'clan_id': updatedPost.clanId,
        'text_content': updatedPost.content,
        'media_url': updatedPost.postType == PostType.photo
            ? updatedPost.feedPhotoUrl
            : (updatedPost.postType == PostType.video
                  ? updatedPost.videoUrl
                  : updatedPost.feedAudioUrl),
        'video_duration': updatedPost.videoDuration,
        'status_type': updatedPost.postType.name,
        'text_color': updatedPost.textColor,
        'likes': updatedPost.likes,
        'views': updatedPost.views.map((v) => v.toMap()).toList(),
      });

      // 4. Insert into the public.tharavadu_statuses table
      String? mediaUrl = updatedPost.content;
      if (updatedPost.postType == PostType.photo) {
        mediaUrl = updatedPost.feedPhotoUrl;
      } else if (updatedPost.postType == PostType.video) {
        mediaUrl = updatedPost.videoUrl;
      } else if (updatedPost.postType == PostType.audio) {
        mediaUrl = updatedPost.feedAudioUrl;
      }

      await _supabase.from('tharavadu_statuses').insert({
        'user_id': updatedPost.creatorId,
        'tharavadu_id': updatedPost.clanId,
        'media_url': mediaUrl,
      });
    } on PostgrestException catch (e) {
      debugPrint('=== SUPABASE INSERTION FAILED ===: $e');
      rethrow;
    } catch (e) {
      debugPrint('Unknown Error creating status: $e');
      rethrow;
    }
  }

  Future<void> toggleLike(
    String postId,
    String userId,
    List<String> currentLikes,
  ) async {
    try {
      final newLikes = List<String>.from(currentLikes);
      if (newLikes.contains(userId)) {
        newLikes.remove(userId);
      } else {
        newLikes.add(userId);
      }
      await _supabase
          .from('statuses')
          .update({'likes': newLikes})
          .eq('id', postId);
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  Future<void> recordView(String postId, ViewRecord record) async {
    try {
      final numericStatusId = int.tryParse(postId);
      if (numericStatusId != null) {
        await _supabase.from('status_views').insert({
          'status_id': numericStatusId,
          'viewer_id': record.viewerIdHash,
        });
      }

      final res = await _supabase
          .from('statuses')
          .select('views')
          .eq('id', postId)
          .maybeSingle();
      if (res == null) return;
      final List currentViews = res['views'] ?? [];

      if (currentViews.any((v) => v['viewerIdHash'] == record.viewerIdHash))
  { return; }

      currentViews.add({
        'viewerIdHash': record.viewerIdHash,
        'viewerClanId': record.viewerClanId,
        'viewerGender': record.viewerGender.name,
        'viewerAge': record.viewerAge,
        'viewerRegion': record.viewerRegion,
        'viewedAt': record.viewedAt.toIso8601String(),
      });

      await _supabase
          .from('statuses')
          .update({'views': currentViews})
          .eq('id', postId);
    } catch (e) {
      debugPrint('Error recording status view: $e');
    }
  }

  Future<void> deleteStatus(String statusId, {String? mediaUrl}) async {
    debugPrint('[StatusService] PURGE INITIATED for status: $statusId');

    // 1. Immediately evict from in-memory lists (0ms latency UI update)
    final existingPost = MockData().statusPosts
        .where((p) => p.id == statusId)
        .firstOrNull;
    final existingStory = MockData().tharavadStories
        .where((s) => s.id == statusId)
        .firstOrNull;

    _activeStatuses.removeWhere((s) => s.id == statusId);
    MockData().removeStatusPost(statusId);
    MockData().removeTharavadStory(statusId);
    notifyListeners();

    // 2. Persist to Deleted Blacklist & Purge Disk Cache immediately
    try {
      await LocalCacheService.instance.markStatusDeleted(statusId);
      await LocalCacheService.instance.purgeStatusFromCache(statusId);
    } catch (e) {
      debugPrint('[StatusService] Local disk cache purge error: $e');
    }

    // 3. Multi-layer Eviction for Cached Network Images & Local Media Files
    final urlsToEvict = <String>{};
    if (mediaUrl != null && mediaUrl.isNotEmpty) urlsToEvict.add(mediaUrl);
    if (existingPost?.feedPhotoUrl != null &&
        existingPost!.feedPhotoUrl!.isNotEmpty)
  { urlsToEvict.add(existingPost.feedPhotoUrl!); }
    if (existingStory?.mediaUrl != null && existingStory!.mediaUrl!.isNotEmpty)
  { urlsToEvict.add(existingStory.mediaUrl!); }

    for (final url in urlsToEvict) {
      if (url.startsWith('http')) {
        try {
          PaintingBinding.instance.imageCache.evict(NetworkImage(url));
          await CachedNetworkImage.evictFromCache(url);
          debugPrint('[StatusService] Evicted image from cache: $url');
        } catch (e) {
          debugPrint('[StatusService] ImageCache eviction error: $e');
        }
      } else if (File(url).existsSync()) {
        try {
          File(url).deleteSync();
          debugPrint('[StatusService] Unlinked local media file: $url');
        } catch (_) {}
      }
    }

    // 4. Remote Supabase Database & Storage Purge
    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(statusId);
    if (isUuid) {
      try {
        await _supabase.from('statuses').delete().eq('id', statusId);
      } catch (_) {}
      try {
        await _supabase.from('tharavad_stories').delete().eq('id', statusId);
      } catch (_) {}
      try {
        await _supabase.from('stories').delete().eq('id', statusId);
      } catch (_) {}
      try {
        await _supabase.from('user_stories').delete().eq('id', statusId);
      } catch (_) {}
      try {
        await _supabase.from('tharavadu_statuses').delete().eq('id', statusId);
      } catch (_) {}

      // Storage object cleanup
      for (final url in urlsToEvict) {
        if (url.startsWith('http')) {
          try {
            final uri = Uri.parse(url);
            final pathSegments = uri.pathSegments;
            final storiesIdx = pathSegments.indexOf('stories');
            if (storiesIdx != -1 && storiesIdx + 1 < pathSegments.length) {
              final path = pathSegments.sublist(storiesIdx + 1).join('/');
              await _supabase.storage.from('stories').remove([path]);
            }
            final statusMediaIdx = pathSegments.indexOf('status_media');
            if (statusMediaIdx != -1 &&
                statusMediaIdx + 1 < pathSegments.length) {
              final path = pathSegments.sublist(statusMediaIdx + 1).join('/');
              await _supabase.storage.from('status_media').remove([path]);
            }
          } catch (_) {}
        }
      }
    }
  }

  @override
  void dispose() {
    _statusChannel?.unsubscribe();
    super.dispose();
  }
}
