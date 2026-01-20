import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:say_yes/utils/string_extensions.dart';
import '../widgets/card.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import 'category_template.dart';
import '../utils/string_extensions.dart';
import '../pages/individual_card.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../appstate.dart';


class CollectionPageTemplate extends StatefulWidget {
  final String pageTitle;
  final Map<String, List<Map<String, dynamic>>> categories;
  final Function(String vendorId, bool isHearted)? onHeartToggled;
  final bool isLovedPage;

  const CollectionPageTemplate({
    required this.pageTitle,
    required this.categories,
    this.onHeartToggled,
    required this.isLovedPage,
    super.key,
  });

  @override
  State<CollectionPageTemplate> createState() => _CollectionPageTemplateState();
}

class _CollectionPageTemplateState extends State<CollectionPageTemplate> {
  String? selectedState;
  String? selectedCounty;
  
  int _calculateItemCount(int itemsLength, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = 160.0; // CustomCard width
    final padding = 16.0; // horizontal padding
    
    final availableWidth = screenWidth - (padding * 2);
    final cardsPerScreen = (availableWidth / cardWidth).floor();
    final cardsToShow = (cardsPerScreen * 1.5).round();
    
    return min(itemsLength, max(cardsToShow, 6)); 
  }

  Map<String, List<Map<String, dynamic>>> _getFilteredCategories() {
    if (selectedState == null && selectedCounty == null) {
      return widget.categories;
    }

    Map<String, List<Map<String, dynamic>>> filteredCategories = {};

    widget.categories.forEach((categoryName, items) {
      final filteredItems = items.where((item) {
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

      if (filteredItems.isNotEmpty) {
        filteredCategories[categoryName] = filteredItems;
      }
    });

    return filteredCategories;
  }

  List<String> _getAvailableStates() {
    Set<String> states = {};
    widget.categories.forEach((_, items) {
      for (var item in items) {
        if (item['vendor_state'] != null) {
          if (item['vendor_state'] is List) {
            for (var state in item['vendor_state'] as List) {
              if (state != null && state.toString().trim().isNotEmpty) {
                states.add(state.toString());
              }
            }
          } else if (item['vendor_state'].toString().trim().isNotEmpty) {
            states.add(item['vendor_state'].toString());
          }
        }
      }
    });
    return states.toList()..sort();
  }

  List<String> _getAvailableCounties() {
    Set<String> counties = {};
    widget.categories.forEach((_, items) {
      for (var item in items) {
        // Filter by selected state if one is chosen
        if (selectedState != null && item['vendor_state'] != null) {
          final states = item['vendor_state'] is List 
              ? (item['vendor_state'] as List).map((e) => e.toString()).toList()
              : [item['vendor_state'].toString()];
          if (!states.contains(selectedState)) {
            continue;
          }
        }

        if (item['vendor_county'] != null) {
          if (item['vendor_county'] is List) {
            for (var county in item['vendor_county'] as List) {
              if (county != null && county.toString().trim().isNotEmpty && county.toString().trim() != "Any") {
                counties.add(county.toString());
              }
            }
          } else if (item['vendor_county'].toString().trim().isNotEmpty && item['vendor_county'].toString().trim() != "Any") {
            counties.add(item['vendor_county'].toString());
          }
        }
      }
    });
    return counties.toList()..sort();
  }

  void _clearFilters() {
    setState(() {
      selectedState = null;
      selectedCounty = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryKeys = _getFilteredCategories().keys.toList();
    final supabase = Supabase.instance.client;
    final availableStates = _getAvailableStates();
    final availableCounties = _getAvailableCounties();
    
    return Scaffold(
      body: Column(
        children: [
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Text(
                'the easiYESt way to plan your perfect wedding',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
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
            child: Row(
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
                            !_getAvailableCounties().contains(selectedCounty)) {
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
                        horizontal: 6,
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
          ),
          
          Expanded(
            child: Consumer<AppState>(
              builder: (context, appState, _) {
                final filteredCategories = _getFilteredCategories();
                final filteredCategoryKeys = filteredCategories.keys.toList();
                
                return filteredCategoryKeys.isEmpty
                  ? Center(
                      child: Text(
                        widget.isLovedPage 
                            ? "Heart vendors to see them here!"
                            : "No vendors found matching your filters.",
                        style: AppStyles.simpleElegant,
                      ),
                    )
                  : ListView.builder(
                itemCount: filteredCategoryKeys.length,
                itemBuilder: (context, index) {
                  final categoryName = filteredCategoryKeys[index];
                  final items = filteredCategories[categoryName]!;
                  String capCategoryName = categoryName.pluralize();
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                child: Text(
                                capCategoryName,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromRGBO(123, 63, 97, 1),
                                    ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:(_) => CategoryPageTemplate(
                                        categoryName: categoryName,
                                        showOnlyLoved: widget.isLovedPage,
                                      )
                                  )
                                  );
                                },
                              ),
                              GestureDetector(
                                child: Text(
                                  "View All",
                                  style: AppStyles.backButton,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:(_) => CategoryPageTemplate(
                                        categoryName: categoryName,
                                        showOnlyLoved: widget.isLovedPage,
                                      )
                                  )
                                  );
                                },
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _calculateItemCount(items.length, context),
                            itemBuilder: (context, itemIndex) {

                              final item = items[itemIndex];
                              return Selector<AppState, bool>(
                                selector: (_, appState) =>
                                    appState.lovedVendorUUIDsCategorizedMap[categoryName]
                                        ?.contains(item['vendor_id']) ??
                                    false,
                                builder: (_, isHearted, __) {
                              return CustomCard(
                                title: item['vendor_name'] ?? "",
                                description: item['vendor_description'] ?? "",
                                imageUrl: ((item['image_url'] as List<dynamic>?)?.isNotEmpty ?? false)
                                    ? (item['image_url'] as List<dynamic>)[0].toString()
                                    : "https://picsum.photos/200/300",
                                isHearted: appState.lovedVendorUUIDsCategorizedMap[categoryName]?.contains(item['vendor_id']) ?? false,
                                isDiamonded: appState.diamondedCards[appState.vendorIdToCategory[item['vendor_id']]] == item['vendor_id'],
                                onHeartToggled: (hearted) {
                                  appState.toggleHeart(item['vendor_id'], hearted);
                                },
                                onDiamondToggled: (diamonded) {
                                  appState.toggleDiamond(item['vendor_id'], diamonded);
                                },
                                onTap: () {
                                  appState.trackCardClick(item['vendor_id']);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      
                                      builder:(_) => IndividualCard(
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
                                        vendor_id: item['vendor_id'] ?? "",
                                        category: categoryName,
                                        isHearted: appState.lovedVendorUUIDsCategorizedMap[categoryName]?.contains(item['vendor_id']) ?? false,
                                        
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
                            })
                          ),
                      ],
                    ),
                  );
                });
              })
            ),
        ],
      ),
    );
  }
}