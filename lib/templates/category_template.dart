import 'package:flutter/material.dart';
import '../widgets/card.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import '../utils/string_extensions.dart';
import '../pages/individual_card.dart';
import '../pages/vendor_map_page.dart';
import '../utils/app_styles.dart';
import 'package:google_fonts/google_fonts.dart';


class CategoryPageTemplate extends StatefulWidget {
  final String categoryName;
  final bool showOnlyLoved;

  const CategoryPageTemplate({
    required this.categoryName,
    required this.showOnlyLoved,
    super.key
  });

  @override
  State<CategoryPageTemplate> createState() => _CategoryPageTemplateState();
}

class _CategoryPageTemplateState extends State<CategoryPageTemplate> {
  String? selectedState;
  String? selectedCounty;
  final Set<String> _selectedStyles = {};

  List<Map<String, dynamic>> _getFilteredItems(List<Map<String, dynamic>> items) {
    if (selectedState == null && selectedCounty == null) {
      return items;
    }

    return items.where((item) {
      // Handle vendor_state as array
      bool matchesState = selectedState == null;
      if (!matchesState && item['vendor_state'] != null) {
        final states = item['vendor_state'] is List 
            ? (item['vendor_state'] as List).map((e) => e.toString()).toList()
            : [item['vendor_state'].toString()];
        // If "any" is in the array, it matches all filters
        matchesState = states.contains('Any') || states.contains(selectedState);
      }

      // Handle vendor_county as array
      bool matchesCounty = selectedCounty == null;
      if (!matchesCounty && item['vendor_county'] != null) {
        final counties = item['vendor_county'] is List 
            ? (item['vendor_county'] as List).map((e) => e.toString()).toList()
            : [item['vendor_county'].toString()];
        // If "any" is in the array, it matches all filters
        matchesCounty = counties.contains('Any') || counties.contains(selectedCounty);
      }

      return matchesState && matchesCounty;
    }).toList();
  }

  List<String> _getAvailableStates(List<Map<String, dynamic>> items) {
    Set<String> states = {};
    for (var item in items) {
      if (item['vendor_state'] != null) {
        if (item['vendor_state'] is List) {
          for (var state in item['vendor_state'] as List) {
            if (state != null && state.toString().trim().isNotEmpty && state.toString() != 'Any') {
              states.add(state.toString());
            }
          }
        } else if (item['vendor_state'].toString().trim().isNotEmpty && item['vendor_state'].toString() != 'Any') {
          states.add(item['vendor_state'].toString());
        }
      }
    }
    return states.toList()..sort();
  }

  List<String> _getAvailableCounties(List<Map<String, dynamic>> items) {
    Set<String> counties = {};
    for (var item in items) {
      // Filter by selected state if one is chosen
      if (selectedState != null && item['vendor_state'] != null) {
        final states = item['vendor_state'] is List 
            ? (item['vendor_state'] as List).map((e) => e.toString()).toList()
            : [item['vendor_state'].toString()];
        if (!states.contains('Any') && !states.contains(selectedState)) {
          continue;
        }
      }

      if (item['vendor_county'] != null) {
        if (item['vendor_county'] is List) {
          for (var county in item['vendor_county'] as List) {
            if (county != null && county.toString().trim().isNotEmpty && county.toString() != 'Any') {
              counties.add(county.toString());
            }
          }
        } else if (item['vendor_county'].toString().trim().isNotEmpty && item['vendor_county'].toString() != 'Any') {
          counties.add(item['vendor_county'].toString());
        }
      }
    }
    return counties.toList()..sort();
  }

  void _clearFilters() {
    setState(() {
      selectedState = null;
      selectedCounty = null;
      _selectedStyles.clear();
    });
  }

