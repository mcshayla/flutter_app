import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/utils/app_styles.dart';
import 'package:say_yes/widgets/stationery.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {

  group('StationeryButton', () {
    testWidgets('shows its label in capitals and calls onPressed',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(StationeryButton(
        label: 'Add task',
        onPressed: () => taps++,
      )));

      expect(find.text('ADD TASK'), findsOneWidget);
      await tester.tap(find.byType(StationeryButton));
      expect(taps, 1);
    });

    testWidgets('has square corners, like the website buttons', (tester) async {
      await tester.pumpWidget(wrap(StationeryButton(label: 'Go', onPressed: () {})));
      final box = tester.widget<DecoratedBox>(find.descendant(
        of: find.byType(StationeryButton),
        matching: find.byKey(const ValueKey('stationery-face')),
      ));
      final deco = box.decoration as BoxDecoration;
      expect(deco.borderRadius, anyOf(isNull, BorderRadius.zero));
    });

    testWidgets('the plum variant is filled plum with white text',
        (tester) async {
      await tester.pumpWidget(wrap(StationeryButton(
        label: 'Contact',
        variant: StationeryVariant.plum,
        onPressed: () {},
      )));
      final box = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('stationery-face')));
      expect((box.decoration as BoxDecoration).color, AppStyles.plum);
      final text = tester.widget<Text>(find.text('CONTACT'));
      expect(text.style?.color, Colors.white);
    });

    testWidgets('the line variant is outlined in plum ink', (tester) async {
      await tester.pumpWidget(wrap(StationeryButton(
        label: 'Website',
        variant: StationeryVariant.line,
        onPressed: () {},
      )));
      final box = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('stationery-face')));
      final deco = box.decoration as BoxDecoration;
      expect(deco.color, anyOf(isNull, Colors.transparent, Colors.white));
      expect((deco.border as Border).top.color, AppStyles.plumInk);
    });

    testWidgets('shows an icon when given one', (tester) async {
      await tester.pumpWidget(wrap(StationeryButton(
        label: 'YES',
        icon: Icons.diamond_outlined,
        onPressed: () {},
      )));
      expect(find.byIcon(Icons.diamond_outlined), findsOneWidget);
    });

    testWidgets('a disabled button ignores taps', (tester) async {
      await tester.pumpWidget(wrap(const StationeryButton(label: 'Save', onPressed: null)));
      await tester.tap(find.byType(StationeryButton));
      // No exception and nothing to call: the semantics report it disabled.
      final semantics = tester.getSemantics(find.byType(StationeryButton));
      expect(semantics.flagsCollection.isEnabled, isFalse);
    });
  });

  group('Eyebrow', () {
    testWidgets('upper-cases its text', (tester) async {
      await tester.pumpWidget(wrap(const Eyebrow('Your YES for Venue')));
      expect(find.text('YOUR YES FOR VENUE'), findsOneWidget);
    });
  });
}
