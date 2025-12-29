import 'package:flutter/material.dart';
import '../widgets/card.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import '../utils/string_extensions.dart';
import '../pages/individual_card.dart';
import '../utils/app_styles.dart';


class CategoryPageTemplate extends StatelessWidget {
  final String categoryName;
  final bool showOnlyLoved;

  const CategoryPageTemplate({
    required this.categoryName,
    required this.showOnlyLoved,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    String capCategoryName = categoryName.capitalize().pluralize();
    return Consumer<AppState>(
      builder:(context, appState, child) {
          final List<Map<String, dynamic>> categoryList = showOnlyLoved
            ? (appState.lovedCategorizedMap[categoryName] ?? [])
            : (appState.allCategorizedMap[categoryName]  ?? []);

        return Scaffold(
          body: Column( 
            children: [
              if (Navigator.canPop(context))
                Row( 
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    showOnlyLoved ?
                    Text("My Loved $capCategoryName") : Text(capCategoryName)
                  ]
                ),
              (categoryList.isEmpty) ? Center(
                  child: Text(
                    "No vendors for this category to display",
                    style: AppStyles.backButton,
                  ),
                ): 
            Expanded( 
              child:Padding(
              padding: const EdgeInsets.all(12.0),
              child:GridView.builder( 
                itemCount: categoryList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
                ),
                itemBuilder:(context, index) {
                  final item = categoryList[index];
                  return CustomCard(
                    title: item['vendor_name'] ?? "",
                    description: item['vendor_description'] ?? "",
                    imageUrl: ((item['image_url'] as List<dynamic>?)?.isNotEmpty ?? false)
                        ? (item['image_url'] as List<dynamic>)[0].toString()
                        : "https://picsum.photos/200/300",
                    isHearted: appState.lovedVendorUUIDsCategorizedMap[categoryName]?.contains(item['vendor_id']) ?? false,
                    onHeartToggled: (hearted) {
                      appState.toggleHeart(item['vendor_id'], hearted);
                    },
                    isDiamonded: appState.diamondedCards[appState.vendorIdToCategory[item['vendor_id']]?.toLowerCase()] == item['vendor_id'],
                    onDiamondToggled: (diamonded) {
                      appState.toggleDiamond(item['vendor_id'], diamonded);
                    },
                    // initialHearted: appState.lovedVendorUUIDsCategorizedMap[categoryName]?.contains(item['vendor_id']) ?? false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:(_) => IndividualCard(
                            category: categoryName,
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
                            isHearted: appState.lovedVendorUUIDsCategorizedMap[categoryName]?.contains(item['vendor_id']) ?? false,
                            isDiamonded: appState.diamondedCards[appState.vendorIdToCategory[item['vendor_id']]?.toLowerCase()] == item['vendor_id'],
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
                },
              )
            )
            )
            ]
          )
        );
      }
    );
  }
}