import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/widgets/card.dart';

void main() {
  Widget buildCard({
    bool isHearted = false,
    bool isDiamonded = false,
    Function(bool)? onHeartToggled,
    Function(bool)? onDiamondToggled,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CustomCard(
          title: 'Test Vendor',
          description: 'A lovely test vendor',
          imageUrl: 'https://picsum.photos/200/300',
          isHearted: isHearted,
          isDiamonded: isDiamonded,
          onHeartToggled: onHeartToggled,
          onDiamondToggled: onDiamondToggled,
          onTap: onTap,
        ),
      ),
    );
  }

  // ─── Heart icon display ────────────────────────────────────────────────────

  group('CustomCard – heart icon display', () {
    testWidgets('shows favorite_border when not hearted', (tester) async {
      await tester.pumpWidget(buildCard(isHearted: false));

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('shows favorite (filled) when hearted', (tester) async {
      await tester.pumpWidget(buildCard(isHearted: true));

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });
  });

  // ─── Heart icon interaction ────────────────────────────────────────────────

  group('CustomCard – heart icon interaction', () {
    testWidgets('calls onHeartToggled(true) when tapping an un-hearted card',
        (tester) async {
      bool? received;
      await tester.pumpWidget(buildCard(
        isHearted: false,
        onHeartToggled: (v) => received = v,
      ));

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      expect(received, isTrue);
    });

    testWidgets('calls onHeartToggled(false) when tapping an already-hearted card',
        (tester) async {
      bool? received;
      await tester.pumpWidget(buildCard(
        isHearted: true,
        onHeartToggled: (v) => received = v,
      ));

      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pump();

      expect(received, isFalse);
    });

    testWidgets('does not call onDiamondToggled when heart icon is tapped',
        (tester) async {
      bool diamondCalled = false;
      await tester.pumpWidget(buildCard(
        isHearted: false,
        onDiamondToggled: (_) => diamondCalled = true,
      ));

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      expect(diamondCalled, isFalse);
    });
  });

  // ─── Diamond icon display ──────────────────────────────────────────────────

  group('CustomCard – diamond icon display', () {
    testWidgets('shows diamond_outlined when not diamonded', (tester) async {
      await tester.pumpWidget(buildCard(isDiamonded: false));

      expect(find.byIcon(Icons.diamond_outlined), findsOneWidget);
      expect(find.byIcon(Icons.diamond), findsNothing);
    });

    testWidgets('shows diamond (filled) when diamonded', (tester) async {
      await tester.pumpWidget(buildCard(isDiamonded: true));

      expect(find.byIcon(Icons.diamond), findsOneWidget);
      expect(find.byIcon(Icons.diamond_outlined), findsNothing);
    });
  });

  // ─── Diamond icon interaction ──────────────────────────────────────────────

  group('CustomCard – diamond icon interaction', () {
    testWidgets('calls onDiamondToggled(true) when tapping an un-diamonded card',
        (tester) async {
      bool? received;
      await tester.pumpWidget(buildCard(
        isDiamonded: false,
        onDiamondToggled: (v) => received = v,
      ));

      await tester.tap(find.byIcon(Icons.diamond_outlined));
      await tester.pump();

      expect(received, isTrue);
    });

    testWidgets(
        'calls onDiamondToggled(false) when tapping an already-diamonded card',
        (tester) async {
      bool? received;
      await tester.pumpWidget(buildCard(
        isDiamonded: true,
        onDiamondToggled: (v) => received = v,
      ));

      await tester.tap(find.byIcon(Icons.diamond));
      await tester.pump();

      expect(received, isFalse);
    });

    testWidgets('does not call onHeartToggled when diamond icon is tapped',
        (tester) async {
      bool heartCalled = false;
      await tester.pumpWidget(buildCard(
        isDiamonded: false,
        onHeartToggled: (_) => heartCalled = true,
      ));

      await tester.tap(find.byIcon(Icons.diamond_outlined));
      await tester.pump();

      expect(heartCalled, isFalse);
    });
  });

  // ─── Combined state ────────────────────────────────────────────────────────

  group('CustomCard – combined heart + diamond state', () {
    testWidgets('shows both filled icons when hearted and diamonded',
        (tester) async {
      await tester.pumpWidget(buildCard(isHearted: true, isDiamonded: true));

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.diamond), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
      expect(find.byIcon(Icons.diamond_outlined), findsNothing);
    });

    testWidgets('shows both outlined icons when neither hearted nor diamonded',
        (tester) async {
      await tester.pumpWidget(buildCard(isHearted: false, isDiamonded: false));

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.diamond_outlined), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
      expect(find.byIcon(Icons.diamond), findsNothing);
    });
  });
}
