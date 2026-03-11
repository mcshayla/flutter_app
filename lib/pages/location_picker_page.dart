import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String address;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerPage({
    this.initialLat,
    this.initialLng,
    super.key,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const _defaultCenter = LatLng(40.7608, -111.8910); // Salt Lake City

  late LatLng _pinPosition;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  String _address = '';
  bool _isSearching = false;
  bool _isReverseGeocoding = false;

  // Debounce timer for reverse geocoding
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final hasInitial = widget.initialLat != null && widget.initialLng != null;
    _pinPosition = hasInitial
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : _defaultCenter;

    if (hasInitial) {
      // Reverse geocode the initial position to show an address
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reverseGeocode(_pinPosition);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _isReverseGeocoding = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${pos.latitude}&lon=${pos.longitude}&format=json',
      );
      final resp = await http.get(uri, headers: {
        'User-Agent': 'EasiYESt Wedding App',
      });
      if (resp.statusCode == 200 && mounted) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final display = (data['display_name'] as String?) ?? '';
        setState(() => _address = display);
      }
    } catch (_) {
      // Silently ignore — address just stays empty
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query.trim())}'
        '&format=json&limit=1',
      );
      final resp = await http.get(uri, headers: {
        'User-Agent': 'EasiYESt Wedding App',
      });
      if (resp.statusCode == 200 && mounted) {
        final results = json.decode(resp.body) as List;
        if (results.isNotEmpty) {
          final lat = double.tryParse(results[0]['lat'] as String);
          final lon = double.tryParse(results[0]['lon'] as String);
          if (lat != null && lon != null) {
            final newPos = LatLng(lat, lon);
            setState(() {
              _pinPosition = newPos;
              _address = (results[0]['display_name'] as String?) ?? '';
            });
            _mapController.move(newPos, 13.0);
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Address not found. Try a different search.',
                style: GoogleFonts.montserrat(fontSize: 12),
              ),
              backgroundColor: const Color(0xFF7B3F61),
            ),
          );
        }
      }
    } catch (_) {
      // Silently ignore search errors
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _onMapTap(TapPosition tapPos, LatLng latLng) {
    setState(() => _pinPosition = latLng);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _reverseGeocode(latLng);
    });
  }

  @override
  Widget build(BuildContext context) {
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
          'Set Location',
          style: GoogleFonts.bodoniModa(
            color: const Color(0xFF7B3F61),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.montserrat(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search for an address…',
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: const Color(0xFF6E6E6E),
                ),
                prefixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF7B3F61)),
                          ),
                        ),
                      )
                    : const Icon(Icons.search,
                        color: Color(0xFF7B3F61), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: 18, color: Color(0xFF6E6E6E)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFDCC7AA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF7B3F61)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: _searchAddress,
              textInputAction: TextInputAction.search,
            ),
          ),

          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _pinPosition,
                initialZoom: widget.initialLat != null ? 13.0 : 10.0,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.easiyest.say_yes',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pinPosition,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Color(0xFF7B3F61),
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Address + confirm button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Color(0xFF7B3F61), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _isReverseGeocoding
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF7B3F61)),
                              ),
                            )
                          : Text(
                              _address.isNotEmpty
                                  ? _address
                                  : 'Tap on the map to place a pin',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: _address.isNotEmpty
                                    ? const Color(0xFF3E3E3E)
                                    : const Color(0xFF6E6E6E),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        LocationResult(
                          latitude: _pinPosition.latitude,
                          longitude: _pinPosition.longitude,
                          address: _address,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B3F61),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Confirm Location',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
