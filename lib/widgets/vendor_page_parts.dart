import 'package:flutter/material.dart';
import '../services/vendor_page_logic.dart';
import '../utils/amenity_icons.dart';
import '../utils/app_styles.dart';
import 'stationery.dart';

/// Building blocks for the vendor page, styled like the website.

// ---------------------------------------------------------------- actions

/// Love · YES · Website. YES is the diamond: the vendor the couple chose for
/// this category. Becoming a YES plays a short champagne shimmer, skipped
/// when the device asks for reduced motion.
class VendorActionRow extends StatefulWidget {
  final bool isLoved;
  final bool isYes;
  final String websiteUrl;
  final ValueChanged<bool> onLove;
  final ValueChanged<bool> onYes;
  final VoidCallback onWebsite;

  const VendorActionRow({
    required this.isLoved,
    required this.isYes,
    required this.websiteUrl,
    required this.onLove,
    required this.onYes,
    required this.onWebsite,
    super.key,
  });

  @override
  State<VendorActionRow> createState() => _VendorActionRowState();
}

class _VendorActionRowState extends State<VendorActionRow> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() {});
    });

  @override
  void didUpdateWidget(VendorActionRow old) {
    super.didUpdateWidget(old);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!old.isYes && widget.isYes && !reduceMotion) {
      _shimmer.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  Widget _action({required String label, required IconData icon, required bool on, required VoidCallback onTap, Widget? overlay}) {
    final fg = on ? Colors.white : AppStyles.plumInk;
    return Expanded(
      child: Semantics(
        button: true,
        toggled: on,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: on ? AppStyles.plumInk : Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 44,
              decoration: BoxDecoration(border: Border.all(color: AppStyles.plumInk)),
              child: Stack(fit: StackFit.expand, children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icon, size: 15, color: on ? AppStyles.champagne : AppStyles.plumInk),
                  const SizedBox(width: 6),
                  Flexible(child: Text(label.toUpperCase(), overflow: TextOverflow.ellipsis, style: AppStyles.eyebrow(size: 10, color: fg))),
                ]),
                if (overlay != null) overlay,
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shimmering = _shimmer.isAnimating;
    return Row(children: [
      _action(
        label: widget.isLoved ? 'Loved' : 'Love',
        icon: widget.isLoved ? Icons.favorite : Icons.favorite_border,
        on: widget.isLoved,
        onTap: () => widget.onLove(!widget.isLoved),
      ),
      const SizedBox(width: 8),
      _action(
        label: 'YES',
        icon: widget.isYes ? Icons.diamond : Icons.diamond_outlined,
        on: widget.isYes,
        onTap: () => widget.onYes(!widget.isYes),
        overlay: shimmering
            ? IgnorePointer(
                key: const ValueKey('yes-shimmer'),
                child: AnimatedBuilder(
                  animation: _shimmer,
                  builder: (context, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1 + 3 * _shimmer.value - 1, -0.3),
                        end: Alignment(3 * _shimmer.value - 1, 0.3),
                        colors: [
                          AppStyles.champagneLight.withValues(alpha: 0),
                          AppStyles.champagneLight.withValues(alpha: 0.6),
                          AppStyles.champagneLight.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      if (widget.websiteUrl.trim().isNotEmpty) ...[
        const SizedBox(width: 8),
        _action(label: 'Website', icon: Icons.language, on: false, onTap: widget.onWebsite),
      ],
    ]);
  }
}

/// Shown once a vendor is the couple's YES for its category.
class YesNote extends StatelessWidget {
  final String category;
  final VoidCallback? onAddToBudget;
  const YesNote({required this.category, required this.onAddToBudget, super.key});

  @override
  Widget build(BuildContext context) => Container(
        color: AppStyles.blush,
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(children: [
          const Icon(Icons.diamond, size: 15, color: AppStyles.plum),
          const SizedBox(width: 8),
          Expanded(child: Text('Your YES for $category', style: AppStyles.body(13, color: AppStyles.plumInk, weight: FontWeight.w500))),
          if (onAddToBudget != null)
            StationeryButton(label: 'Add to budget', compact: true, onPressed: onAddToBudget),
        ]),
      );
}

// ---------------------------------------------------------------- facts

/// Big Playfair numbers for the facts every couple checks first.
class AtAGlance extends StatelessWidget {
  final List<GlanceItem> items;
  const AtAGlance({required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppStyles.champagne)),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppStyles.champagne.withValues(alpha: 0.6))),
        child: IntrinsicHeight(
          child: Row(children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const VerticalDivider(width: 1, thickness: 1, color: AppStyles.champagne),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(items[i].value, textAlign: TextAlign.center, style: AppStyles.display(items[i].value.length > 12 ? 17 : 24)),
                    const SizedBox(height: 4),
                    Text(items[i].label.toUpperCase(), textAlign: TextAlign.center, style: AppStyles.eyebrow(size: 8.5, color: AppStyles.inkSoft)),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Label-over-value rows for the type-specific details.
class DetailsList extends StatelessWidget {
  final List<DetailItem> items;
  const DetailsList({required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final d in items)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEFE7DC)))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.label.toUpperCase(), style: AppStyles.eyebrow(size: 9, color: AppStyles.inkSoft)),
            const SizedBox(height: 3),
            Text(d.value, style: AppStyles.body(14.5, weight: FontWeight.w500)),
          ]),
        ),
    ]);
  }
}

