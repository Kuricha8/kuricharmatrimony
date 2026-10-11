import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coin_ad_slot_model.dart';

class CoinAdSlotService extends ChangeNotifier {
  static final CoinAdSlotService instance = CoinAdSlotService._();
  CoinAdSlotService._();

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _slotsChannel;

  CoinAdSlot? activeFrontSlot;
  CoinAdSlot? activeBackSlot;
  CoinAdSlot? waitingFrontSlot;
  CoinAdSlot? waitingBackSlot;

  List<CoinAdSlot> allSlotsHistory = [];
  bool isLoading = false;

  void init() {
    fetchActiveSlots();
    _subscribeToSlotChanges();
  }

  /// Check if the active slot is free for a given position ('front' | 'back')
  bool isPositionActiveFree(String position) {
    final pos = position.toLowerCase();
    if (pos == 'front') {
      return activeFrontSlot == null || activeFrontSlot!.isExpired;
    } else {
      return activeBackSlot == null || activeBackSlot!.isExpired;
    }
  }

  /// Check if the waiting queue slot is free for a given position
  bool isPositionWaitingFree(String position) {
    final pos = position.toLowerCase();
    if (pos == 'front') {
      return waitingFrontSlot == null;
    } else {
      return waitingBackSlot == null;
    }
  }

  /// Check if a position is completely full (Active busy + Waiting busy)
  bool isPositionFullyBooked(String position) {
    return !isPositionActiveFree(position) && !isPositionWaitingFree(position);
  }

  /// Check if both front & back are completely booked (all 4 slots occupied)
  bool get isAllFullyBooked =>
      isPositionFullyBooked('front') && isPositionFullyBooked('back');

