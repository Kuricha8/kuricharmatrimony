import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

class AutoRotatingVideoAdsWidget extends StatefulWidget {
  const AutoRotatingVideoAdsWidget({super.key});

  @override
  State<AutoRotatingVideoAdsWidget> createState() =>
      _AutoRotatingVideoAdsWidgetState();
}

class _AutoRotatingVideoAdsWidgetState
    extends State<AutoRotatingVideoAdsWidget> {
  VideoPlayerController? _controller;
  List<Map<String, dynamic>> _ads = [];
  int _currentAdIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAds();
  }

  Future<void> _fetchAds() async {
    try {
      final response = await Supabase.instance.client
          .from('admin_custom_ads')
          .select()
          .eq('is_active', true);

      if (response.isNotEmpty) {
        final List<Map<String, dynamic>> adsList =
            List<Map<String, dynamic>>.from(response);
        // Shuffle to start with random ads
        adsList.shuffle();

        if (mounted) {
          setState(() {
            _ads = adsList;
          });
          _playAdAtIndex(0);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching rotating ads: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _videoListener() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    // When video reaches the end
    if (_controller!.value.position >= _controller!.value.duration) {
      _controller!.removeListener(_videoListener);
      _playNextAd();
    }
  }

  Future<void> _playNextAd() async {
    if (_ads.isEmpty) return;

    _currentAdIndex = (_currentAdIndex + 1) % _ads.length;
    await _playAdAtIndex(_currentAdIndex);
  }

  Future<void> _playAdAtIndex(int index) async {
    if (_ads.isEmpty || index >= _ads.length) return;

    final ad = _ads[index];
    final String url = ad['video_url'] ?? ad['image_url'] ?? '';

    if (url.isEmpty) {
      // Skip empty URLs
      _playNextAd();
      return;
    }

    final oldController = _controller;

    final newController = VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      await newController.initialize();
      newController.setVolume(0); // Play silently
      newController.setLooping(false); // We handle looping by switching ads
      newController.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _controller = newController;
          _isLoading = false;
        });
        await newController.play();

        // Dispose old controller after new one is ready to prevent flickering
        oldController?.removeListener(_videoListener);
        oldController?.dispose();
      } else {
        newController.dispose();
      }
    } catch (e) {
      debugPrint('Error initializing rotating video ad: $e');
      // If one ad fails to play, skip to next after a short delay
      if (mounted) {
        Future.delayed(const Duration(seconds: 2), _playNextAd);
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_ads.isEmpty) return;
    final currentAd = _ads[_currentAdIndex];
    if (currentAd['redirect_url'] != null) {
      final url = Uri.parse(currentAd['redirect_url']);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_ads.isEmpty ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return const SizedBox.shrink(); // Hide if no ad or failed to load
    }

    final currentAd = _ads[_currentAdIndex];

    return GestureDetector(
      onTap: _handleTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio > 0
                  ? _controller!.value.aspectRatio
                  : 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VideoPlayer(_controller!),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Sponsored',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (currentAd['title'] != null)
              Container(
                color: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentAd['title'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
