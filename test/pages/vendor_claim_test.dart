// Claiming an existing listing happens only on the website now (the server
// checks the emailed code there). The app's start page offers creating a new
// listing and points vendors who are already listed to the website.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:say_yes/pages/vendor_claim.dart';

Future<void> _initSupabase() async {
  SharedPreferences.setMockInitialValues({});
  try {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test_anon_key_for_unit_tests',
    );
  } catch (_) {
    // Already initialized when running alongside other test files.
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    await _initSupabase();
  });

  testWidgets('no claiming in the app: no business search or Claim buttons', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VendorClaimPage(userId: 'u1')));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Claim'), findsNothing);
    expect(find.text('Search for your business'), findsNothing);
  });

  testWidgets('already listed vendors are sent to the website to claim', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VendorClaimPage(userId: 'u1')));
    await tester.pump();
    expect(find.textContaining('already listed', findRichText: true), findsWidgets);
    expect(find.text('Claim on easiyest.com'), findsOneWidget);
    expect(kClaimListingUrl, 'https://www.easiyest.com/vendor.html');
  });

  testWidgets('new vendors can still create a listing in the app', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VendorClaimPage(userId: 'u1')));
    await tester.pump();
    expect(find.text('Create New Vendor Profile'), findsOneWidget);
  });
}
