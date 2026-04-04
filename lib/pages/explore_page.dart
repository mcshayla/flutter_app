import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../templates/collection_page_template.dart';
import '../templates/category_template.dart';
import '../appstate.dart';
import '../utils/image_utils.dart';
import 'package:provider/provider.dart';


class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (!appState.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final categoriesMap = appState.allCategorizedMap;

        if (kIsWeb) {
          return _WebCategoryLanding(categories: categoriesMap);
        }

        return CollectionPageTemplate(
          pageTitle: "Explore",
          categories: categoriesMap,
          onHeartToggled: (vendorId, hearted) {
            appState.toggleHeart(vendorId, hearted);
          },
          isLovedPage: false,
        );
      },
    );
  }
}


String? _extractImageUrl(List<Map<String, dynamic>> vendors) {
  for (final v in vendors) {
    final raw = v['image_url'];
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first?.toString();
      if (first != null && first.trim().isNotEmpty) return first.trim();
    }
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
  }
  return null;
}


class _WebCategoryLanding extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> categories;

  const _WebCategoryLanding({required this.categories});

  int _columnCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final categoryNames = categories.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final colCount = _columnCount(constraints.maxWidth);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 8),
                    child: Column(
                      children: [
                        Text(
                          'Plan your wedding the easiest way!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.bodoniModa(
                            fontSize: 28,
                            color: const Color(0xFF7B3F61),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.2,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Find, save, and organize hand-picked local vendors',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: const Color(0xFF6E6E6E),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                      child: GridView.builder(
                  itemCount: categoryNames.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: colCount,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 20.0,
                    mainAxisSpacing: 20.0,
                  ),
                  itemBuilder: (context, index) {
                    final name = categoryNames[index];
                    final vendors = categories[name] ?? [];
                    return _CategoryCard(
                      categoryName: name,
                      imageUrl: _extractImageUrl(vendors),
                    );
                  },
                ),
              ),
            ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


class _CategoryCard extends StatefulWidget {
  final String categoryName;
  final String? imageUrl;

  const _CategoryCard({required this.categoryName, this.imageUrl});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CategoryPageTemplate(
              categoryName: widget.categoryName,
              showOnlyLoved: false,
            ),
          ));
        },
        child: AnimatedScale(
          scale: _isHovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image or gradient fallback
                if (widget.imageUrl != null)
                  Image.network(
                    supabaseThumb(widget.imageUrl!, width: 600),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _GradientBackground(),
                  )
                else
                  _GradientBackground(),

                // Blur layer (only when image present)
                if (widget.imageUrl != null)
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: const SizedBox.expand(),
                    ),
                  ),

                // Dark overlay
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  color: Colors.black.withOpacity(_isHovered ? 0.25 : 0.42),
                ),

                // Category name
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.categoryName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.bodoniModa(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          shadows: [
                            const Shadow(
                              blurRadius: 8,
                              color: Colors.black54,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _GradientBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7B3F61),
            Color(0xFFDCC7AA),
          ],
        ),
      ),
    );
  }
}
