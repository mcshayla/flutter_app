import 'package:flutter/material.dart';
import '../templates/collection_page_template.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import '../utils/string_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import './individual_card.dart';
import '../utils/app_styles.dart';

class YesPage extends StatelessWidget {
  const YesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final diamondedCategories = appState.diamondedCards;
    final categoriesMap = appState.allCategorizedMap;
    final categoryKeys = categoriesMap.keys.toList();
    final filteredEntries = diamondedCategories.entries.where((entry) => entry.value.isNotEmpty).toList();
    final vendorMap = <String, dynamic>{};
    for (var entry in filteredEntries) {
      final vendorList = categoriesMap[entry.key.capitalize()] ?? [];
      final vendor = vendorList.firstWhere((v) => v['vendor_id'] == entry.value, orElse: () => {});
      vendorMap[entry.value] = vendor;
    }
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(36.0),
            child: Column(
              children: [
                Text("Mr. & Mrs.",
                    style: GoogleFonts.bodoniModa(
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                        color: const Color(0xFF7B3F61))),
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  color: const Color(0xFFDCC7AA),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredEntries.length == 0
                ? Center(
                    child: Text(
                      "Diamond Vendors to see them here!",
                      style: AppStyles.simpleElegant,
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final category = filteredEntries[index].key;
                      final vendorId = filteredEntries[index].value;
                      // Get vendor name safely
                      final vendor = vendorMap[vendorId] ?? {"vendor_name": "Unknown"};
                      final vendorName = vendor['vendor_name'];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(category.capitalize(),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF7B3F61),
                                      )),
                            ),
                            GestureDetector(
                              onTap: () => {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => IndividualCard(
                                              vendor_id: vendor['vendor_id'],
                                              category: category.capitalize(),
                                              title: vendor['vendor_name'] ?? "",
                                              description: vendor['vendor_description'] ?? "",
                                              style_keywords: vendor['style_keywords'] ?? "",
                                              location: vendor['vendor_location'] ?? "",
                                              address: vendor['address'] ?? "",
                                              vendor_estimated_price: vendor['vendor_estimated_price'] ?? "",
                                              vendor_price: vendor['vendor_price'] ?? "",
                                              contact_email: vendor['contact_email'] ?? "",
                                              contact_phone: vendor['contact_phone'] ?? "",
                                              website_url: vendor['website_url'] ?? "",
                                              imageUrl: (vendor['image_url'] as List<dynamic>?)
                                                          ?.whereType<String>()
                                                          .toList() ?? [],
                                                  social_media_links: (vendor['social_media_links'] as List<dynamic>?)
                                                          ?.whereType<String>()
                                                          .toList() ?? [],
                                              isHearted: appState.lovedVendorUUIDsCategorizedMap[category.capitalize()]?.contains(vendor['vendor_id']) ?? false,
                                              isDiamonded: appState.diamondedCards[appState.vendorIdToCategory[vendor['vendor_id']]?.toLowerCase()] == vendor['vendor_id'],
                                              onHeartToggled: (hearted) {
                                                appState.toggleHeart(vendor['vendor_id'], hearted);
                                              },
                                              onDiamondToggled: (diamonded) {
                                                appState.toggleDiamond(vendor['vendor_id'], diamonded);
                                              },
                                            )))
                              },
                              child: Container(
                                width: double.infinity,
                                height: 100,
                                margin: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F5F0),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(2, 2),
                                    )
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          ((vendor['image_url'] as List<dynamic>?)?.isNotEmpty ?? false)
                                              ? (vendor['image_url'] as List<dynamic>)[0].toString()
                                              : "https://picsum.photos/200/300",
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          cacheWidth: 200,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Image.network(
                                              "https://picsum.photos/200/300",
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              cacheWidth: 200,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Text(
                                          vendorName,
                                          style: GoogleFonts.bodoniModa(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600, // Medium to Semi-Bold for impact
                                            letterSpacing: 2.0,
                                          ),
                                          // style: AppStyles.fancyTitle,
                                          //   style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          // fontWeight: FontWeight.bold,
                                          // color: const Color.fromARGB(255, 9, 9, 9)
                                          // style:GoogleFonts.cormorantGaramond(
                                          //     fontSize: 22,
                                          //     fontWeight: FontWeight.w600,
                                          //   ),
                                          // style: GoogleFonts.bodoniModa(
                                          //   fontSize: 24, 
                                          //   fontWeight: FontWeight.w600,
                                          //   letterSpacing: 2.0,
                                          //   color: const Color.fromARGB(255, 0, 0, 0)
                                          // ),
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                          maxLines: 2,
                                          // You can adjust this as needed
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}