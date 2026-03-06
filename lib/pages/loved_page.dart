import 'package:flutter/material.dart';
import '../templates/collection_page_template.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'vendor_compare_page.dart';

class LovedPage extends StatefulWidget {
  const LovedPage({super.key});

  @override
  State<LovedPage> createState() => _LovedPageState();
}

class _LovedPageState extends State<LovedPage> {
  bool _compareMode = false;
  final Set<String> _selectedForCompare = {};
  Map<String, Map<String, dynamic>> _vendorById = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (!appState.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        // Build vendorById lookup
        _vendorById = {};
        for (var entry in appState.allCategorizedMap.entries) {
          for (var vendor in entry.value) {
            final id = vendor['vendor_id'] as String?;
            if (id != null) _vendorById[id] = vendor;
          }
        }

        final lovedCategoriesMap = appState.lovedCategorizedMap;

        return Scaffold(
          body: Column(
            children: [
              // Compare toolbar
              if (_compareMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: const Color(0xFF7B3F61).withOpacity(0.08),
                  child: Row(
                    children: [
                      Text(
                        '${_selectedForCompare.length} selected (max 3)',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: const Color(0xFF7B3F61),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _compareMode = false;
                            _selectedForCompare.clear();
                          });
                        },
                        child: Text('Cancel',
                            style: GoogleFonts.montserrat(fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _selectedForCompare.length >= 2
                            ? () {
                                final vendors = _selectedForCompare
                                    .map((id) => _vendorById[id])
                                    .whereType<Map<String, dynamic>>()
                                    .toList();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VendorComparePage(vendors: vendors),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B3F61),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Compare',
                            style: GoogleFonts.montserrat(fontSize: 13)),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: _compareMode
                    ? _buildCompareList(context, appState, lovedCategoriesMap)
                    : CollectionPageTemplate(
                        pageTitle: "Loved",
                        categories: lovedCategoriesMap,
                        onHeartToggled: (vendorId, hearted) {
                          appState.toggleHeart(vendorId, hearted);
                        },
                        isLovedPage: true,
                        onCompareToggle: () {
                          setState(() => _compareMode = true);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompareList(
    BuildContext context,
    AppState appState,
    Map<String, List<Map<String, dynamic>>> lovedCategoriesMap,
  ) {
    final allLovedVendors = <Map<String, dynamic>>[];
    for (var entry in lovedCategoriesMap.entries) {
      for (var vendor in entry.value) {
        allLovedVendors.add(vendor);
      }
    }

    if (allLovedVendors.isEmpty) {
      return Center(
        child: Text('Heart vendors to compare them!',
            style: GoogleFonts.montserrat(fontSize: 14, color: const Color(0xFF6E6E6E))),
      );
    }

    // Group by category for display
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lovedCategoriesMap.keys.length,
      itemBuilder: (context, catIndex) {
        final category = lovedCategoriesMap.keys.elementAt(catIndex);
        final vendors = lovedCategoriesMap[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                category,
                style: GoogleFonts.bodoniModa(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B3F61),
                ),
              ),
            ),
            ...vendors.map((vendor) {
              final id = vendor['vendor_id'] as String? ?? '';
              final isSelected = _selectedForCompare.contains(id);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      if (_selectedForCompare.length < 3) {
                        _selectedForCompare.add(id);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Maximum 3 vendors')),
                        );
                      }
                    } else {
                      _selectedForCompare.remove(id);
                    }
                  });
                },
                activeColor: const Color(0xFF7B3F61),
                title: Text(
                  vendor['vendor_name'] ?? '',
                  style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  vendor['vendor_location'] ?? '',
                  style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF6E6E6E)),
                ),
                secondary: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ((vendor['image_url'] as List<dynamic>?)?.isNotEmpty ?? false)
                        ? (vendor['image_url'] as List<dynamic>)[0].toString()
                        : 'https://picsum.photos/50/50',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 50,
                      color: const Color(0xFFDCC7AA),
                    ),
                  ),
                ),
              );
            }),
            const Divider(),
          ],
        );
      },
    );
  }
}
