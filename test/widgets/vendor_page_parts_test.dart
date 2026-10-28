import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/services/vendor_page_logic.dart';
import 'package:say_yes/widgets/vendor_page_parts.dart';

Future<void> pump(WidgetTester tester, Widget child, {double width = 390, bool reduceMotion = false}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 1600), disableAnimations: reduceMotion),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  ));
}

void main() {
  group('VendorActionRow', () {
    Widget row({bool loved = false, bool yes = false, String website = 'https://example.com', ValueChanged<bool>? onLove, ValueChanged<bool>? onYes, VoidCallback? onWebsite}) =>
        VendorActionRow(
          isLoved: loved,
          isYes: yes,
          websiteUrl: website,
          onLove: onLove ?? (_) {},
          onYes: onYes ?? (_) {},
          onWebsite: onWebsite ?? () {},
        );

    testWidgets('labels all three actions: Love, YES and Website', (tester) async {
      await pump(tester, row());
      expect(find.text('LOVE'), findsOneWidget);
      expect(find.text('YES'), findsOneWidget);
      expect(find.text('WEBSITE'), findsOneWidget);
      expect(find.text('COMPARE'), findsNothing);
    });

    testWidgets('Love and YES toggle their current state', (tester) async {
      bool? love, yes;
      await pump(tester, row(loved: true, onLove: (v) => love = v, onYes: (v) => yes = v));
      await tester.tap(find.text('LOVED'));
      await tester.tap(find.text('YES'));
      expect(love, isFalse);
      expect(yes, isTrue);
    });

    testWidgets('a chosen YES shows the filled diamond', (tester) async {
      await pump(tester, row(yes: true));
      expect(find.byIcon(Icons.diamond), findsOneWidget);
      await pump(tester, row(yes: false));
      expect(find.byIcon(Icons.diamond_outlined), findsOneWidget);
    });

    testWidgets('no Website button when the vendor has no website', (tester) async {
      await pump(tester, row(website: ''));
      expect(find.text('WEBSITE'), findsNothing);
    });

    testWidgets('becoming a YES plays a short shimmer', (tester) async {
      await pump(tester, row(yes: false));
      await pump(tester, row(yes: true));
      expect(find.byKey(const ValueKey('yes-shimmer')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('yes-shimmer')), findsNothing);
    });

    testWidgets('no shimmer for people who turned off animations', (tester) async {
      await pump(tester, row(yes: false), reduceMotion: true);
      await pump(tester, row(yes: true), reduceMotion: true);
      expect(find.byKey(const ValueKey('yes-shimmer')), findsNothing);
    });
  });

  group('YesNote', () {
    testWidgets('names the category and offers Add to budget', (tester) async {
      var added = 0;
      await pump(tester, YesNote(category: 'Venue', onAddToBudget: () => added++));
      expect(find.text('Your YES for Venue'), findsOneWidget);
      await tester.tap(find.text('ADD TO BUDGET'));
      expect(added, 1);
    });

    testWidgets('without a price there is nothing to add to the budget', (tester) async {
      await pump(tester, const YesNote(category: 'Venue', onAddToBudget: null));
      expect(find.text('ADD TO BUDGET'), findsNothing);
    });
  });

  group('AtAGlance', () {
    testWidgets('shows each number over its label', (tester) async {
      await pump(tester, const AtAGlance(items: [GlanceItem(r'$3,200', 'Starting price'), GlanceItem('50–300', 'Guests')]));
      expect(find.text(r'$3,200'), findsOneWidget);
      expect(find.text('STARTING PRICE'), findsOneWidget);
      expect(find.text('50–300'), findsOneWidget);
      expect(find.text('GUESTS'), findsOneWidget);
    });

    testWidgets('renders nothing when there are no numbers', (tester) async {
      await pump(tester, const AtAGlance(items: []));
      expect(find.byType(Text), findsNothing);
    });
  });

  group('IncludedCard and highlights', () {
    const groups = [
      IncludedGroup('Included Services', [IncludedItem('Clean-Up Included', 'cleaning_services')]),
      IncludedGroup('Facilities', [IncludedItem('Dance Floor', 'nightlife'), IncludedItem('Mystery', 'not_a_real_icon')]),
    ];

    testWidgets('a "What\'s included" card with group labels and icons', (tester) async {
      await pump(tester, const IncludedCard(groups: groups));
      expect(find.text("What's included"), findsOneWidget);
      expect(find.text('INCLUDED SERVICES'), findsOneWidget);
      expect(find.text('FACILITIES'), findsOneWidget);
      expect(find.text('Dance Floor'), findsOneWidget);
      expect(find.byIcon(Icons.nightlife), findsOneWidget);
      // An unknown icon name falls back instead of drawing a blank.
      expect(find.text('Mystery'), findsOneWidget);
    });

    testWidgets('highlights show up to three round icons with labels', (tester) async {
      await pump(tester, const HighlightMedallions(items: [
        IncludedItem('Bridal suite', 'checkroom'),
        IncludedItem('Dance floor', 'nightlife'),
        IncludedItem('Clean-up', 'cleaning_services'),
        IncludedItem('Wi-Fi', 'wifi'),
      ]));
      expect(find.text('Bridal suite'), findsOneWidget);
      expect(find.text('Clean-up'), findsOneWidget);
      expect(find.text('Wi-Fi'), findsNothing);
    });
  });

  group('DetailsList', () {
    testWidgets('shows each filter answer under its label', (tester) async {
      await pump(tester, const DetailsList(items: [DetailItem('Venue Type', 'Barns, Farms & Ranches')]));
      expect(find.text('VENUE TYPE'), findsOneWidget);
      expect(find.text('Barns, Farms & Ranches'), findsOneWidget);
    });
  });

  group('PhotoMosaic', () {
    testWidgets('lays out three photos with one arched', (tester) async {
      await pump(tester, const PhotoMosaic(images: ['a.jpg', 'b.jpg', 'c.jpg'], imageBuilder: _box));
      expect(find.byKey(const ValueKey('mosaic-arch')), findsOneWidget);
      expect(find.byType(ColoredBox), findsNWidgets(3));
    });

    testWidgets('draws nothing with fewer than three', (tester) async {
      await pump(tester, const PhotoMosaic(images: ['a.jpg'], imageBuilder: _box));
      expect(find.byKey(const ValueKey('mosaic-arch')), findsNothing);
    });
  });

  group('ReviewPullQuote', () {
    testWidgets('sets the review in quotes with stars and the reviewer', (tester) async {
      await pump(tester, const ReviewPullQuote(review: {'comment': 'The orchard was perfect', 'rating': 5, 'userName': 'Emma'}));
      expect(find.text('“The orchard was perfect”'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNWidgets(5));
      expect(find.text('EMMA'), findsOneWidget);
    });
  });
}

Widget _box(String url) => const ColoredBox(color: Colors.grey);
