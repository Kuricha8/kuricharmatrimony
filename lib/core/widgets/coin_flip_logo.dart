import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/coin_ad_slot_service.dart';
import 'promote_coin_slot_sheet.dart';

class CoinFlipLogoWidget extends StatefulWidget {
  final double size;

  const CoinFlipLogoWidget({super.key, this.size = 40.0});

  @override
  State<CoinFlipLogoWidget> createState() => _CoinFlipLogoWidgetState();
}

class _CoinFlipLogoWidgetState extends State<CoinFlipLogoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  String? _adminFrontUrl;
  String? _adminBackUrl;

  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();

    // Setup continuous rotation animation (1 full spin every 4 seconds)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _animation = Tween<double>(begin: 0, end: 2 * pi).animate(_controller);
    _controller.repeat();

    _fetchLogos();
    _subscribeToChanges();
    CoinAdSlotService.instance.init();
  }

  Future<void> _fetchLogos() async {
    try {
      final res = await Supabase.instance.client
          .from('admin_app_settings')
          .select('key, value');
      _updateUrlsFromData(res);
    } catch (e) {
      debugPrint('Error fetching coin logos: $e');
    }

    try {
      await CoinAdSlotService.instance.fetchActiveSlots();
    } catch (e) {
      debugPrint('Error fetching active coin slots in widget: $e');
    }
  }

  void _updateUrlsFromData(List<dynamic> rows) {
    if (!mounted) return;
    String? newFront;
    String? newBack;

    for (var row in rows) {
      if (row['key'] == 'coin_logo_front') newFront = row['value'];
      if (row['key'] == 'coin_logo_back') newBack = row['value'];
    }

    setState(() {
      if (newFront != null) _adminFrontUrl = newFront;
      if (newBack != null) _adminBackUrl = newBack;
    });
  }

  void _subscribeToChanges() {
    _subscription = Supabase.instance.client
        .channel('public:admin_app_settings')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'admin_app_settings',
          callback: (payload) {
            final key = payload.newRecord['key'] ?? payload.oldRecord['key'];
            final value = payload.newRecord['value'];

            if (key == 'coin_logo_front' || key == 'coin_logo_back') {
              if (mounted) {
                setState(() {
                  if (key == 'coin_logo_front') _adminFrontUrl = value;
                  if (key == 'coin_logo_back') _adminBackUrl = value;
                });
              }
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _controller.dispose();
    _subscription?.unsubscribe();
    super.dispose();
  }

  Widget _buildFace(String? url, bool isFront) {
    if (url == null || url.trim().isEmpty) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFront ? Colors.amber.shade700 : Colors.indigo.shade700,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            isFront ? Icons.monetization_on : Icons.stars,
            color: Colors.white,
            size: widget.size * 0.5,
          ),
        ),
      );
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          url,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: isFront ? Colors.amber.shade700 : Colors.indigo.shade700,
              child: Center(
                child: Icon(
                  isFront ? Icons.monetization_on : Icons.stars,
                  color: Colors.white,
                  size: widget.size * 0.5,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openPromotionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PromoteCoinSlotSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CoinAdSlotService.instance,
      builder: (context, _) {
        final activeFront = CoinAdSlotService.instance.activeFrontSlot;
        final activeBack = CoinAdSlotService.instance.activeBackSlot;

        // Effective URLs: Active paid slot takes priority over admin default assets
        final effectiveFrontUrl =
            (activeFront != null && !activeFront.isExpired)
            ? activeFront.imageUrl
            : _adminFrontUrl;

        final effectiveBackUrl = (activeBack != null && !activeBack.isExpired)
            ? activeBack.imageUrl
            : _adminBackUrl;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openPromotionSheet,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final angle = _animation.value;
              final isBackVisible = angle > (pi / 2) && angle < (3 * pi / 2);

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateY(angle),
                child: isBackVisible
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: _buildFace(effectiveBackUrl, false),
                      )
                    : _buildFace(effectiveFrontUrl, true),
              );
            },
          ),
        );
      },
    );
  }
}
