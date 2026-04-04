import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import 'explore_page.dart';

class LovedPage extends StatelessWidget {
  const LovedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (!appState.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        if (appState.lovedCategorizedMap.isEmpty) {
          return const _EmptyLovedState();
        }

        return CategoryLanding(
          categories: appState.lovedCategorizedMap,
          isLovedPage: true,
        );
      },
    );
  }
}

class _EmptyLovedState extends StatelessWidget {
  const _EmptyLovedState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Color(0xFFDCC7AA)),
            const SizedBox(height: 20),
            Text(
              'Heart vendors to save them here',
              textAlign: TextAlign.center,
              style: GoogleFonts.bodoniModa(
                fontSize: 22,
                color: const Color(0xFF7B3F61),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap the ♡ on any vendor to add them to your Loved list',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF6E6E6E),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
