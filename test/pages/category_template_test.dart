import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:say_yes/appstate.dart';
import 'package:say_yes/templates/category_template.dart';
import 'package:say_yes/widgets/card.dart';

Future<void> _initSupabase() async {
  SharedPreferences.setMockInitialValues({});
  try {
    await Supabase.initialize(url: 'https://test.supabase.co', anonKey: 'test_anon_key_for_unit_tests');
  } catch (_) {}
}

Future<void> pumpList(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final s = AppState();
  await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
    value: s,
    child: const MaterialApp(home: CategoryPageTemplate(categoryName: 'Venue', showOnlyLoved: false)),
  ));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  s.allCategorizedMap = {
    'Venue': [
      {'vendor_id': 'v1', 'vendor_name': 'Grove Station', 'vendor_location': 'Pleasant Grove', 'vendor_description': 'Elegant event venue.', 'image_url': <dynamic>[]},
      {'vendor_id': 'v2', 'vendor_name': 'Memorial House', 'vendor_location': 'Salt Lake City', 'vendor_description': 'Since the 1920s.', 'image_url': <dynamic>[]},
    ],
  };
  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
  s.notifyListeners();
  await tester.pump();
}

void main() {
  setUpAll(_initSupabase);

  testWidgets('the list is titled with the plural name and a count', (tester) async {
    await pumpList(tester, 390);
    expect(find.text('Venues'), findsOneWidget);
    expect(find.text('2 venues'), findsOneWidget);
  });

  testWidgets('each card shows its city', (tester) async {
    await pumpList(tester, 390);
    expect(find.text('PLEASANT GROVE'), findsOneWidget);
    expect(find.text('SALT LAKE CITY'), findsOneWidget);
  });

  testWidgets('on a phone, one vendor per row so full names fit', (tester) async {
    await pumpList(tester, 390);
    final first = tester.getRect(find.byType(CustomCard).first);
    expect(first.width, greaterThan(300));
  });

  testWidgets('on desktop, vendors sit side by side', (tester) async {
    await pumpList(tester, 1280);
    final cards = find.byType(CustomCard);
    expect(tester.getRect(cards.at(0)).top, tester.getRect(cards.at(1)).top);
  });

  testWidgets('no random stock photos for vendors without pictures', (tester) async {
    await pumpList(tester, 390);
    final stock = find.byWidgetPredicate((w) => w is Image && w.image is NetworkImage && (w.image as NetworkImage).url.contains('picsum'));
    expect(stock, findsNothing);
  });
}
