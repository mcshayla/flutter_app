import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/widgets/spec_card.dart';

Widget wrap(List<SpecEntry> entries, {bool isWide = false, String? heading}) =>
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SpecCard(entries: entries, isWide: isWide, heading: heading),
        ),
      ),
    );

void main() {
  group('SpecCard', () {
    testWidgets('labels are upper-cased, values are left as authored',
        (tester) async {
      await tester.pumpWidget(wrap(const [
        SpecEntry('Base Price', r'$4,500'),
      ]));

      expect(find.text('BASE PRICE'), findsOneWidget);
      expect(find.text(r'$4,500'), findsOneWidget);
    });

    testWidgets('renders nothing when there is nothing to show',
        (tester) async {
      await tester.pumpWidget(wrap(const []));

      expect(find.byType(Text), findsNothing);
      expect(find.byType(ElevatedPanel), findsNothing);
    });

    testWidgets('a link entry fires its callback when tapped', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(wrap([
        SpecEntry('Website', 'example.com', onTap: () => tapped++),
      ]));

      await tester.tap(find.text('example.com'));
      expect(tapped, 1);
    });

    testWidgets('a link is underlined and a plain fact is not', (tester) async {
      await tester.pumpWidget(wrap([
        const SpecEntry('Location', 'Salt Lake City'),
        SpecEntry('Phone', '555-0100', onTap: () {}),
      ]));

      final plain = tester.widget<Text>(find.text('Salt Lake City'));
      final link = tester.widget<Text>(find.text('555-0100'));

      expect(plain.style?.decoration, TextDecoration.none);
      expect(link.style?.decoration, TextDecoration.underline);
    });

    testWidgets('shows an optional heading above the entries', (tester) async {
      await tester.pumpWidget(wrap(
        const [SpecEntry('Location', 'Provo')],
        heading: 'Details',
      ));

      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('lays entries out in both wide and narrow modes',
        (tester) async {
      const entries = [
        SpecEntry('Location', 'Provo'),
        SpecEntry('Address', '123 Main St'),
      ];

      await tester.pumpWidget(wrap(entries, isWide: true));
      expect(find.byType(Wrap), findsOneWidget);
      expect(find.text('Provo'), findsOneWidget);

      await tester.pumpWidget(wrap(entries, isWide: false));
      expect(find.byType(Wrap), findsNothing);
      expect(find.text('Provo'), findsOneWidget);
    });
  });
}
