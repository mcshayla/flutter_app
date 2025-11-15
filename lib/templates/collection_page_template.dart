import 'package:flutter/material.dart';
import '../widgets/card.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';

class CollectionPageTemplate extends StatelessWidget {
  final String pageTitle;
  final Map<String, List<Map<String, dynamic>>> categories;
  final Function(String vendorId, bool isHearted)? onHeartToggled;

  const CollectionPageTemplate({
    required this.pageTitle,
    required this.categories,
    this.onHeartToggled,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final categoryKeys = categories.keys.toList();
    return Scaffold(
      // appBar: AppBar(),
      body: Column(
        children: [
          if (Navigator.canPop(context))
            IconButton(icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          // Constrain the main ListView inside Expanded so Column provides bounded height
          Expanded(
            child: categoryKeys.isEmpty
              ? const Center(
                  child: Text(
                    "No vendors to display",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
              itemCount: categoryKeys.length,
              itemBuilder: (context, index) {
                final categoryName = categoryKeys[index];
                final items = categories[categoryName]!;
            
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
                            Text(
                              categoryName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF7B3F61),
                                  ),
                            ),
                            GestureDetector(
                              child: Text(
                                "View All $categoryName",
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                // TODO: navigate to category page

                              },
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          itemBuilder: (context, itemIndex) {

                            final item = items[itemIndex];
                            // bool isLoved = appState.lovedVendorUUIDsCategorizedMap[categoryName]?.contains(item['vendor_id']) ?? false;
                            return CustomCard(
                              title: item['vendor_name'] ?? "",
                              description: item['vendor_description'] ?? "",
                              imageUrl: item['image_url'] ?? "",
                              isHearted: appState.lovedVendorUUIDsCategorizedMap[categoryName]?.contains(item['vendor_id']) ?? false,
                              isDiamonded: false,
                              onHeartToggled: (hearted) {
                                appState.toggleHeart(item['vendor_id'], hearted);
                              },

                              // initialHearted: appState.lovedVendorUUIDsCategorizedMap[categoryName]?.contains(item['vendor_id']) ?? false,
                              onTap: () {
                                // navigate to detail page
                                // Navigator.push()
                              },
                              // onHeartToggled: (hearted) {
                              //   if (onHeartToggled != null) {
                              //     // onHeartToggled!(item['vendor_id'], hearted);
                              //     appState.toggleHeart(item['vendor_id'], hearted);
                              //   }
                              // }
                            );
                          })
                        ),
                    ],
                  ),
                );
              })
            ),
        ],
      ),
    );
  }
}



