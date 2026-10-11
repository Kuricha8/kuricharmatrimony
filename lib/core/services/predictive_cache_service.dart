import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/mock_data.dart';
import 'status_service.dart';
import '../../features/clan_feed/tharavadu_list.dart';

/// Sub-Zero Latency Predictive Cache Engine
/// Pre-warms assets, executes touch/hover predictive caching, and accelerates screen transitions.
class PredictiveCacheService {
  PredictiveCacheService._();
  static final PredictiveCacheService instance = PredictiveCacheService._();

  final Set<String> _precachedUrls = {};
  bool _isPrewarming = false;

  /// Triggered on onTapDown / hover: immediately loads asset into image cache before navigation
  void prewarmUrl(BuildContext? context, String? url) {
    if (url == null || url.trim().isEmpty || _precachedUrls.contains(url))
  { return; }
    final trimmed = url.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) return;

    _precachedUrls.add(trimmed);
    try {
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        final image = NetworkImage(trimmed);
        if (context != null) {
          precacheImage(image, context).catchError((_) {});
        } else {
          image
              .resolve(const ImageConfiguration())
              .addListener(
                ImageStreamListener(
                  (image, synchronousCall) {},
                  onError: (exception, stackTrace) {},
                ),
              );
        }
      } else if (trimmed.startsWith('assets/')) {
        final image = AssetImage(trimmed);
        if (context != null) {
          precacheImage(image, context).catchError((_) {});
        }
      } else if (File(trimmed.replaceFirst('file://', '')).existsSync()) {
        final image = FileImage(File(trimmed.replaceFirst('file://', '')));
        if (context != null) {
          precacheImage(image, context).catchError((_) {});
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('PredictiveCacheService error on $url: $e');
    }
  }

  /// Batch precaches URLs with a concurrency limiter
  Future<void> prewarmBatch(
    BuildContext? context,
    List<String> urls, {
    int limit = 10,
  }) async {
    final toWarm = urls.take(limit).toList();
    for (final url in toWarm) {
      prewarmUrl(context, url);
    }
  }

  /// Silently pre-warms top status media assets in memory
  Future<void> prewarmTopStatuses(BuildContext context) async {
    try {
      final posts = MockData().statusPosts;
      final urls = <String>[];
      for (final post in posts.take(10)) {
        if (post.feedPhotoUrl != null && post.feedPhotoUrl!.isNotEmpty) {
          urls.add(post.feedPhotoUrl!);
        }
      }
      for (final clan in allClans.take(10)) {
        if (clan.imageUrl != null && clan.imageUrl!.isNotEmpty) {
          urls.add(clan.imageUrl!);
        }
      }
      await prewarmBatch(context, urls, limit: 15);
    } catch (_) {}
  }

  /// Silently pre-warms top match profile photos
  Future<void> prewarmTopMatches(BuildContext context) async {
    try {
      final profiles = MockData().profiles;
      final urls = <String>[];
      for (final p in profiles.take(8)) {
        if (p.photoUrl.isNotEmpty && p.photoUrl.startsWith('http')) {
          urls.add(p.photoUrl);
        }
      }
      await prewarmBatch(context, urls, limit: 8);
    } catch (_) {}
  }

  /// Full background pre-warming orchestrated on app startup
  void prewarmApp(BuildContext context) {
    if (_isPrewarming) return;
    _isPrewarming = true;

    Future.microtask(() async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!context.mounted) return;

      // 1. Prewarm Status tray assets
      await prewarmTopStatuses(context);

      // 2. Prewarm Matches summary & avatars
      if (context.mounted) {
        await prewarmTopMatches(context);
      }

      // 3. Ensure StatusService data is up to date
      StatusService.instance.fetchStatuses();

      _isPrewarming = false;
    });
  }
}
