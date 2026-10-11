import 'dart:async';
import 'dart:math';

enum PlatformStatus { pending, loading, success, failed }

class SocialMediaService {
  /// Simulates calling a Supabase Edge Function to post to social media.
  static Future<Map<String, PlatformStatus>> queuePost({
    required String imageUrl,
    required String caption,
    required List<String> platforms,
    Function(String platform, PlatformStatus status)? onProgress,
  }) async {
    final results = <String, PlatformStatus>{};
    for (final p in platforms) {
      results[p] = PlatformStatus.loading;
      onProgress?.call(p, PlatformStatus.loading);
    }

    // In a real scenario, this would be:
    // await Supabase.instance.client.functions.invoke('post_to_socials', body: {...});

    final random = Random();

    for (final p in platforms) {
      // Simulate network delay per platform
      await Future.delayed(Duration(seconds: 1 + random.nextInt(2)));

      // Simulate 80% success rate
      final isSuccess = random.nextDouble() > 0.2;
      results[p] = isSuccess ? PlatformStatus.success : PlatformStatus.failed;
      onProgress?.call(p, results[p]!);
    }

    return results;
  }
}
