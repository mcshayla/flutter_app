import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:say_yes/pages/vendor_map_page.dart';

/// Tests have no network, so real OSM tile fetches throw. Serve a 1x1
/// transparent PNG instead — these tests are about markers, not tiles.
final Uint8List _blankTile = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _BlankTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_blankTile);
}

/// The map must never geocode at runtime. Vendors without stored coordinates
/// are simply not plotted — no spinner, no per-vendor network round trip.
Map<String, dynamic> vendor({
  required String id,
  double? lat,
  double? lng,
  String? address,
}) {
  return {
    'vendor_id': id,
    'vendor_name': 'Vendor $id',
    'vendor_category': 'Venue',
    'latitude': lat,
    'longitude': lng,
    if (address != null) 'address': address,
  };
}

Widget wrap(List<Map<String, dynamic>> vendors) => MaterialApp(
      home: VendorMapPage(
        vendors: vendors,
        categoryName: 'Venue',
        tileProvider: _BlankTileProvider(),
      ),
    );

void main() {
  group('VendorMapPage', () {
    testWidgets(
        'shows the empty state immediately when vendors exist but none have '
        'coordinates', (tester) async {
      // Deliberately NOT an empty list — an empty list would pass even if the
      // geocoding loop were still there.
      await tester.pumpWidget(wrap([
        vendor(id: 'a', address: '123 Main St, Provo, UT'),
        vendor(id: 'b', address: '456 State St, Ogden, UT'),
        vendor(id: 'c', address: '789 Center St, Logan, UT'),
      ]));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.textContaining('No vendors with recognisable locations'),
        findsOneWidget,
      );
    });

    testWidgets('never shows a "Locating vendors" progress pill',
        (tester) async {
      await tester.pumpWidget(wrap([
        vendor(id: 'a', address: '123 Main St, Provo, UT'),
        vendor(id: 'b', lat: 40.7608, lng: -111.8910),
      ]));
      await tester.pump();

      expect(find.textContaining('Locating vendors'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('plots vendors that have stored coordinates', (tester) async {
      await tester.pumpWidget(wrap([
        vendor(id: 'a', lat: 40.7608, lng: -111.8910),
        vendor(id: 'b', lat: 41.2230, lng: -111.9738),
      ]));
      await tester.pump();

      expect(
        find.textContaining('No vendors with recognisable locations'),
        findsNothing,
      );
      expect(find.byIcon(Icons.storefront), findsNWidgets(2));
    });
  });
}
