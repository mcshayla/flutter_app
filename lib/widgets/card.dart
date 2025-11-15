import 'package:flutter/material.dart';

class CustomCard extends StatefulWidget {

  final String title;
  final String description;
  final String imageUrl;
  final VoidCallback? onTap;
  final bool isHearted;
  final bool isDiamonded;
  // final bool initialHearted;
  // final bool initialDiamonded;
  final Function(bool)? onHeartToggled;

  const CustomCard({
    required this.title, required this.description, required this.imageUrl, this.onTap, required this.isHearted, required this.isDiamonded, this.onHeartToggled, super.key //the super key being the id from the database for the venue or whatever
  });

  @override
  State<CustomCard> createState() => _CustomCardState();

}

class _CustomCardState extends State<CustomCard> {
  // late bool isHearted;
  // late bool isDiamonded;

  // @override
  // void initState() {
  //   // super.initState();
  //   // isHearted = widget.initialHearted;
  //   // isDiamonded = widget.initialDiamonded;
  // }

  // // void _toggleHeart() {
  //   setState(() {
  //     isHearted = !isHearted;
  //   });

  //   if (widget.onHeartToggled != null) {
  //     widget.onHeartToggled!(isHearted);
  //   }
  // }

  // void _toggleDiamond() {
  //   setState(() {
  //     isDiamonded = !isDiamonded;
  //   });

  //   //TODO: udpate database for diamonded.
  // }

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
            // crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded( 
                child: Stack (
                fit: StackFit.expand,
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
                          IconButton(
                            icon: Icon(
                              widget.isHearted ? Icons.favorite : Icons.favorite_border,
                              color: widget.isHearted ? Color(0xFFDCC7AA) : Color(0xFFDCC7AA),
                            ),
                            onPressed: () {
                              if (widget.onHeartToggled != null) widget.onHeartToggled!(!widget.isHearted);
                            },
                          ),
                        IconButton(
                            icon: Icon(
                              widget.isDiamonded ? Icons.diamond : Icons.diamond_outlined,
                              color: widget.isDiamonded ? Color(0xFFDCC7AA) : Color(0xFFDCC7AA),
                            ),
                            onPressed: () {
                              // if (widget.onHeartToggled != null) widget.onHeartToggled!(!widget.isHearted);
                            },
                          )
                          // GestureDetector(           
                          //   // onTap: _toggleHeart,
                          //   child: Icon(isHearted ? Icons.favorite : Icons.favorite_border,
                          //   color: Color(0xFFDCC7AA),
                          //   size: 24,
                          //   ),
                          // ),
                          // SizedBox(width: 8),
                          // GestureDetector(
                          //   // onTap: _toggleDiamond,
                          //   child: Icon(
                          //     isDiamonded ? Icons.diamond : Icons.diamond_outlined,
                          //     color: Color(0xFFDCC7AA),
                          //     size: 24,
                          //   ),
                          // ),
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