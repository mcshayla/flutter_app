import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Opens a vendor's photos full screen, starting at [initialIndex].
///
/// Swipe, the on-screen arrows or the keyboard arrows move between photos;
/// Esc, the close button or tapping the dark backdrop closes it. Pinch or
/// scroll-zoom works on each photo.
Future<void> showPhotoLightbox(BuildContext context, List<String> images, {int initialIndex = 0}) {
  if (images.isEmpty) return Future.value();
  return Navigator.of(context).push(PageRouteBuilder(
    opaque: false,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    pageBuilder: (_, __, ___) => PhotoLightbox(
      images: images,
      initialIndex: initialIndex.clamp(0, images.length - 1),
    ),
    transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
  ));
}

class PhotoLightbox extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const PhotoLightbox({required this.images, this.initialIndex = 0, super.key});

  @override
  State<PhotoLightbox> createState() => _PhotoLightboxState();
}

class _PhotoLightboxState extends State<PhotoLightbox> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final target = _index + delta;
    if (target < 0 || target >= widget.images.length) return;
    _controller.animateToPage(target, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
      _go(1);
    } else if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _go(-1);
    } else if (e.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Widget _arrow(IconData icon, VoidCallback onTap, String label) => Material(
        color: Colors.white.withValues(alpha: 0.15),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: label,
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white, size: 28),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final count = widget.images.length;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Stack(children: [
            PageView.builder(
              controller: _controller,
              itemCount: count,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => GestureDetector(
                // Taps on the empty space around a photo close the viewer.
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 56),
                  child: InteractiveViewer(
                    maxScale: 4,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {}, // a tap on the photo itself does not close
                        child: Image.network(
                          widget.images[i],
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, progress) => progress == null
                              ? child
                              : const Center(child: CircularProgressIndicator(color: Colors.white)),
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                key: const ValueKey('lightbox-close'),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
            if (count > 1)
              Positioned(
                top: 18,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Text(
                    '${_index + 1} / $count',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, letterSpacing: 0.8),
                  ),
                ),
              ),
            if (_index > 0)
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(child: _arrow(Icons.chevron_left, () => _go(-1), 'Previous photo')),
              ),
            if (_index < count - 1)
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(child: _arrow(Icons.chevron_right, () => _go(1), 'Next photo')),
              ),
          ]),
        ),
      ),
    );
  }
}
