import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomCard extends StatefulWidget {

  final String title;
  final String description;
  final String imageUrl;
  final VoidCallback? onTap;
  final bool isHearted;
  final bool isDiamonded;
  final Function(bool)? onHeartToggled;
  final Function(bool)? onDiamondToggled;

  const CustomCard({
    required this.title, required this.description, required this.imageUrl, this.onTap, required this.isHearted, required this.isDiamonded, this.onHeartToggled, this.onDiamondToggled, super.key //the super key being the id from the database for the venue or whatever
  });

  @override
  State<CustomCard> createState() => _CustomCardState();

}

class _CustomCardState extends State<CustomCard> {

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 200;
    const double cardHeight = 240;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5F0),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2,2),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded( 
                child: Stack (
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    cacheWidth: 400,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.network(
                        "https://picsum.photos/200/300",
                        width: double.infinity,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        cacheWidth: 400,
                      );
                    }
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              widget.onHeartToggled?.call(!widget.isHearted);
                            },
                            child: Icon(
                              widget.isHearted ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: const Color(0xFF7B3F61),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              widget.onDiamondToggled?.call(!widget.isDiamonded);
                            },
                            child: Icon(
                              widget.isDiamonded ? Icons.diamond : Icons.diamond_outlined,
                              size: 20,
                              color: const Color(0xFF7B3F61),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ],
              ),
              ),
            Container(
                height: 84,
                padding: EdgeInsets.all(12),
                // child: Stack(
                  // children: [
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            // Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3E3E3E)), overflow: TextOverflow.ellipsis),
                            Text(widget.title, style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ), overflow: TextOverflow.ellipsis),
                            SizedBox(height: 4),
                            // Text(widget.description, overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFF6E6E6E)))
                            Text(
                              widget.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                                color: Color(0xFF6E6E6E)
                              ),
                            )

                          ],
                    ),   
              ),
            ],
          ),
        ),
      ),
    );
  }
}
