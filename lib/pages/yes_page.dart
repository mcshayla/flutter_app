import 'package:flutter/material.dart';
import '../templates/collection_page_template.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import '../utils/string_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import './individual_card.dart';


class YesPage extends StatelessWidget {
  const YesPage({super.key});

  @override
  Widget build(BuildContext context) {
     final appState = Provider.of<AppState>(context);
     final diamondedCategories = appState.diamondedCards;
     final categoriesMap = appState.allCategorizedMap;
     final categoryKeys = categoriesMap.keys.toList();
     final filteredEntries = diamondedCategories.entries.where((entry) => entry.value.isNotEmpty).toList();
    return Scaffold( 
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(36.0),
            child:Text("Mr. & Mrs.", style: GoogleFonts.bodoniModa(
                  fontSize: 48, 
                  fontWeight: FontWeight.w600, // Medium to Semi-Bold for impact
                  letterSpacing: 2.0, // A little spacing for elegance
                  color: const Color(0xFF7B3F61)
                )),
          ),
          
          Expanded(
            
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: filteredEntries.length,
              itemBuilder: (context, index) {
                // final category = diamondedCategories.keys.elementAt(index);
                // final vendorId = diamondedCategories[category];
                
                final category = filteredEntries[index].key;
                final vendorId = filteredEntries[index].value;
                 // Get vendor name safely
                // Get vendor name safely
                final vendorList = categoriesMap[category.capitalize()] ?? [];
                final vendor = vendorList.firstWhere(
                  (v) => v['vendor_id'] == vendorId,
                  orElse: () => {"vendor_name": "Unknown"}
                );
                final vendorName = vendor['vendor_name'];
                return Padding( 
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   Padding(
                   padding: const EdgeInsets.all(8),
                   child:Text(
                      category.capitalize(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7B3F61),
                          ),
                    ),
                ),
                   GestureDetector(
                    onTap: () => {
                      Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:(_) => IndividualCard(
                                      vendor_id: vendor['vendor_id'],
                                      category: category,
                                      imageUrl: vendor['image_url'] ?? "",
                                      title: vendor['vendor_name'] ?? "",
                                      description: vendor['vendor_description'] ?? "",
                                      style_keywords: vendor['style_keywords'] ?? "",
                                      location: vendor['vendor_location'] ?? "",
                                      address: vendor['address'] ?? "",
                                      vendor_estimated_price: vendor['vendor_estimated_price'] ?? "",
                                      vendor_price: vendor['vendor_price'] ?? "",
                                      contact_email: vendor['contaact_emal'] ?? "",
                                      contact_phone: vendor['contact_phone'] ?? "",
                                      website_url: vendor['website_url'] ?? "",
                                      isHearted: appState.lovedVendorUUIDsCategorizedMap[category]?.contains(vendor['vendor_id']) ?? false,
                                      isDiamonded: appState.diamondedCards[appState.vendorIdToCategory[vendor['vendor_id']]?.toLowerCase()] == vendor['vendor_id'],
                                      onHeartToggled: (hearted) {
                                        appState.toggleHeart(vendor['vendor_id'], hearted);
                                      },
                                      onDiamondToggled: (diamonded) {
                                        appState.toggleDiamond(vendor['vendor_id'], diamonded);
                                      },
                                    )
                                  )
                      )
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
                            offset: Offset(2,2),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Center(
                          child: Text(vendorName, style: GoogleFonts.bodoniModa(
                          fontSize: 24, 
                          fontWeight: FontWeight.w600, // Medium to Semi-Bold for impact
                          letterSpacing: 2.0, // A little spacing for elegance
                          color: const Color.fromARGB(255, 0, 0, 0)
                           )
                           )
                        )
                        ),
                    )

                //   child: Container( 
                //     width: 300,
                //     height: 100,
                //   padding: const EdgeInsets.all(8),
                //   child: vendorName != "Unknown"
                //       ? Text("$category -- $vendorName")
                //       : SizedBox.shrink(), // empty widget
                // )
                ),
                ]
                ));
              })
          )
        ]
      )
    );
  }
}