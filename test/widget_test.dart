// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter_test/flutter_test.dart';
import 'package:kurichiyar_matrimony/main.dart';
import 'package:kurichiyar_matrimony/core/widgets/logo_widget.dart';
import 'package:kurichiyar_matrimony/core/utils/mock_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  testWidgets('App rendering smoke test', (WidgetTester tester) async {
    await dotenv.load(fileName: ".env");
    // Initialize Supabase mock client without auto session refresh to prevent pending Timer leaks in tests
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? 'https://noidreeslytswkmsnmcn.supabase.co',
      publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vaWRyZWVzbHl0c3drbXNubWNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5NTA2ODksImV4cCI6MjA5OTUyNjY4OX0.VnpX0xjRNi89efECRAzMiu79trSQlblpRjfWZLkjMo4',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );

    KurichiyarMatrimonyApp.isTesting = true;
    MockData().logout();
    // Mock the Terms and Conditions agreement state
    SharedPreferences.setMockInitialValues({'hasAgreedTerms': true});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const KurichiyarMatrimonyApp());
    
    // Pump multiple frames to let SharedPreferences, MethodChannels, and async permission checks resolve
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Verify that the Guest Screen or dashboard elements are rendered initially
    expect(find.byType(LogoWidget), findsOneWidget);

    // Tap on the Moiety Checker tab in the bottom navigation bar
    await tester.tap(find.text('Moiety Checker'));
    await tester.pumpAndSettle();

    expect(find.text('Moiety Compatibility Checker'), findsAtLeast(1));
  });
}
