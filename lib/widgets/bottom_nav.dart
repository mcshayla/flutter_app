import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class BottomNav extends StatelessWidget {

  // final VoidCallback onAITap;
  final VoidCallback onExploreTap;
  final VoidCallback onLovedTap;
  final VoidCallback onYesTap;

  const BottomNav({ required this.onExploreTap, required this.onLovedTap, required this.onYesTap//the super key being the id from the database for the venue or whatever
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      height: 60,
      // color: const Color.fromARGB(235, 195, 112, 141),
      // color: const Color.fromARGB(235, 65, 24, 38),
      color: const Color.fromARGB(255, 174, 176, 129),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.home_outlined,  color: Colors.white),
            onPressed: onExploreTap
          ),
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.white),
            onPressed: onLovedTap,
          ),
          IconButton(
            icon: Image.asset('assets/diamond_ring.png',
              width: 26,
              height: 26,
              color: Colors.white
            ),
            onPressed: onYesTap, // your callback
          )
        ],)
    );
  }
}