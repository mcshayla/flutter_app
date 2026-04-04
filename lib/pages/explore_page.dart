import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

        return CategoryLanding(categories: appState.allCategorizedMap);
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


class CategoryLanding extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> categories;
  final bool isLovedPage;

  const CategoryLanding({required this.categories, this.isLovedPage = false, super.key});

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
          final isMobile = constraints.maxWidth < 600;
          final hPad = isMobile ? 16.0 : 32.0;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                children: [
                  if (kIsWeb && !isLovedPage)
                    Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 8),
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
                          const SizedBox(height: 6),
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
                      padding: EdgeInsets.fromLTRB(hPad, isMobile ? 20 : 12, hPad, isMobile ? 16 : 32),
                      child: GridView.builder(
                        itemCount: categoryNames.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: colCount,
                          childAspectRatio: isMobile ? 1.0 : 1.2,
                          crossAxisSpacing: isMobile ? 12.0 : 20.0,
                          mainAxisSpacing: isMobile ? 12.0 : 20.0,
                        ),
                        itemBuilder: (context, index) {
                          final name = categoryNames[index];
                          final vendors = categories[name] ?? [];
                          return _CategoryCard(
                            categoryName: name,
                            imageUrl: _extractImageUrl(vendors),
                            showOnlyLoved: isLovedPage,
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
  final bool showOnlyLoved;

  const _CategoryCard({required this.categoryName, this.imageUrl, this.showOnlyLoved = false});

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
              showOnlyLoved: widget.showOnlyLoved,
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
                  color: Colors.black.withOpacity(_isHovered ? 0.35 : 0.52),
                ),

                // Category name
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: AutoSizeText(
                      widget.categoryName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      minFontSize: 14,
                      style: GoogleFonts.bodoniModa(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        height: 1.3,
                        shadows: [
                          const Shadow(
                            blurRadius: 2,
                            color: Colors.black,
                            offset: Offset(0, 1),
                          ),
                          const Shadow(
                            blurRadius: 12,
                            color: Colors.black87,
                            offset: Offset(0, 0),
                          ),
                          const Shadow(
                            blurRadius: 24,
                            color: Colors.black54,
                            offset: Offset(0, 0),
                          ),
                        ],
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
