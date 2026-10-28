import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:say_yes/appstate.dart';
import 'package:say_yes/pages/individual_card.dart';
import 'package:say_yes/widgets/vendor_page_parts.dart';

Future<void> _initSupabase() async {
  SharedPreferences.setMockInitialValues({});
  try {
    await Supabase.initialize(url: 'https://test.supabase.co', anonKey: 'test_anon_key_for_unit_tests');
  } catch (_) {}
}

void fillVenueSetup(AppState s, {bool yes = false}) {
  s.categoryFilters = {
    'Venue': [
      {'filter_key': 'venue_type', 'filter_label': 'Venue Type', 'filter_type': 'chips'},
      {'filter_key': 'venue_amenities', 'filter_label': 'Amenities', 'filter_type': 'chips'},
      {'filter_key': 'guest_capacity_range', 'filter_label': 'Guest Capacity', 'filter_type': 'range'},
    ],
  };
  s.filterOptions = {
    'venue_type': [
      {'option_value': 'barn', 'option_label': 'Barns, Farms & Ranches'},
    ],
    'venue_amenities': [
      {'option_value': 'dance', 'option_label': 'Dance Floor', 'option_group': 'Facilities', 'icon_name': 'nightlife'},
    ],
  };
  if (yes) s.diamondedCards = {'Venue': 'v1'};
  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
  s.notifyListeners();
}

IndividualCard barn({int? capMin = 50, int? capMax = 300}) => IndividualCard(
      category: 'Venue',
      vendor_id: 'v1',
      title: 'The Barn at Wall Brothers Orchards',
      description: 'A timber orchard barn.',
      imageUrl: const [],
      style_keywords: 'Rustic, Elegant',
      location: 'Santaquin',
      address: '918 UT-198',
      vendor_estimated_price: '',
      vendor_price: r'$3,200',
      contact_email: '',
      contact_phone: '',
      website_url: 'https://thebarneventvenue.com/',
      social_media_links: const [],
      isHearted: false,
      isDiamonded: false,
      filterValues: const {'venue_type': ['barn'], 'venue_amenities': ['dance']},
      capacityMin: capMin,
      capacityMax: capMax,
    );

Future<void> pumpCard(WidgetTester tester, IndividualCard card, double width, {bool yes = false}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final state = AppState();
  await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(home: card),
  ));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  fillVenueSetup(state, yes: yes);
  await tester.pump();
}

void main() {
  setUpAll(_initSupabase);

  for (final width in [390.0, 1280.0]) {
    group('Vendor page at ${width.toInt()}px', () {
      testWidgets('has labeled Love, YES and Website actions', (tester) async {
        await pumpCard(tester, barn(), width);
        final row = find.byType(VendorActionRow);
        expect(row, findsOneWidget);
        for (final label in ['LOVE', 'YES', 'WEBSITE']) {
          expect(find.descendant(of: row, matching: find.text(label)), findsOneWidget);
        }
      });

      testWidgets('a vendor with no photos gets a soft placeholder, not a random stock photo', (tester) async {
        await pumpCard(tester, barn(), width);
        final stock = find.byWidgetPredicate((w) =>
            w is Image && w.image is NetworkImage && (w.image as NetworkImage).url.contains('picsum'));
        expect(stock, findsNothing);
        expect(find.byKey(const ValueKey('photo-placeholder')), findsOneWidget);
      });

      testWidgets('shows price and guest capacity at a glance', (tester) async {
        await pumpCard(tester, barn(), width);
        expect(find.byType(AtAGlance), findsOneWidget);
        expect(find.text(r'$3,200'), findsWidgets);
        expect(find.text('50–300'), findsOneWidget);
      });

      testWidgets('shows the filter answers and the included amenities', (tester) async {
        await pumpCard(tester, barn(), width);
        expect(find.text('Barns, Farms & Ranches'), findsOneWidget);
        expect(find.byType(IncludedCard), findsOneWidget);
        expect(find.text('Dance Floor'), findsWidgets);
      });

      testWidgets('once it is the YES, the note offers Add to budget', (tester) async {
        await pumpCard(tester, barn(), width, yes: true);
        expect(find.text('Your YES for Venue'), findsOneWidget);
        expect(find.text('ADD TO BUDGET'), findsOneWidget);
      });

      testWidgets('the description reads as normal text, not letter-spaced', (tester) async {
        await pumpCard(tester, barn(), width);
        final about = tester.widget<Text>(find.text('A timber orchard barn.'));
        expect(about.style?.letterSpacing ?? 0, lessThanOrEqualTo(0.2));
      });

      testWidgets('the vendor name is set in Playfair, not wide-spaced Bodoni', (tester) async {
        await pumpCard(tester, barn(), width);
        final title = tester.widget<Text>(find.text('The Barn at Wall Brothers Orchards').first);
        expect(title.style?.fontFamily, contains('PlayfairDisplay'));
        expect(title.style?.letterSpacing ?? 0, lessThanOrEqualTo(0.5));
      });
    });
  }
}
