import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_styles.dart';

/// One labelled fact about a vendor: "BASE PRICE" over "$4,500".
///
/// [onTap] is set for the facts that are really links (email, phone, website);
/// those render in plum and underlined so it is obvious they do something.
class SpecEntry {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const SpecEntry(this.label, this.value, {this.onTap});

  bool get isLink => onTap != null;
}

/// The elevated surface every block on the vendor page shares.
///
/// One widget rather than a style repeated at each call site: the vendor page
/// has a desktop layout and a mobile layout that historically drifted apart
/// (amenities rendered on one and not the other), so the surface is defined
/// once and both layouts ask for it.
class ElevatedPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const ElevatedPanel({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
    this.margin = const EdgeInsets.only(bottom: 24),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppStyles.primaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppStyles.accentColor.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyles.darkWords.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// The small-caps heading shared by every section on the vendor page.
class SectionHeading extends StatelessWidget {
  final String text;
  const SectionHeading(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: AppStyles.darkWords,
        ),
      );
}

/// A block of [SpecEntry]s on an [ElevatedPanel].
///
/// Wide layouts flow the entries into columns; narrow ones stack them. Empty
/// entries are the caller's problem — this renders whatever it is given, and
/// renders nothing at all when given an empty list.
class SpecCard extends StatelessWidget {
  final List<SpecEntry> entries;
  final bool isWide;

  /// Optional heading above the block.
  final String? heading;

  const SpecCard({
    required this.entries,
    this.isWide = false,
    this.heading,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return ElevatedPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading != null) ...[
            SectionHeading(heading!),
            const SizedBox(height: 16),
          ],
          if (isWide)
            Wrap(
              spacing: 48,
              runSpacing: 22,
              children:
                  entries.map((e) => _entry(e, constrained: true)).toList(),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  _entry(entries[i]),
                  if (i != entries.length - 1) const SizedBox(height: 18),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _entry(SpecEntry entry, {bool constrained = false}) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          entry.label.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppStyles.secondaryColor.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: entry.onTap,
          child: Text(
            entry.value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: entry.isLink
                  ? AppStyles.secondaryColor
                  : AppStyles.darkWords,
              decoration:
                  entry.isLink ? TextDecoration.underline : TextDecoration.none,
              decorationColor:
                  entry.isLink ? AppStyles.secondaryColor : null,
            ),
          ),
        ),
      ],
    );

    // On wide layouts the columns need a ceiling or one long value stretches
    // the whole row; on narrow ones the value should use the full width.
    return constrained
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: content,
          )
        : content;
  }
}
