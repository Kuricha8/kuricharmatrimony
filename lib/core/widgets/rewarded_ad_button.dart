import 'package:flutter/material.dart';
import '../services/rewarded_ad_service.dart';
import '../services/ad_status_service.dart';

class RewardedAdButton extends StatefulWidget {
  final VoidCallback onRewardEarned;
  final String buttonText;

  const RewardedAdButton({
    super.key,
    required this.onRewardEarned,
    this.buttonText = 'Watch Ad to Unlock',
  });

  @override
  State<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends State<RewardedAdButton> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Preload the ad when the button is first rendered
    RewardedAdService.instance.loadAd();
  }

  void _handleTap() {
    setState(() => _isLoading = true);

    RewardedAdService.instance.showAdIfAvailable(
      onRewardEarned: () {
        if (mounted) setState(() => _isLoading = false);
        widget.onRewardEarned();
      },
      onAdFailed: () {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ad is not available yet. Please try again in a moment.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ad-Free Experience for Premium Users: Hide the widget completely.
    if (AdStatusService.instance.isPremiumUser) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleTap,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.play_circle_outline, size: 20),
      label: Text(
        _isLoading ? 'Loading Ad...' : widget.buttonText,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
