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

  /// Parsed pieces of the address, empty when the geocoder didn't return them.
  final String city;
  final String state;
  final String county;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city = '',
    this.state = '',
    this.county = '',
  });

  /// Short "City, ST" label shown on vendor cards.
  String get cityLabel {
    final abbr = _stateAbbreviations[state] ?? state;
    return [city, abbr].where((p) => p.isNotEmpty).join(', ');
  }
}

/// A Nominatim result trimmed to what the vendor form needs.
class _Place {
  final String address;
  final String city;
  final String state;
  final String county;

  const _Place(this.address, this.city, this.state, this.county);

  /// Builds "140 N Main St, Spanish Fork, UT 84660" from Nominatim's
  /// address details, instead of its long display_name
  /// ("140, North Main Street, Spanish Fork, Utah County, Utah, 84660, United States").
  factory _Place.fromNominatim(Map<String, dynamic> data) {
    final parts = (data['address'] as Map?)?.cast<String, dynamic>() ?? {};
    String part(String key) => (parts[key] as String?)?.trim() ?? '';

    final city = [
      'city',
      'town',
      'village',
      'hamlet',
      'suburb',
    ].map(part).firstWhere((v) => v.isNotEmpty, orElse: () => '');
    final state = part('state');
    final street = [part('house_number'), part('road')]
        .where((p) => p.isNotEmpty)
        .join(' ');
    final stateZip = [_stateAbbreviations[state] ?? state, part('postcode')]
        .where((p) => p.isNotEmpty)
        .join(' ');
    final formatted =
        [street, city, stateZip].where((p) => p.isNotEmpty).join(', ');

    return _Place(
      formatted.isNotEmpty
          ? formatted
          : (data['display_name'] as String?) ?? '',
      city,
      state,
      part('county'),
    );
  }
}

