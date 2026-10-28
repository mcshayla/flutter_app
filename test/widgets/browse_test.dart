import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/pages/explore_page.dart';
import 'package:say_yes/utils/category_names.dart';
import 'package:say_yes/widgets/card.dart';

Future<void> pumpAt(WidgetTester tester, double width, Widget child) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('categoryDisplayName', () {
    test('reads like a menu: plural where it makes sense', () {
      expect(categoryDisplayName('Venue'), 'Venues');
      expect(categoryDisplayName('Photographer'), 'Photographers');
      expect(categoryDisplayName('Videographer'), 'Videographers');
      expect(categoryDisplayName('Florist'), 'Florists');
      expect(categoryDisplayName('DJ'), 'DJs');
      expect(categoryDisplayName('Cake'), 'Cakes');
      expect(categoryDisplayName('Jeweler'), 'Jewelers');
    });
    test('names that are already a service stay as they are', () {
      expect(categoryDisplayName('Catering'), 'Catering');
      expect(categoryDisplayName('Photo & Video'), 'Photo & Video');
      expect(categoryDisplayName('Wedding Planning'), 'Wedding Planning');
      expect(categoryDisplayName('Attire'), 'Attire');
    });
    test('an unknown name passes through untouched', () {
      expect(categoryDisplayName('Something New'), 'Something New');
    });
    test('counts use the right noun', () {
      expect(vendorCountLabel('Venue', 1), '1 venue');
      expect(vendorCountLabel('Venue', 3), '3 venues');
      expect(vendorCountLabel('Catering', 2), '2 caterers');
      expect(vendorCountLabel('Something New', 2), '2 vendors');
    });
  });

  group('Explore categories', () {
    final cats = <String, List<Map<String, dynamic>>>{
      'Venue': [],
      'Videographer': [],
      'Photographer': [],
      'Catering': [],
    };

    testWidgets('labels sit under each tile, in plural', (tester) async {
      await pumpAt(tester, 390, CategoryLanding(categories: cats));
      expect(find.text('Venues'), findsOneWidget);
      expect(find.text('Videographers'), findsOneWidget);
    });

    testWidgets('photos are arched and sharp, not blurred behind text', (tester) async {
      await pumpAt(tester, 390, CategoryLanding(categories: cats));
      expect(find.byKey(const ValueKey('category-arch-Venue')), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('long names fit on one line on a phone (no "Photographe / r")', (tester) async {
      await pumpAt(tester, 390, CategoryLanding(categories: cats));
      final label = find.text('Videographers');
      final style = tester.widget<Text>(label).style!;
      expect(tester.getSize(label).height, lessThan(style.fontSize! * 2));
    });

    testWidgets('the intro shows on phones too, not just the website', (tester) async {
      await pumpAt(tester, 390, CategoryLanding(categories: cats));
      expect(find.textContaining('Utah wedding'), findsOneWidget);
    });

    testWidgets('the Loved page skips the intro', (tester) async {
      await pumpAt(tester, 390, CategoryLanding(categories: cats, isLovedPage: true));
      expect(find.textContaining('Utah wedding'), findsNothing);
    });
  });

  group('Vendor card', () {
    Widget card({String image = '', String subtitle = 'Pleasant Grove'}) => SizedBox(
          width: 360,
          height: 380,
          child: CustomCard(
            title: 'The Barn at Wall Brothers Orchards',
            description: "A timber orchard barn in the family's fruit farms.",
            imageUrl: image,
            subtitle: subtitle,
            isHearted: false,
            isDiamonded: false,
          ),
        );

    testWidgets('shows the city above a Playfair name that is not cut short', (tester) async {
      await pumpAt(tester, 390, Center(child: card()));
      expect(find.text('PLEASANT GROVE'), findsOneWidget);
      final title = tester.widget<Text>(find.text('The Barn at Wall Brothers Orchards'));
      expect(title.style?.fontFamily, contains('PlayfairDisplay'));
      expect(title.maxLines ?? 2, greaterThanOrEqualTo(2));
    });

    testWidgets('no photo shows a brand placeholder, never a random stock photo', (tester) async {
      await pumpAt(tester, 390, Center(child: card()));
      expect(find.byKey(const ValueKey('card-photo-placeholder')), findsOneWidget);
      final stock = find.byWidgetPredicate((w) => w is Image && w.image is NetworkImage && (w.image as NetworkImage).url.contains('picsum'));
      expect(stock, findsNothing);
    });

    testWidgets('keeps both the heart and the diamond', (tester) async {
      await pumpAt(tester, 390, Center(child: card()));
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.diamond_outlined), findsOneWidget);
    });
  });
}
