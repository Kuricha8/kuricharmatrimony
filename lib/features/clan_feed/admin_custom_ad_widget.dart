import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class AdminCustomAdWidget extends StatefulWidget {
  const AdminCustomAdWidget({super.key});

  @override
  State<AdminCustomAdWidget> createState() => _AdminCustomAdWidgetState();
}

class _AdminCustomAdWidgetState extends State<AdminCustomAdWidget> {
  VideoPlayerController? _controller;
  Map<String, dynamic>? _adData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRandomAd();
  }

  Future<void> _fetchRandomAd() async {
    try {
      final response = await Supabase.instance.client
          .from('admin_custom_ads')
          .select()
          .eq('is_active', true);

      if (response.isNotEmpty) {
        final ads = response as List<dynamic>;
        final randomAd = ads[Random().nextInt(ads.length)];

        if (mounted) {
          setState(() {
            _adData = randomAd;
          });
          _initializeVideoPlayer(
            randomAd['image_url'] ?? randomAd['video_url'],
          );
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching custom ad: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeVideoPlayer(String url) async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _controller!.initialize();
      _controller!.setVolume(0); // Play silently
      _controller!.setLooping(true);
      _controller!.play();
    } catch (e) {
      debugPrint('Error initializing video ad: $e');
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_adData != null && _adData!['redirect_url'] != null) {
      final url = Uri.parse(_adData!['redirect_url']);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_adData == null ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return const SizedBox.shrink(); // Hide if no ad or failed to load
    }

    return GestureDetector(
      onTap: _handleTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.amber.shade100,
              child: const Row(
                children: [
                  Icon(Icons.campaign, size: 16, color: Colors.amber),
                  SizedBox(width: 6),
                  Text(
                    'Sponsored',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_controller!),
                  VideoProgressIndicator(_controller!, allowScrubbing: false),
                ],
              ),
            ),
            if (_adData!['redirect_url'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.blue.shade50,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Learn More',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 16, color: Colors.blue),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
