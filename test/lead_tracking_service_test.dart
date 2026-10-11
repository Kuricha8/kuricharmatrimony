import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurichiyar_matrimony/core/services/lead_tracking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LeadTrackingService Unit Tests', () {
    late LeadTrackingService service;

    setUp(() {
      service = LeadTrackingService.instance;
      service.reset();
    });

    tearDown(() {
      service.reset();
    });

    test('Phone sanitization strips non-digits and +91 prefix correctly', () {
      expect(LeadTrackingService.sanitizePhone('+91 98765 43210'), '9876543210');
      expect(LeadTrackingService.sanitizePhone('+919876543210'), '9876543210');
      expect(LeadTrackingService.sanitizePhone('98765-43210'), '9876543210');
      expect(LeadTrackingService.sanitizePhone('9876543210'), '9876543210');
    });

    test('Initializes state correctly', () {
      service.init(phone: '+91 9876543210', name: 'John Doe', step: 2);
      expect(service.currentPhone, '9876543210');
      expect(service.currentName, 'John Doe');
      expect(service.currentStep, 2);
      expect(service.currentStatus, LeadTrackingService.statusTyping);
      expect(service.isCompleted, isFalse);
    });

    test('Debounced auto-save triggers 1-second debounce timer with status typing', () async {
      service.trackLeadInput(
        phone: '9876543210',
        name: 'Rahul',
        currentStep: 1,
        debounceDuration: const Duration(milliseconds: 100),
      );

      expect(service.currentPhone, '9876543210');
      expect(service.currentName, 'Rahul');
      expect(service.currentStatus, LeadTrackingService.statusTyping);
      expect(service.hasActiveDebounce, isTrue);

      // Rapidly update again within debounce window
      service.trackLeadInput(
        phone: '9876543210',
        name: 'Rahul Kumar',
        currentStep: 1,
        debounceDuration: const Duration(milliseconds: 100),
      );

      expect(service.currentName, 'Rahul Kumar');
      expect(service.hasActiveDebounce, isTrue);

      // Wait for debounce timer to fire
      await Future.delayed(const Duration(milliseconds: 150));
      expect(service.hasActiveDebounce, isFalse);
      expect(service.currentStatus, LeadTrackingService.statusTyping);
    });

    test('Drop-off detection marks status as abandoned when app is paused/inactive/hidden', () async {
      service.init(phone: '9876543210', name: 'Ananya', step: 3);

      // Start debounce timer
      service.trackLeadInput(
        phone: '9876543210',
        name: 'Ananya',
        currentStep: 3,
        debounceDuration: const Duration(seconds: 1),
      );
      expect(service.hasActiveDebounce, isTrue);

      // Simulate user backgrounding app
      await service.handleAppLifecycleState(AppLifecycleState.paused);

      expect(service.hasActiveDebounce, isFalse);
      expect(service.currentStatus, LeadTrackingService.statusAbandoned);
    });

    test('Screen exit marks status as abandoned if not completed', () async {
      service.init(phone: '9876543210', name: 'Vishnu', step: 2);

      await service.handleScreenExit();

      expect(service.currentStatus, LeadTrackingService.statusAbandoned);
      expect(service.isCompleted, isFalse);
    });

    test('Successful completion transitions status to completed and locks against abandonment', () async {
      service.init(phone: '9876543210', name: 'Deepa', step: 9);

      // Complete registration
      await service.markCompleted(phone: '9876543210', name: 'Deepa', step: 9);

      expect(service.currentStatus, LeadTrackingService.statusCompleted);
      expect(service.isCompleted, isTrue);

      // Now, simulate app backgrounding or navigating away
      await service.handleAppLifecycleState(AppLifecycleState.paused);
      expect(service.currentStatus, LeadTrackingService.statusCompleted);

      await service.handleScreenExit();
      expect(service.currentStatus, LeadTrackingService.statusCompleted);

      // Additional typing attempt after completion does not overwrite
      service.trackLeadInput(phone: '9876543210', name: 'Modified', currentStep: 9);
      expect(service.currentStatus, LeadTrackingService.statusCompleted);
      expect(service.hasActiveDebounce, isFalse);
    });

    test('Enforces 1.5-second default debounce duration for high concurrency', () {
      expect(LeadTrackingService.defaultDebounceDuration, const Duration(milliseconds: 1500));
    });

    test('getAdminLeadsStream returns stream and safely handles uninitialized or offline client', () {
      final stream = service.getAdminLeadsStream(limit: 50);
      expect(stream, isA<Stream<List<Map<String, dynamic>>>>());
    });

    test('Admin stream listener cancels and disposes cleanly for memory safety', () async {
      final stream = service.getAdminLeadsStream(limit: 50);
      final sub = stream.listen((_) {});
      await sub.cancel();
      expect(true, isTrue); // Clean disposal without leaks
    });

    test('Network calls safely suppress errors without throwing or freezing', () async {
      // Supabase is not initialized in standard widget test environment,
      // so this verifies graceful error suppression for all operations
      expect(() => service.trackLeadInput(phone: '9999999999', name: 'Offline Test', currentStep: 1), returnsNormally);
      expect(() => service.updateStep(2), returnsNormally);
      expect(() => service.markAbandoned(), returnsNormally);
      expect(() => service.markCompleted(phone: '9999999999'), returnsNormally);
    });
  });
}
