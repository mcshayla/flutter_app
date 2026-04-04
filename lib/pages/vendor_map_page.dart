import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../appstate.dart';
import '../utils/image_utils.dart';
import 'individual_card.dart';

class VendorMapPage extends StatefulWidget {
  final List<Map<String, dynamic>> vendors;
  final String categoryName;

  const VendorMapPage({
    required this.vendors,
    required this.categoryName,
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

  // Static geocoding cache — persists for the app session
  static final Map<String, LatLng?> _cache = {};

  bool _isGeocoding = false;
  int _locatedCount = 0;
  bool _mapIsReady = false;
  bool _positionsLoaded = false;

  @override
  void initState() {
    super.initState();
    for (final v in widget.vendors) {
      final id = (v['vendor_id'] as String?) ?? '';
      if (id.isNotEmpty) _vendorById[id] = v;
    }
    _loadPositions();
  }

  Future<void> _loadPositions() async {
    setState(() => _isGeocoding = true);

    // ── Fast path: vendors with stored coordinates ──────────────────────────
    final needsGeocoding = <Map<String, dynamic>>[];
    for (final v in widget.vendors) {
      final id = (v['vendor_id'] as String?) ?? '';
      final lat = (v['latitude'] as num?)?.toDouble();
      final lng = (v['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        _positions[id] = LatLng(lat, lng);
        _locatedCount++;
      } else {
        needsGeocoding.add(v);
      }
    }

    if (mounted) setState(() {});

    // ── Fallback: Nominatim geocoding for legacy vendors ────────────────────
    for (final v in needsGeocoding) {
      final id = (v['vendor_id'] as String?) ?? '';
      final query = ((v['address'] as String?)?.isNotEmpty == true
              ? v['address'] as String
              : v['vendor_location'] as String?) ??
          '';

      if (query.isEmpty) continue;

      if (_cache.containsKey(query)) {
        final cached = _cache[query];
        if (cached != null && mounted) {
          setState(() {
            _positions[id] = cached;
            _locatedCount++;
          });
        }
        continue;
      }

      // Nominatim rate limit: 1 req/sec
      await Future.delayed(const Duration(milliseconds: 1100));
      if (!mounted) return;

      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(query)}'
          '&format=json&limit=1&countrycodes=us',
        );
        final resp = await http.get(uri, headers: {
          'User-Agent': 'EasiYESt Wedding App',
        });

        if (resp.statusCode == 200) {
          final results = json.decode(resp.body) as List;
          if (results.isNotEmpty) {
            final lat = double.tryParse(results[0]['lat'] as String);
            final lon = double.tryParse(results[0]['lon'] as String);
            if (lat != null && lon != null && mounted) {
              final ll = LatLng(lat, lon);
              _cache[query] = ll;
              setState(() {
                _positions[id] = ll;
                _locatedCount++;
              });
            } else {
              _cache[query] = null;
            }
          } else {
            _cache[query] = null;
          }
        }
      } catch (_) {
        // Skip vendors that fail to geocode
      }
    }

    if (mounted) {
      setState(() {
        _isGeocoding = false;
        _positionsLoaded = true;
      });
      if (_mapIsReady && _positions.isNotEmpty) _fitBounds();
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
                style: GoogleFonts.bodoniModa(
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
    for (final v in widget.vendors) {
      final id = (v['vendor_id'] as String?) ?? '';
      final pos = _positions[id];
      if (pos == null) continue;

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
          style: GoogleFonts.bodoniModa(
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
                if (_positionsLoaded && _positions.isNotEmpty) _fitBounds();
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.easiyest.say_yes',
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

          // Progress pill while geocoding
          if (_isGeocoding)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF7B3F61)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Locating vendors… $_locatedCount found',
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: const Color(0xFF3E3E3E)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Empty state
          if (!_isGeocoding && markers.isEmpty)
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
