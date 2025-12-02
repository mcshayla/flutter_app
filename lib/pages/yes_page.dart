import 'package:flutter/material.dart';
import '../templates/collection_page_template.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import '../utils/string_extensions.dart';


class YesPage extends StatelessWidget {
  const YesPage({super.key});

  @override
  Widget build(BuildContext context) {
     final appState = Provider.of<AppState>(context);
     final diamondedCategories = appState.diamondedCards;
     final categoriesMap = appState.allCategorizedMap;
     final categoryKeys = categoriesMap.keys.toList();
    return Scaffold( 
      body: Column(
        children: [
          Text("Mr. & Mrs."),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: diamondedCategories.length,
              itemBuilder: (context, index) {
                final category = diamondedCategories.keys.elementAt(index);
                final vendorId = diamondedCategories[category];
                // Get vendor name safely
                final vendorList = categoriesMap[category.capitalize()] ?? [];
                final vendor = vendorList.firstWhere(
                  (v) => v['vendor_id'] == vendorId,
                  orElse: () => {"vendor_name": "Unknown"}
                );
                final vendorName = vendor['vendor_name'];
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: vendorName != "Unknown"
                      ? Text("$category -- $vendorName")
                      : SizedBox.shrink(), // empty widget
                );
              })
          )
        ]
      )
    );
  }
}