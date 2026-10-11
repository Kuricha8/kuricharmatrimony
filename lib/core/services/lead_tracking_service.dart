import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Realtime Lead Auto-Save & Abandonment Tracking Service.
///
/// Features:
/// 1. Auto-save on Input (Debounce):
///    - Debounced (1-second) upserts to `registration_leads` table.
///    - Initial status: 'typing'.
/// 2. Detect Drop-offs / Abandonment:
///    - Detects backgrounding / inactive app lifecycle states or screen exit.
///    - Updates status to 'abandoned' if registration is not completed.
/// 3. Successful Registration Completion:
///    - Cleanly marks status as 'completed' upon full registration submission.
/// 4. Performance & Safety:
///    - All network calls run non-blocking in the background.
///    - Network errors are gracefully caught and suppressed.
class LeadTrackingService {
  static final LeadTrackingService instance = LeadTrackingService._();
  LeadTrackingService._();

  static const String tableName = 'registration_leads';
  static const String statusTyping = 'typing';
  static const String statusAbandoned = 'abandoned';
  static const String statusCompleted = 'completed';

  /// High-concurrency debounce duration (1.5 seconds) to throttle database writes
  /// efficiently for up to 1,000 simultaneous users.
  static const Duration defaultDebounceDuration = Duration(milliseconds: 1500);

  Timer? _debounceTimer;
  String? _currentPhone;
  String? _currentName;
  int _currentStep = 1;
  String _currentStatus = statusTyping;
  bool _isCompleted = false;

  // Custom instance for testing / mocking
  FirebaseFirestore? _customFirestore;
  @visibleForTesting
  void setFirestoreForTesting(FirebaseFirestore? firestore) => _customFirestore = firestore;

  FirebaseFirestore get _firestore {
    return _customFirestore ?? FirebaseFirestore.instance;
  }

  // Getters for inspection & testing
  bool get isCompleted => _isCompleted;
  String? get currentPhone => _currentPhone;
  String? get currentName => _currentName;
  int get currentStep => _currentStep;
  String get currentStatus => _currentStatus;
  bool get hasActiveDebounce =>
      _debounceTimer != null && _debounceTimer!.isActive;

  /// Sanitizes phone numbers by stripping non-digit characters and normalizing.
  static String sanitizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10 && digits.startsWith('91')) {
      digits = digits.substring(digits.length - 10);
    }
    return digits;
  }

  /// Initialize tracking session for a registration flow.
  void init({String? phone, String? name, int step = 1}) {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _isCompleted = false;
    _currentStatus = statusTyping;
    _currentStep = step > 0 ? step : 1;
    if (phone != null && phone.trim().isNotEmpty) {
      _currentPhone = sanitizePhone(phone);
    }
    if (name != null) {
      _currentName = name.trim();
    }
  }

  /// Called when user inputs or updates key fields (Phone, Full Name).
  ///
  /// Uses a 1-second debounce listener. While typing, updates status to 'typing'.
  void trackLeadInput({
    required String phone,
    required String name,
    required int currentStep,
    Duration debounceDuration = defaultDebounceDuration,
  }) {
    if (_isCompleted) return;

    _currentStep = currentStep > 0 ? currentStep : 1;
    _currentName = name.trim();

    final cleanPhone = sanitizePhone(phone);
    if (cleanPhone.isNotEmpty) {
      _currentPhone = cleanPhone;
    }

    // Cancel existing debounce timer
    _debounceTimer?.cancel();

    // If phone number is not yet present, do not upsert to Supabase
    // since 'phone' is the primary identifier for lead tracking.
    if (_currentPhone == null || _currentPhone!.isEmpty) {
      return;
    }

    _currentStatus = statusTyping;

    // Start 1-second debounce timer
    _debounceTimer = Timer(debounceDuration, () {
      _upsertLead(status: statusTyping);
    });
  }

  /// Updates current step in registration flow and synchronizes to DB in background.
  Future<void> updateStep(int step) async {
    if (_isCompleted) return;
    _currentStep = step > 0 ? step : 1;

    if (_currentPhone != null && _currentPhone!.isNotEmpty) {
      await _upsertLead(status: _currentStatus);
    }
  }

  /// Handles AppLifecycleState transitions via WidgetsBindingObserver.
  ///
  /// If the user backgrounds, closes, or leaves the app without completing
  /// registration, the lead status is marked as 'abandoned'.
  Future<void> handleAppLifecycleState(AppLifecycleState state) async {
    if (_isCompleted) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _debounceTimer?.cancel();
        await markAbandoned();
        break;
      case AppLifecycleState.resumed:
        // User resumed app. Next input will switch status back to 'typing'.
        break;
    }
  }

  /// Called when user navigates away from registration screen before completion.
  Future<void> handleScreenExit() async {
    if (_isCompleted) return;
    _debounceTimer?.cancel();
    await markAbandoned();
  }

  /// Marks the current lead as 'abandoned' in background.
  Future<void> markAbandoned() async {
    if (_isCompleted) return;
    _debounceTimer?.cancel();

    if (_currentPhone == null || _currentPhone!.isEmpty) return;

    _currentStatus = statusAbandoned;
    await _upsertLead(status: statusAbandoned);
  }

  /// Marks the lead as 'completed' upon successful profile submission.
  Future<void> markCompleted({String? phone, String? name, int? step}) async {
    _isCompleted = true;
    _debounceTimer?.cancel();
    _currentStatus = statusCompleted;

    if (phone != null && phone.trim().isNotEmpty) {
      final clean = sanitizePhone(phone);
      if (clean.isNotEmpty) _currentPhone = clean;
    }
    if (name != null && name.trim().isNotEmpty) {
      _currentName = name.trim();
    }
    if (step != null && step > 0) {
      _currentStep = step;
    }

    if (_currentPhone == null || _currentPhone!.isEmpty) return;

    await _upsertLead(status: statusCompleted);
  }

  /// Background upsert with error suppression to ensure zero UI freezes or interruptions.
  Future<void> _upsertLead({required String status}) async {
    final targetPhone = _currentPhone;
    if (targetPhone == null || targetPhone.isEmpty) return;

    try {
      final payload = {
        'phone': targetPhone,
        'name': (_currentName != null && _currentName!.isNotEmpty)
            ? _currentName
            : 'Anonymous',
        'current_step': _currentStep,
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      };

      debugPrint('LeadTrackingService: Upserting lead ($status) -> $payload');
      await _firestore.collection(tableName).doc(targetPhone).set(payload, SetOptions(merge: true));
      debugPrint(
        'LeadTrackingService: Upsert complete for $targetPhone [status: $status]',
      );
    } catch (e) {
      // Gracefully suppress network errors so user registration flow remains seamless
      debugPrint('LeadTrackingService (suppressed): Failed to upsert lead: $e');
    }
  }

  /// Resets state (e.g., when logging out or clearing registration state).
  void reset() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _currentPhone = null;
    _currentName = null;
    _currentStep = 1;
    _currentStatus = statusTyping;
    _isCompleted = false;
  }

  /// High-concurrency streamlined realtime stream for the admin app.
  ///
  /// Streams `registration_leads` limited to the latest entries (default: 50)
  /// ordered by `updated_at` descending, optimizing bandwidth and memory.
  Stream<List<Map<String, dynamic>>> getAdminLeadsStream({int limit = 20}) {
    return _firestore
        .collection(tableName)
        .orderBy('updated_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
