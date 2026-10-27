import 'package:flutter/material.dart';
import '../utils/app_styles.dart';

/// The website's button family: square corners, letter-spaced capitals and a
/// thin second border offset outside the first, like letterpress stationery.
enum StationeryVariant { solid, plum, line }

class StationeryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final StationeryVariant variant;
  final IconData? icon;
  final bool expand;
  final bool compact;

  const StationeryButton({
    required this.label,
    required this.onPressed,
    this.variant = StationeryVariant.line,
    this.icon,
    this.expand = false,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final (Color? fill, Color edge, Color text, Color halo) = switch (variant) {
      StationeryVariant.solid => (AppStyles.champagne, AppStyles.champagne, AppStyles.plumInk, AppStyles.champagne),
      StationeryVariant.plum => (AppStyles.plum, AppStyles.plum, Colors.white, AppStyles.goldLine),
      StationeryVariant.line => (null, AppStyles.plumInk, AppStyles.plumInk, AppStyles.goldLine),
    };
    final enabled = onPressed != null;
    final pad = compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 9)
        : const EdgeInsets.symmetric(horizontal: 22, vertical: 14);

    final label = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: compact ? 13 : 15, color: text),
          const SizedBox(width: 7),
        ],
        Flexible(
          child: Text(
            this.label.toUpperCase(),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.eyebrow(size: compact ? 9.5 : 10.5, color: text),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: this.label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: DecoratedBox(
            // The outer hairline, offset from the face.
            decoration: BoxDecoration(border: Border.all(color: halo.withValues(alpha: 0.8), width: 1)),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onPressed,
                  child: DecoratedBox(
                    key: const ValueKey('stationery-face'),
                    decoration: BoxDecoration(
                      color: fill,
                      border: Border.all(color: edge, width: 1),
                    ),
                    child: Padding(padding: pad, child: label),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small letter-spaced capitals above a heading.
class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  final TextAlign? textAlign;
  const Eyebrow(this.text, {this.color = AppStyles.plum, this.textAlign, super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), textAlign: textAlign, style: AppStyles.eyebrow(color: color));
}

/// A thin rose rule with a small heart, the website's section divider.
class HeartRule extends StatelessWidget {
  final double width;
  const HeartRule({this.width = 220, super.key});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(child: Container(height: 1, color: AppStyles.rose));
    return SizedBox(
      width: width,
      child: Row(children: [
        line,
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.favorite_border, size: 13, color: AppStyles.rose),
        ),
        line,
      ]),
    );
  }
}
