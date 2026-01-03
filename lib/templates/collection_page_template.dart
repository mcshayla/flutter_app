import 'dart:math';

import 'package:flutter/material.dart';
import 'package:say_yes/utils/string_extensions.dart';
import '../widgets/card.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import 'category_template.dart';
import '../utils/string_extensions.dart';
import '../pages/individual_card.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_styles.dart';

class CollectionPageTemplate extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // final appState = Provider.of<AppState>(context);
    final categoryKeys = categories.keys.toList();
    return Scaffold(
      // appBar: AppBar(),
      body: Column(
        children: [
          Expanded(
            child: Consumer<AppState>(
              builder: (context, appState, _) {
            return categoryKeys.isEmpty
              ? Center(
                  child: Text(
                    "Heart vendors to see them here!",
                    style: AppStyles.simpleElegant,
                  ),
                )
              : ListView.builder(
              itemCount: categoryKeys.length,
              itemBuilder: (context, index) {
                final categoryName = categoryKeys[index];
                final items = categories[categoryName]!;
                String capCategoryName = categoryName.capitalize().pluralize();
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
                                      showOnlyLoved: isLovedPage,
                                    )
                                )
                                );
                              },
                            ),
                            GestureDetector(
                              child: Text(
                                "View All $capCategoryName",
                                style: AppStyles.backButton,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:(_) => CategoryPageTemplate(
                                      categoryName: categoryName,
                                      showOnlyLoved: isLovedPage,
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
                          // itemCount: items.length
                          itemCount: min(items.length, 6),
                          itemBuilder: (context, itemIndex) {

                            final item = items[itemIndex];
                            // bool isLoved = appState.lovedVendorUUIDsCategorizedMap[categoryName]?.contains(item['vendor_id']) ?? false;
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
                              isDiamonded: appState.diamondedCards[appState.vendorIdToCategory[item['vendor_id']]?.toLowerCase()] == item['vendor_id'],
                              onHeartToggled: (hearted) {
                                appState.toggleHeart(item['vendor_id'], hearted);
                              },
                              onDiamondToggled: (diamonded) {
                                appState.toggleDiamond(item['vendor_id'], diamonded);
                              },
                              onTap: () {
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