// ---------------------------------------------------------------- included

IconData _iconFor(String? name) => amenityIcon(name) ?? amenityFallbackIcon;

/// Amenities as a printed menu card: double border, grouped, fine-line icons.
class IncludedCard extends StatelessWidget {
  final List<IncludedGroup> groups;
  const IncludedCard({required this.groups, super.key});

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppStyles.goldLine)),
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppStyles.champagne)),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(text: "What's ", style: AppStyles.display(24)),
              TextSpan(text: 'included', style: AppStyles.display(24, color: AppStyles.plum, italic: true)),
            ]),
            textAlign: TextAlign.center,
          ),
          for (final g in groups) ...[
            const SizedBox(height: 18),
            if (g.title != null)
              Container(
                padding: const EdgeInsets.only(bottom: 6),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppStyles.champagne))),
                child: Text(g.title!.toUpperCase(), style: AppStyles.eyebrow(size: 9)),
              ),
            LayoutBuilder(builder: (context, c) {
              final colWidth = c.maxWidth >= 360 ? (c.maxWidth - 14) / 2 : c.maxWidth;
              return Wrap(spacing: 14, runSpacing: 10, children: [
                for (final item in g.items)
                  SizedBox(
                    width: colWidth,
                    child: Row(children: [
                      Icon(_iconFor(item.iconName), size: 18, color: AppStyles.plum),
                      const SizedBox(width: 9),
                      Expanded(child: Text(item.label, style: AppStyles.body(13.5))),
                    ]),
                  ),
              ]);
            }),
          ],
        ]),
      ),
    );
  }
}

/// The top three included items as round icons near the top of the page.
class HighlightMedallions extends StatelessWidget {
  final List<IncludedItem> items;
  const HighlightMedallions({required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    final shown = items.take(3).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in shown)
          Expanded(
            child: Column(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppStyles.goldLine),
                  boxShadow: const [
                    BoxShadow(color: AppStyles.cream, spreadRadius: 3),
                    BoxShadow(color: AppStyles.champagne, spreadRadius: 4),
                  ],
                ),
                child: Icon(_iconFor(item.iconName), size: 22, color: AppStyles.plum),
              ),
              const SizedBox(height: 10),
              Text(item.label, textAlign: TextAlign.center, style: AppStyles.body(11.5, color: AppStyles.inkSoft, weight: FontWeight.w500)),
            ]),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- photos

/// One tall arched photo beside two smaller ones.
class PhotoMosaic extends StatelessWidget {
  final List<String> images;
  final Widget Function(String url) imageBuilder;
  const PhotoMosaic({required this.images, required this.imageBuilder, super.key});

  @override
  Widget build(BuildContext context) {
    if (images.length < 3) return const SizedBox.shrink();
    return SizedBox(
      height: 300,
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          flex: 6,
          child: ClipRRect(
            key: const ValueKey('mosaic-arch'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(999)),
            child: imageBuilder(images[0]),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: ClipRect(child: imageBuilder(images[1]))),
            const SizedBox(height: 8),
            Expanded(child: ClipRect(child: imageBuilder(images[2]))),
          ]),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- reviews

/// The newest written review, set large in italic like a magazine quote.
class ReviewPullQuote extends StatelessWidget {
  final Map<String, dynamic> review;
  const ReviewPullQuote({required this.review, super.key});

  @override
  Widget build(BuildContext context) {
    final rating = (review['rating'] as num?)?.round().clamp(0, 5) ?? 0;
    final name = (review['userName'] ?? '').toString().trim();
    return Container(
      width: double.infinity,
      color: AppStyles.blush,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < rating; i++) const Icon(Icons.star, size: 16, color: AppStyles.goldLine),
        ]),
        const SizedBox(height: 12),
        Text('“${review['comment'].toString().trim()}”',
            textAlign: TextAlign.center, style: AppStyles.display(21, italic: true).copyWith(height: 1.4)),
        if (name.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(name.toUpperCase(), style: AppStyles.eyebrow(size: 9.5)),
        ],
      ]),
    );
  }
}
