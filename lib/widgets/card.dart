import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../utils/image_utils.dart';

/// A vendor in a list: a wide photo with Love and YES on it, then the city,
/// the name in Playfair and a two-line description.
class CustomCard extends StatefulWidget {
  final String title;
  final String description;
  final String imageUrl;

  /// Shown in small capitals above the name, usually the vendor's city.
  final String subtitle;
  final VoidCallback? onTap;
  final bool isHearted;
  final bool isDiamonded;
  final Function(bool)? onHeartToggled;
  final Function(bool)? onDiamondToggled;

  const CustomCard({
    required this.title,
    required this.description,
    required this.imageUrl,
    this.subtitle = '',
    this.onTap,
    required this.isHearted,
    required this.isDiamonded,
    this.onHeartToggled,
    this.onDiamondToggled,
    super.key,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  bool _hover = false;

  Widget _placeholder({bool keyed = false}) => DecoratedBox(
        key: keyed ? const ValueKey('card-photo-placeholder') : null,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppStyles.blush, AppStyles.champagneLight],
          ),
        ),
        child: const Center(child: Icon(Icons.photo_camera_outlined, color: AppStyles.rose)),
      );

  Widget _chip(IconData icon, VoidCallback onTap, String label) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.white.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(icon, size: 18, color: AppStyles.plum),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageUrl.trim().isNotEmpty;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                ClipRect(
                  child: AnimatedScale(
                    scale: _hover ? 1.03 : 1,
                    duration: const Duration(milliseconds: 400),
                    child: hasImage
                        ? Image.network(
                            supabaseThumb(widget.imageUrl, width: 700),
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(keyed: true),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _chip(widget.isHearted ? Icons.favorite : Icons.favorite_border,
                        () => widget.onHeartToggled?.call(!widget.isHearted), widget.isHearted ? 'Loved' : 'Love'),
                    const SizedBox(width: 6),
                    _chip(widget.isDiamonded ? Icons.diamond : Icons.diamond_outlined,
                        () => widget.onDiamondToggled?.call(!widget.isDiamonded), 'YES'),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (widget.subtitle.trim().isNotEmpty && widget.subtitle != 'Unknown')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(widget.subtitle.trim().toUpperCase(),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: AppStyles.eyebrow(size: 9)),
                  ),
                Text(widget.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppStyles.display(18)),
                if (widget.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(widget.description,
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: AppStyles.body(12.5, color: AppStyles.inkSoft)),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