  void _showKeywordSheet(BuildContext context, List<String> allKeywords) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search by Keywords',
                    style: GoogleFonts.bodoniModa(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7B3F61),
                    ),
                  ),
                  if (_selectedStyles.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedStyles.clear());
                        setSheetState(() {});
                      },
                      child: Text(
                        'Clear',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: const Color(0xFF7B3F61),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Select styles to filter vendors',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: const Color(0xFF6E6E6E),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allKeywords.map((k) {
                      final selected = _selectedStyles.contains(k);
                      return FilterChip(
                        label: Text(k, style: GoogleFonts.montserrat(fontSize: 13)),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedStyles.add(k);
                            } else {
                              _selectedStyles.remove(k);
                            }
                          });
                          setSheetState(() {});
                        },
                        selectedColor: const Color(0xFF7B3F61).withOpacity(0.15),
                        checkmarkColor: const Color(0xFF7B3F61),
                        labelStyle: TextStyle(
                          color: selected
                              ? const Color(0xFF7B3F61)
                              : const Color(0xFF3E3E3E),
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFF7B3F61)
                              : const Color(0xFFDCC7AA),
                        ),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B3F61),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _selectedStyles.isEmpty
                        ? 'Show All'
                        : 'Show Results (${_selectedStyles.length} selected)',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String capCategoryName = widget.categoryName;
    return Consumer<AppState>(
      builder:(context, appState, child) {
          final List<Map<String, dynamic>> categoryList = widget.showOnlyLoved
            ? (appState.lovedCategorizedMap[widget.categoryName] ?? [])
            : (appState.allCategorizedMap[widget.categoryName]  ?? []);

          var filteredList = _getFilteredItems(categoryList);
          if (_selectedStyles.isNotEmpty) {
            filteredList = filteredList.where((v) {
              final keywords = (v['style_keywords'] ?? '').toString()
                  .split(',')
                  .map((k) => k.trim())
                  .where((k) => k.isNotEmpty)
                  .toSet();
              return _selectedStyles.any((s) => keywords.contains(s));
            }).toList();
          }
          final availableStates = _getAvailableStates(categoryList);
          final availableCounties = _getAvailableCounties(categoryList);

          final allKeywords = categoryList
              .map((v) => (v['style_keywords'] ?? '').toString().split(','))
              .expand((e) => e)
              .map((k) => k.trim())
              .where((k) => k.isNotEmpty)
              .toSet()
              .toList()..sort();

        return Scaffold(
          body: Column( 
            children: [
              if (Navigator.canPop(context))
                Row( 
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: widget.showOnlyLoved ?
                        Text("My Loved $capCategoryName", style: AppStyles.backButton) : Text(capCategoryName, style: AppStyles.backButton)
                    ),
                  ]
                ),
              
              // Filter Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC7AA).withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFDCC7AA).withOpacity(0.3),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedState,
                        decoration: InputDecoration(
                          labelText: 'State',
                          labelStyle: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF7B3F61),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF7B3F61)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              'All States',
                              style: GoogleFonts.montserrat(fontSize: 11),
                            ),
                          ),
                          ...availableStates.map((state) => DropdownMenuItem(
                                value: state,
                                child: Text(
                                  state,
                                  style: GoogleFonts.montserrat(fontSize: 11),
                                ),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedState = value;
                            // Reset county when state changes
                            if (selectedCounty != null && 
                                !_getAvailableCounties(categoryList).contains(selectedCounty)) {
                              selectedCounty = null;
                            }
                          });
                        },
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: const Color(0xFF7B3F61),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCounty,
                        decoration: InputDecoration(
                          labelText: 'County',
                          labelStyle: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF7B3F61),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFDCC7AA)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF7B3F61)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              'All Counties',
                              style: GoogleFonts.montserrat(fontSize: 11),
                            ),
                          ),
                          ...availableCounties.map((county) => DropdownMenuItem(
                                value: county,
                                child: Text(
                                  county,
                                  style: GoogleFonts.montserrat(fontSize: 11),
                                ),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedCounty = value;
                          });
                        },
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: const Color(0xFF7B3F61),
                        ),
                      ),
                    ),
                  ],
                ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (allKeywords.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showKeywordSheet(context, allKeywords),
                          icon: Icon(
                            Icons.style_outlined,
                            size: 16,
                            color: _selectedStyles.isNotEmpty
                                ? Colors.white
                                : const Color(0xFF7B3F61),
                          ),
                          label: Text(
                            _selectedStyles.isEmpty
                                ? 'Search by Keywords'
                                : 'Keywords (${_selectedStyles.length})',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _selectedStyles.isNotEmpty
                                  ? Colors.white
                                  : const Color(0xFF7B3F61),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _selectedStyles.isNotEmpty
                                ? const Color(0xFF7B3F61)
                                : Colors.transparent,
                            side: const BorderSide(color: Color(0xFF7B3F61)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VendorMapPage(
                              vendors: filteredList,
                              categoryName: widget.categoryName,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.map_outlined,
                            size: 16, color: Color(0xFF7B3F61)),
                        label: Text(
                          'Search by Map',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7B3F61),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF7B3F61)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
              
              (filteredList.isEmpty) ? Expanded(
                child: Center(
                  child: Text(
                    selectedState != null || selectedCounty != null || _selectedStyles.isNotEmpty
                        ? "No vendors found matching your filters"
                        : "No vendors for this category to display",
                    style: AppStyles.backButton,
                  ),
                ),
              ): 
            Expanded( 
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder( 
                itemCount: filteredList.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
                ),
                itemBuilder:(context, index) {
                  final item = filteredList[index];
                  return Selector<AppState, bool>(
                              selector: (_, appState) =>
                                  appState.lovedVendorUUIDsCategorizedMap[widget.categoryName]
                                      ?.contains(item['vendor_id']) ??
                                  false,
                              builder: (_, isHearted, __) {
                  return CustomCard(
                    title: item['vendor_name'] ?? "",
                    description: item['vendor_description'] ?? "",
                    imageUrl: ((item['image_url'] as List<dynamic>?)?.isNotEmpty ?? false)
                        ? (item['image_url'] as List<dynamic>)[0].toString()
                        : "https://picsum.photos/200/300",
                    isHearted: appState.lovedVendorUUIDsCategorizedMap[widget.categoryName]?.contains(item['vendor_id']) ?? false,
                    onHeartToggled: (hearted) {
                      appState.toggleHeart(item['vendor_id'], hearted);
                    },
                    isDiamonded: appState.diamondedCards[appState.vendorIdToCategory[item['vendor_id']]] == item['vendor_id'],
                    onDiamondToggled: (diamonded) {
                      appState.toggleDiamond(item['vendor_id'], diamonded);
                    },
                    onTap: () {
                      appState.trackCardClick(item['vendor_id']);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:(_) => IndividualCard(
                            category: widget.categoryName,
                            vendor_id:item['vendor_id'],
                            title: item['vendor_name'] ?? "",
                            description: item['vendor_description'] ?? "",
                            style_keywords: item['style_keywords'] ?? "",
                            location: item['vendor_location'] ?? "",
                            address: item['address'] ?? "",
                            vendor_estimated_price: item['vendor_estimated_price'] ?? "",
                            vendor_price: item['vendor_price'] ?? "",
                            contact_email: item['contact_email'] ?? "",
                            contact_phone: item['contact_phone'] ?? "",
                            website_url: item['website_url'] ?? "",
                            imageUrl: (item['image_url'] as List<dynamic>?)
                                          ?.whereType<String>()
                                          .toList() ?? [],
                                      social_media_links: (item['social_media_links'] as List<dynamic>?)
                                          ?.whereType<String>()
                                          .toList() ?? [],
                            isHearted: appState.lovedVendorUUIDsCategorizedMap[widget.categoryName]?.contains(item['vendor_id']) ?? false,
                            isDiamonded: appState.diamondedCards[appState.vendorIdToCategory[item['vendor_id']]] == item['vendor_id'],
                            onHeartToggled: (hearted) {
                              appState.toggleHeart(item['vendor_id'], hearted);
                            },
                            onDiamondToggled: (diamonded) {
                              appState.toggleDiamond(item['vendor_id'], diamonded);
                            },
                          )
                        )
                      );
                    },
                  );
                });
                },
              )))
            )
            )
            ]
          )
        );
      }
    );
  }
}