const _stateAbbreviations = {
  'Alabama': 'AL', 'Alaska': 'AK', 'Arizona': 'AZ', 'Arkansas': 'AR',
  'California': 'CA', 'Colorado': 'CO', 'Connecticut': 'CT',
  'Delaware': 'DE', 'Florida': 'FL', 'Georgia': 'GA', 'Hawaii': 'HI',
  'Idaho': 'ID', 'Illinois': 'IL', 'Indiana': 'IN', 'Iowa': 'IA',
  'Kansas': 'KS', 'Kentucky': 'KY', 'Louisiana': 'LA', 'Maine': 'ME',
  'Maryland': 'MD', 'Massachusetts': 'MA', 'Michigan': 'MI',
  'Minnesota': 'MN', 'Mississippi': 'MS', 'Missouri': 'MO',
  'Montana': 'MT', 'Nebraska': 'NE', 'Nevada': 'NV',
  'New Hampshire': 'NH', 'New Jersey': 'NJ', 'New Mexico': 'NM',
  'New York': 'NY', 'North Carolina': 'NC', 'North Dakota': 'ND',
  'Ohio': 'OH', 'Oklahoma': 'OK', 'Oregon': 'OR', 'Pennsylvania': 'PA',
  'Rhode Island': 'RI', 'South Carolina': 'SC', 'South Dakota': 'SD',
  'Tennessee': 'TN', 'Texas': 'TX', 'Utah': 'UT', 'Vermont': 'VT',
  'Virginia': 'VA', 'Washington': 'WA', 'West Virginia': 'WV',
  'Wisconsin': 'WI', 'Wyoming': 'WY',
};

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

  _Place _place = const _Place('', '', '', '');
  String get _address => _place.address;
  bool _isSearching = false;
  bool _isReverseGeocoding = false;

  /// Matches from the last search, shown as a pick list when there are several.
  List<Map<String, dynamic>> _searchResults = [];

  // Debounce timer for reverse geocoding
  Timer? _debounceTimer;

  // Drags fire many lookups; only the newest one may update the address.
  int _geocodeRequest = 0;

  static const _headers = {'User-Agent': 'EasiYESt Wedding App'};

  @override
  void initState() {
    super.initState();
    final hasInitial = widget.initialLat != null && widget.initialLng != null;
    _pinPosition = hasInitial
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : _defaultCenter;

    // Show an address for the starting pin so "Confirm" never saves a blank.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reverseGeocode(_pinPosition);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    final request = ++_geocodeRequest;
    setState(() => _isReverseGeocoding = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${pos.latitude}&lon=${pos.longitude}&format=json&addressdetails=1',
      );
      final resp = await http.get(uri, headers: _headers);
      if (resp.statusCode == 200 && mounted && request == _geocodeRequest) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        setState(() => _place = _Place.fromNominatim(data));
      }
    } catch (_) {
      // Silently ignore — address just stays empty
    } finally {
      if (mounted && request == _geocodeRequest) {
        setState(() => _isReverseGeocoding = false);
      }
    }
  }

  /// Nominatim only returns exact matches, and OpenStreetMap is missing many
  /// Utah house numbers (and some whole streets). So if the full address
  /// finds nothing, retry without the ZIP, then without the house number,
  /// then with just the city, so the vendor at least lands nearby.
  static List<String> _fallbackQueries(String query) {
    final noZip = query.replaceAll(RegExp(r',?\s*\d{5}(-\d{4})?\s*$'), '');
    final noHouseNumber = noZip.replaceFirst(RegExp(r'^\d+\s+'), '');
    final comma = noZip.indexOf(',');
    final cityOnly = comma == -1 ? '' : noZip.substring(comma + 1).trim();
    return {query, noZip, noHouseNumber, cityOnly}
        .where((q) => q.isNotEmpty)
        .toList();
  }

  Future<void> _searchAddress(String query) async {
    query = query.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });
    try {
      List<Map<String, dynamic>> results = [];
      final attempts = _fallbackQueries(query);
      for (var i = 0; i < attempts.length && results.isEmpty; i++) {
        // Nominatim's usage policy allows one request per second.
        if (i > 0) await Future.delayed(const Duration(seconds: 1));
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(attempts[i])}'
          '&format=json&limit=5&addressdetails=1&countrycodes=us'
          // Prefer (but don't restrict to) Utah results.
          '&viewbox=-114.05,42.0,-109.04,37.0',
        );
        final resp = await http.get(uri, headers: _headers);
        if (resp.statusCode != 200) break;
        results =
            (json.decode(resp.body) as List).cast<Map<String, dynamic>>();
      }
      if (!mounted) return;

      if (results.isEmpty) {
        _showMessage('Address not found. Try just the street and city, '
            'or drag the map to your spot.');
      } else if (results.length == 1) {
        _selectResult(results.first, query);
      } else {
        setState(() => _searchResults = results);
      }
    } catch (_) {
      if (mounted) {
        _showMessage("Search isn't working right now. "
            'Drag the map to your spot instead.');
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectResult(Map<String, dynamic> result, String query) {
    final lat = double.tryParse(result['lat'] as String);
    final lon = double.tryParse(result['lon'] as String);
    if (lat == null || lon == null) return;

    var place = _Place.fromNominatim(result);
    final houseNumber = (result['address'] as Map?)?['house_number'];
    // A street-level match drops the vendor's house number; keep what they
    // typed as the address, but take city/state/county from the match.
    if (houseNumber == null && RegExp(r'^\d+\s').hasMatch(query)) {
      place = _Place(query, place.city, place.state, place.county);
      _showMessage("Couldn't find that exact address, so this is the closest "
          'match. Drag the map so the pin sits on your spot.');
    }

    final newPos = LatLng(lat, lon);
    _debounceTimer?.cancel();
    _geocodeRequest++; // discard any lookup still in flight
    setState(() {
      _pinPosition = newPos;
      _place = place;
      _searchResults = [];
      _isReverseGeocoding = false;
    });
    _mapController.move(newPos, 17.0);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: GoogleFonts.montserrat(fontSize: 12)),
        backgroundColor: const Color(0xFF7B3F61),
      ),
    );
  }

  void _scheduleReverseGeocode(LatLng pos) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _reverseGeocode(pos);
    });
  }

  /// The pin is fixed at the center of the map, so dragging the map moves it.
  void _onMapMoved(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _pinPosition = camera.center;
    if (_searchResults.isNotEmpty) setState(() => _searchResults = []);
    _scheduleReverseGeocode(camera.center);
  }

  void _onMapTap(TapPosition tapPos, LatLng latLng) {
    _pinPosition = latLng;
    _mapController.move(latLng, _mapController.camera.zoom);
    _scheduleReverseGeocode(latLng);
  }

  Widget _buildSearchResults() {
    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _searchResults.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: Color(0xFFDCC7AA)),
          itemBuilder: (_, i) {
            final result = _searchResults[i];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.location_on,
                  color: Color(0xFF7B3F61), size: 18),
              title: Text(
                _Place.fromNominatim(result).address,
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: const Color(0xFF3E3E3E)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () =>
                  _selectResult(result, _searchController.text.trim()),
            );
          },
        ),
      ),
    );
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

          // Map, with the pin fixed at the center
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pinPosition,
                    initialZoom: widget.initialLat != null ? 16.0 : 10.0,
                    onTap: _onMapTap,
                    onPositionChanged: _onMapMoved,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.easiyest.say_yes',
                    ),
                  ],
                ),
                // Lifted by its own height so the pin's tip marks the center.
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(
                        Icons.location_pin,
                        color: Color(0xFF7B3F61),
                        size: 40,
                      ),
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty) _buildSearchResults(),
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
                                  : 'Drag the map to move the pin',
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
                          address: _place.address,
                          city: _place.city,
                          state: _place.state,
                          county: _place.county,
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
