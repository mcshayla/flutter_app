import 'package:flutter/material.dart';

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
                    cacheWidth: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.network(
                        "https://picsum.photos/200/300",
                        width: double.infinity,
                        fit: BoxFit.cover,
                        cacheWidth: 200,
                      );
                    }
                  ),
                  Positioned( 
                      top: 3,
                      right: 5,
                      child: Container( 
                        padding: EdgeInsets.zero,
                        margin: EdgeInsets.zero,
                        decoration: BoxDecoration( 
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              widget.isHearted ? Icons.favorite : Icons.favorite_border,
                              color: widget.isHearted ? Color(0xFFDCC7AA) : Color(0xFFDCC7AA),
                              // color: Color(0xFF7B3F61),
                            ),
                            onPressed: () {
                              if (widget.onHeartToggled != null) widget.onHeartToggled!(!widget.isHearted);
                            },
                          ),
                        IconButton(
                          padding: EdgeInsets.zero,
                            icon: Icon(
                              widget.isDiamonded ? Icons.diamond : Icons.diamond_outlined,
                              color: widget.isDiamonded ? Color(0xFFDCC7AA) : Color(0xFFDCC7AA),
                            ),
                            onPressed: () {
                               if (widget.onDiamondToggled != null) widget.onDiamondToggled!(!widget.isDiamonded);
                            },
                          )
                        ],
                      )),
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
                            Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3E3E3E)), overflow: TextOverflow.ellipsis),
                            SizedBox(height: 4),
                            Text(widget.description, overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFF6E6E6E)))
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
