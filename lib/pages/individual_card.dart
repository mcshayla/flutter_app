import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:say_yes/utils/string_extensions.dart';
import '../appstate.dart';
import 'package:provider/provider.dart';
import '../utils/app_styles.dart';
class IndividualCard extends StatefulWidget {

  final String title;
  final String description;
  final String imageUrl;
  final String style_keywords;
  final String location;
  final String address;
  final String vendor_estimated_price;
  final String vendor_price;
  final String contact_email;
  final String contact_phone;
  final String website_url;
  final String vendor_id;
  final String category;
  // final VoidCallback? onTap;
  final bool isHearted;
  final bool isDiamonded;
  final Function(bool)? onHeartToggled;
  final Function(bool)? onDiamondToggled;

  const IndividualCard({
    required this.category, required this.vendor_id, required this.title, required this.description, required this.imageUrl, required this.style_keywords, required this.location, required this.address, required this.vendor_estimated_price,required this.vendor_price, required this.contact_email, required this.contact_phone, required this.website_url, required this.isHearted, required this.isDiamonded, this.onHeartToggled, this.onDiamondToggled, super.key //the super key being the id from the database for the venue or whatever
  });

  @override
  State<IndividualCard>createState() => _CustomCardState();

}

class _CustomCardState extends State<IndividualCard> {

  @override
  Widget build(BuildContext context) {
    final details = [
            ['Style Keywords', widget.style_keywords],
            ['Description', widget.description],
            ['Estimated Price', widget.vendor_estimated_price],
            ['Base Price', widget.vendor_price],
            ['Location', widget.location],
            ['Address', widget.address],
            ['Email', widget.contact_email],
            ['Phone', widget.contact_phone],
            ['Website', widget.website_url]
          ];
    final appState = Provider.of<AppState>(context);
    final isHearted = appState.lovedVendorUUIDsCategorizedMap[widget.category]?.contains(widget.vendor_id) ?? false;
    final isDiamonded = appState.diamondedCards[widget.category.lowerCase()] == widget.vendor_id;
    return Consumer<AppState>(
      builder:(context, appState, child) {
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (Navigator.canPop(context))
                Row( 
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text("Back",
                    style: AppStyles.backButton
                    
                    )
                  ]
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 300, // <-- your max height here
                ),
                child: Image.network(
                  widget.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.network(
                      "https://picsum.photos/200/300",
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(
                top: 36.0,
                left: 36.0,
                right: 36.0,
                bottom: 0.0, // no padding at the bottom
              ),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                child:Text(widget.title, softWrap: true,               // allow wrapping
                  overflow: TextOverflow.visible, 
                  style: GoogleFonts.bodoniModa(
                  fontSize: 26, 
                  fontWeight: FontWeight.w600, // Medium to Semi-Bold for impact
                  letterSpacing: 2.0, // A little spacing for elegance
                  color: const Color(0xFF7B3F61)
                )),),
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isHearted ? Icons.favorite : Icons.favorite_border,
                        color: isHearted ? Color(0xFFDCC7AA) : Color(0xFFDCC7AA),
                      ),
                      onPressed: () {
                        if (widget.onHeartToggled != null) widget.onHeartToggled!(!isHearted);
                      },
                    ),
                  IconButton(
                    padding: EdgeInsets.zero,
                      icon: Icon(
                        isDiamonded ? Icons.diamond : Icons.diamond_outlined,
                        color: isDiamonded ? Color(0xFFDCC7AA) : Color(0xFFDCC7AA),
                      ),
                      onPressed: () {
                          if (widget.onDiamondToggled != null) widget.onDiamondToggled!(!isDiamonded);
                      },
                    )
                  ],
                )
              ],)
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 10.0,
                left: 38.0,
                right: 36.0,
                bottom: 10.0, // no padding at the bottom
              ),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                details
                  .where((item) => item[1] != null && item[1].trim().isNotEmpty && item[1] != "Unknown")
                  .map((item) {
                final detailTitle = item[0];
                final value = item[1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "$detailTitle: ",
                          // style: const TextStyle(
                          //   fontWeight: FontWeight.bold,
                          //   fontSize: 14,
                          //   ),
                          style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0
                          )
                        ),
                        Expanded(
                          child:
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6E6E6E),
                          ),
                          softWrap: true,
                        ),
                        ),
                      ],
                  ));
                  }
              ).toList()
            ),
            ),
            ],
          )
        ),

      );
        }
    );
  }
}