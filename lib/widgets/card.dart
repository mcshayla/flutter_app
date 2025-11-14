import 'package:flutter/material.dart';

class CustomCard extends StatefulWidget {

  final String title;
  final String description;
  final String imageUrl;
  final VoidCallback? onTap;

  final bool initialHearted;
  final bool initialDiamonded;

  const CustomCard({
    required this.title, required this.description, required this.imageUrl, this.onTap, this.initialHearted = false, this.initialDiamonded = false, super.key //the super key being the id from the database for the venue or whatever
  });

  @override
  State<CustomCard> createState() => _CustomCardState();

}

class _CustomCardState extends State<CustomCard> {
  late bool isHearted;
  late bool isDiamonded;

  @override
  void initState() {
    super.initState();
    isHearted = widget.initialHearted;
    isDiamonded = widget.initialDiamonded;
  }

  void _toggleHeart() {
    setState(() {
      isHearted = !isHearted;
    });

    //TODO: update database
    //updateDatabaseForUser(userid, cardid, ishearted, is diamondedd)
  }

  void _toggleDiamond() {
    setState(() {
      isDiamonded = !isDiamonded;
    });

    //TODO: udpate database for diamonded.
  }

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
          // color: const Color.fromARGB(235, 111, 51, 72),
          color: const Color.fromARGB(255, 143, 96, 96),
          borderRadius: BorderRadius.circular(12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded( 
                child: Stack (
                children: [
                  Image.network(
                    "https://picsum.photos/200/300",
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned( 
                      top: 3,
                      right: 5,
                      child: Row( 
                        children: [
                          GestureDetector(
                            onTap: _toggleHeart,
                            child: Icon(isHearted ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                            size: 24,
                            ),
                          ),
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: _toggleDiamond,
                            child: Icon(
                              isDiamonded ? Icons.diamond : Icons.diamond_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
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
                            Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                            SizedBox(height: 4),
                            Text(widget.description, overflow: TextOverflow.ellipsis)
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

//   @override
//   Widget build(BuildContext context) {
//     const double cardWidth = 200;
//     const double cardHeight = 240;

//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: cardWidth,
//         height: cardHeight,
//         margin: EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           // color: const Color.fromARGB(235, 111, 51, 72),
//           color: const Color.fromARGB(255, 143, 96, 96),
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black26,
//               blurRadius: 4,
//               offset: Offset(2,2),
//             )
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Image.network(imageUrl, fit: BoxFit.cover,),
//               Expanded( 
//                 child: Image.network(
//                 "https://picsum.photos/200/300",
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//               ),
//               ),
//               Container(
//                 height: 84,
//                 padding: EdgeInsets.all(12),
//                 child: Stack()
//                 child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [

//                   Text(title, style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
//                   SizedBox(height: 4),
//                   Text(description, overflow: TextOverflow.ellipsis)
//                 ],))
//             ]

//           )
//         )
//       )

//     );
//   }
// }