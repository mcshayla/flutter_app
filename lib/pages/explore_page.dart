import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../utils/category_names.dart';
import '../widgets/stationery.dart';
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
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final categoryNames = categories.keys.toList();

    return Scaffold(
      backgroundColor: AppStyles.cream,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final colCount = _columnCount(constraints.maxWidth);
          final isMobile = constraints.maxWidth < 600;
          final hPad = isMobile ? 16.0 : 32.0;

          return CustomScrollView(
            slivers: [
              if (!isLovedPage)
                SliverToBoxAdapter(
                  child: Container(
                    color: AppStyles.blush,
                    padding: EdgeInsets.fromLTRB(hPad, isMobile ? 28 : 44, hPad, isMobile ? 26 : 40),
                    child: Column(children: [
                      const Eyebrow('Explore'),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: 'Plan your ', style: AppStyles.display(isMobile ? 28 : 38)),
                          TextSpan(text: 'Utah wedding', style: AppStyles.display(isMobile ? 28 : 38, color: AppStyles.plum, italic: true)),
                        ]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const HeartRule(width: 200),
                      const SizedBox(height: 12),
                      Text('Loved, local, handpicked vendors.',
                          textAlign: TextAlign.center, style: AppStyles.body(isMobile ? 14 : 16, color: AppStyles.inkSoft)),
                    ]),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, isMobile ? 24 : 40, hPad, 40),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: AppStyles.maxContentWidth),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categoryNames.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: colCount,
                          // Arch (4:5) plus room for the label underneath.
                          childAspectRatio: 0.66,
                          crossAxisSpacing: isMobile ? 14 : 28,
                          mainAxisSpacing: isMobile ? 18 : 32,
                        ),
                        itemBuilder: (context, index) {
                          final name = categoryNames[index];
                          return _CategoryCard(
                            categoryName: name,
                            imageUrl: _extractImageUrl(categories[name] ?? const []),
                            showOnlyLoved: isLovedPage,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


/// An arched photo with the category name underneath, like the website's
/// cards. The photo stays sharp; the label never sits on top of it.
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
    final label = categoryDisplayName(widget.categoryName);
    return Semantics(
      button: true,
      label: label,
      child: MouseRegion(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AnimatedSlide(
                  offset: Offset(0, _isHovered ? -0.02 : 0),
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    // Hairline rose ring around the arch, offset by a cream gap.
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(999)),
                      border: Border.all(color: _isHovered ? AppStyles.plum : AppStyles.rose),
                    ),
                    child: ClipRRect(
                      key: ValueKey('category-arch-${widget.categoryName}'),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(999)),
                      child: widget.imageUrl != null
                          ? Image.network(
                              supabaseThumb(widget.imageUrl!, width: 600),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const _GradientBackground(),
                            )
                          : const _GradientBackground(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: AppStyles.display(17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppStyles.rose, AppStyles.plum],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}
