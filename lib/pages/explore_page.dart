import 'package:flutter/material.dart';
import '../templates/collection_page_template.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';


class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});
  @override
  Widget build(BuildContext context) {

    return Consumer<AppState> (
      builder: (context, appState, _) {
        if (!appState.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final categoriesMap = appState.allCategorizedMap;

        return CollectionPageTemplate(
          pageTitle: "Explore",
          categories: categoriesMap,
          onHeartToggled: (vendorId, hearted) {
            // Call your AppState method directly
            appState.toggleHeart(vendorId, hearted);
          },
        );
      }
    );
  }
}
