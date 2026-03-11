import 'package:flutter/material.dart';
import '../templates/collection_page_template.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';

class LovedPage extends StatelessWidget {
  const LovedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (!appState.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return CollectionPageTemplate(
          pageTitle: "Loved",
          categories: appState.lovedCategorizedMap,
          onHeartToggled: (vendorId, hearted) {
            appState.toggleHeart(vendorId, hearted);
          },
          isLovedPage: true,
        );
      },
    );
  }
}