  /// Fetches slots, performs auto-promotion of expired slots, and syncs state
  Future<void> fetchActiveSlots() async {
    isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final nowIso = now.toIso8601String();

      // 1. Auto-promotion logic: Check for expired active slots and promote waiting entries
      await _runAutoPromotion(nowIso);

      // 2. Fetch all recent coin ad slots
      final res = await _supabase
          .from('coin_ad_slots')
          .select('*')
          .order('created_at', ascending: false);

      final rows = res as List<dynamic>;
      final List<CoinAdSlot> allSlots = [];

      CoinAdSlot? frontActive;
      CoinAdSlot? backActive;
      CoinAdSlot? frontWaiting;
      CoinAdSlot? backWaiting;

      for (var row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final slot = CoinAdSlot.fromMap(row);
        final pos = slot.slotPosition.toLowerCase().trim();
        final statusLower = slot.status.toLowerCase().trim();
        final isActiveStatus =
            statusLower == 'active' || row['is_active'] == true;

        if (isActiveStatus && !slot.isExpired) {
          if (pos == 'front') {
            frontActive ??= slot;
          } else if (pos == 'back') {
            backActive ??= slot;
          } else {
            // Default to front if position isn't explicitly 'back'
            frontActive ??= slot;
          }
        } else if (statusLower == 'waiting' || statusLower == 'pending') {
          if (pos == 'front' && frontWaiting == null) {
            frontWaiting = slot;
          } else if (pos == 'back' && backWaiting == null) {
            backWaiting = slot;
          }
        }
      }

      // If back active is free but front is set and there's a 2nd active ad, assign to back
      if (backActive == null && allSlots.isNotEmpty) {
        for (var slot in allSlots) {
          if (slot.id != frontActive?.id && slot.isActive) {
            backActive = slot;
            break;
          }
        }
      }

      activeFrontSlot = frontActive;
      activeBackSlot = backActive;
      waitingFrontSlot = frontWaiting;
      waitingBackSlot = backWaiting;
      allSlotsHistory = allSlots.take(20).toList();

      debugPrint(
        '[CoinAdSlotService] Active Front: ${activeFrontSlot?.imageUrl}, Back: ${activeBackSlot?.imageUrl}',
      );
    } catch (e) {
      debugPrint('[CoinAdSlotService] Error fetching coin ad slots: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Automatically marks expired active slots and promotes waiting queue
  Future<void> _runAutoPromotion(String nowIso) async {
    try {
      // Find active slots that expired
      final expiredActive = await _supabase
          .from('coin_ad_slots')
          .select('id, slot_position')
          .eq('status', 'active')
          .lte('expires_at', nowIso);

      for (var slot in (expiredActive as List)) {
        final slotId = slot['id'].toString();
        final pos = (slot['slot_position'] ?? 'front')
            .toString()
            .toLowerCase()
            .trim();

        // Mark active as expired
        await _supabase
            .from('coin_ad_slots')
            .update({'status': 'expired'})
            .eq('id', slotId);

        // Check if there is a waiting slot for this position
        final waitingQueue = await _supabase
            .from('coin_ad_slots')
            .select('*')
            .inFilter('status', ['waiting', 'pending'])
            .eq('slot_position', pos)
            .order('created_at', ascending: true)
            .limit(1);

        if (waitingQueue.isNotEmpty) {
          final waitingId = waitingQueue.first['id'].toString();
          final promoStart = DateTime.now();
          final promoExpires = promoStart.add(const Duration(days: 7));

          await _supabase
              .from('coin_ad_slots')
              .update({
                'status': 'active',
                'starts_at': promoStart.toIso8601String(),
                'expires_at': promoExpires.toIso8601String(),
              })
              .eq('id', waitingId);

          debugPrint(
            '[CoinAdSlotService] Promoted waiting slot $waitingId to ACTIVE for $pos face',
          );
        }
      }
    } catch (e) {
      debugPrint('[CoinAdSlotService] Auto-promotion check note: $e');
    }
  }

  void _subscribeToSlotChanges() {
    _slotsChannel?.unsubscribe();
    _slotsChannel = _supabase
        .channel('public:coin_ad_slots')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'coin_ad_slots',
          callback: (_) {
            fetchActiveSlots();
          },
        )
        .subscribe();
  }

  Future<String> uploadSlotImage(File file, String userId) async {
    final ext = file.path.split('.').last.toLowerCase();
    final fileName =
        'coin_${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storagePath = 'coin_slots/$fileName';

    await _supabase.storage.from('app_assets').upload(storagePath, file);
    return _supabase.storage.from('app_assets').getPublicUrl(storagePath);
  }

  /// Books slot as ACTIVE (if free) or WAITING queue (if active busy and queue free)
  Future<({CoinAdSlot slot, bool isQueued})> activateOrQueueCoinSlot({
    required String slotPosition,
    required String userId,
    required String imageUrl,
    required double amountPaid,
    required String paymentId,
    int durationDays = 7,
  }) async {
    final pos = slotPosition.toLowerCase();
    final activeFree = isPositionActiveFree(pos);
    final waitingFree = isPositionWaitingFree(pos);

    if (!activeFree && !waitingFree) {
      throw Exception('ഈ സ്ലോട്ടുകൾ പൂർണ്ണമായി ബുക്ക് ചെയ്തിരിക്കുന്നു.');
    }

    final now = DateTime.now();
    DateTime startsAt = now;
    DateTime expiresAt = now.add(Duration(days: durationDays));
    String status = 'active';

    if (!activeFree) {
      // Active slot is occupied -> Book into waiting/pending queue
      final currentActive = (pos == 'front') ? activeFrontSlot : activeBackSlot;
      startsAt = currentActive?.expiresAt ?? now;
      expiresAt = startsAt.add(Duration(days: durationDays));
      status = 'pending';
    }

    final row = {
      'slot_position': pos,
      'user_id': userId,
      'image_url': imageUrl,
      'amount_paid': amountPaid,
      'duration_days': durationDays,
      'starts_at': startsAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'status': status.toLowerCase().trim(),
      'payment_id': paymentId,
      'created_at': now.toIso8601String(),
    };

    final res = await _supabase
        .from('coin_ad_slots')
        .insert(row)
        .select()
        .single();
    final newSlot = CoinAdSlot.fromMap(res);

    await fetchActiveSlots();
    return (
      slot: newSlot,
      isQueued: status == 'pending' || status == 'waiting',
    );
  }

  // Backwards compatibility alias
  Future<CoinAdSlot> activateCoinSlot({
    required String slotPosition,
    required String userId,
    required String imageUrl,
    required double amountPaid,
    required String paymentId,
    int durationDays = 7,
  }) async {
    final res = await activateOrQueueCoinSlot(
      slotPosition: slotPosition,
      userId: userId,
      imageUrl: imageUrl,
      amountPaid: amountPaid,
      paymentId: paymentId,
      durationDays: durationDays,
    );
    return res.slot;
  }

  Future<void> adminOverrideSlot(String slotId, String newStatus) async {
    try {
      await _supabase
          .from('coin_ad_slots')
          .update({'status': newStatus.toLowerCase().trim()})
          .eq('id', slotId);

      await fetchActiveSlots();
    } catch (e) {
      debugPrint('Error overriding coin slot: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _slotsChannel?.unsubscribe();
    super.dispose();
  }
}
