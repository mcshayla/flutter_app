import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../appstate.dart';
import '../services/vendor_filter.dart';
import '../utils/image_utils.dart';
import 'individual_card.dart';

class VendorMapPage extends StatefulWidget {
  final List<Map<String, dynamic>> vendors;
  final String categoryName;

  /// Overrides the OpenStreetMap tile source. Only meant for tests, which have
  /// no network — production always uses the default provider.
  @visibleForTesting
  final TileProvider? tileProvider;

  const VendorMapPage({
    required this.vendors,
    required this.categoryName,
    this.tileProvider,
    super.key,
  });

  @override
  State<VendorMapPage> createState() => _VendorMapPageState();
}

class _VendorMapPageState extends State<VendorMapPage> {
  final MapController _mapController = MapController();

  // vendorId → resolved LatLng
  final Map<String, LatLng> _positions = {};

  // vendorId → vendor data (for quick lookup in marker tap)
  final Map<String, Map<String, dynamic>> _vendorById = {};

  bool _mapIsReady = false;

  @override
  void initState() {
    super.initState();
    _loadPositions();
  }

  /// Plots every vendor that already has stored coordinates.
  ///
  /// Synchronous and instant by design. This used to fall back to geocoding
  /// missing addresses through Nominatim one vendor at a time, with a 1.1s
  /// rate-limit sleep each, and it withheld the camera until the whole loop
  /// finished — 45-75s for a category with unfilled coordinates, and broken
  /// outright on web where the browser strips the required User-Agent header.
  /// Vendors without coordinates are now simply not shown; a one-time backfill
  /// (python_scripts/backfill_vendor_coords.py) populates the column instead.
  void _loadPositions() {
    for (final v in vendorsWithCoordinates(widget.vendors)) {
      final id = v['vendor_id'] as String;
      _vendorById[id] = v;
      _positions[id] = LatLng(
        (v['latitude'] as num).toDouble(),
        (v['longitude'] as num).toDouble(),
      );
    }
  }

  void _fitBounds() {
    if (_positions.isEmpty) return;
    final points = _positions.values.toList();
    if (points.length == 1) {
      _mapController.move(points.first, 13.0);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(64),
      ),
    );
  }

  void _openVendorSheet(Map<String, dynamic> vendor) {
    final appState = context.read<AppState>();
    final vendorId = (vendor['vendor_id'] as String?) ?? '';
    final category = widget.categoryName;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF8F5F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCC7AA),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Vendor thumbnail
              if ((vendor['image_url'] as List?)?.isNotEmpty == true) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    supabaseThumb((vendor['image_url'] as List).first as String),
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Text(
                (vendor['vendor_name'] as String?) ?? '',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B3F61),
                ),
              ),

              if ((vendor['vendor_location'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Color(0xFF6E6E6E)),
                    const SizedBox(width: 4),
                    Text(
                      vendor['vendor_location'] as String,
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: const Color(0xFF6E6E6E)),
                    ),
                  ],
                ),
              ],

              if ((vendor['vendor_price'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  vendor['vendor_price'] as String,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: const Color(0xFF7B3F61),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    final isHearted = appState
                            .lovedVendorUUIDsCategorizedMap[category]
                            ?.contains(vendorId) ??
                        false;
                    final isDiamonded =
                        appState.diamondedCards[
                                appState.vendorIdToCategory[vendorId]] ==
                            vendorId;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IndividualCard(
                          category: category,
                          filterValues: (vendor['filter_values'] as Map<String, dynamic>?) ?? const {},
                          startingPrice: vendor['starting_price'] as num?,
                          capacityMin: (vendor['capacity_min'] as num?)?.toInt(),
                          capacityMax: (vendor['capacity_max'] as num?)?.toInt(),
                          vendor_id: vendorId,
                          title: (vendor['vendor_name'] as String?) ?? '',
                          description:
                              (vendor['vendor_description'] as String?) ?? '',
                          style_keywords:
                              (vendor['style_keywords'] as String?) ?? '',
                          location:
                              (vendor['vendor_location'] as String?) ?? '',
                          address: (vendor['address'] as String?) ?? '',
                          vendor_estimated_price:
                              (vendor['vendor_estimated_price'] as String?) ??
                                  '',
                          vendor_price:
                              (vendor['vendor_price'] as String?) ?? '',
                          contact_email:
                              (vendor['contact_email'] as String?) ?? '',
                          contact_phone:
                              (vendor['contact_phone'] as String?) ?? '',
                          website_url:
                              (vendor['website_url'] as String?) ?? '',
                          imageUrl:
                              (vendor['image_url'] as List<dynamic>?)
                                  ?.whereType<String>()
                                  .toList() ??
                              [],
                          social_media_links:
                              (vendor['social_media_links'] as List<dynamic>?)
                                  ?.whereType<String>()
                                  .toList() ??
                              [],
                          isHearted: isHearted,
                          isDiamonded: isDiamonded,
                          onHeartToggled: (v) =>
                              appState.toggleHeart(vendorId, v),
                          onDiamondToggled: (v) =>
                              appState.toggleDiamond(vendorId, v),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B3F61),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'View Profile',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build markers list for clustering
    final markers = <Marker>[];
    for (final entry in _positions.entries) {
      final v = _vendorById[entry.key]!;
      final pos = entry.value;

      markers.add(Marker(
        point: pos,
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => _openVendorSheet(v),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF7B3F61),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.storefront, color: Colors.white, size: 18),
          ),
        ),
      ));
    }

    const defaultCenter = LatLng(40.7608, -111.8910);
    final initialZoom = markers.isNotEmpty ? 8.0 : 7.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF7B3F61)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF7B3F61),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: defaultCenter,
              initialZoom: initialZoom,
              onMapReady: () {
                _mapIsReady = true;
                if (_positions.isNotEmpty) _fitBounds();
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.easiyest.say_yes',
                tileProvider: widget.tileProvider,
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 45,
                  size: const Size(40, 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(50),
                  maxZoom: 15,
                  markers: markers,
                  builder: (context, clusterMarkers) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFF7B3F61),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${clusterMarkers.length}',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Zoom + fit FABs (right side)
          Positioned(
            right: 12,
            bottom: 90,
            child: Column(
              children: [
                _mapFab(
                  icon: Icons.add,
                  onTap: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  ),
                ),
                const SizedBox(height: 8),
                _mapFab(
                  icon: Icons.remove,
                  onTap: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  ),
                ),
                const SizedBox(height: 8),
                _mapFab(
                  icon: Icons.fit_screen,
                  onTap: _fitBounds,
                ),
              ],
            ),
          ),

          // Empty state
          if (markers.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'No vendors with recognisable locations found.\nTry adjusting your filters.',
                  style: GoogleFonts.montserrat(
                      fontSize: 14, color: const Color(0xFF6E6E6E)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mapFab({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF7B3F61)),
      ),
    );
  }
}
