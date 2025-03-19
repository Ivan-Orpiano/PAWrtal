import 'package:capstone_app/mobile/user/pages/pets_next_page.dart';
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

class MyPetTile extends StatelessWidget {
  const MyPetTile ({super.key});

  @override
  Widget build(BuildContext context) {
    return
    InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PetsNextPage(),
          ),
        );
      },
      child: SizedBox(
        height: 200,
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30)
          ),
          child: Container(
            width: 160,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 81, 115, 153),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: Image.asset(
                    'lib/images/dogimage.jpg',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        "David",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        "Doggy Dog",
                        style: TextStyle(
                          fontSize: 16
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );

    // InkWell(
    //   onTap: () {
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => const PetsNextPage()
    //       )
    //     );
    //   },
    //   child: Container(
    //     width: 175,
    //     height: 220,
    //     decoration: BoxDecoration(
    //       borderRadius: BorderRadius.circular(30),
    //       color: Colors.white,
    //       boxShadow: [
    //         BoxShadow(
    //           color: Colors.grey.shade400,
    //           spreadRadius: 2,
    //           blurRadius: 3,
    //           offset: const Offset(0, 2)
    //         )
    //       ]
    //     ),
    //     child: Column(
    //       children: [
    //         Row(
    //           children: [
    //             Padding(
    //               padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
    //               child: ClipRRect(
    //                 borderRadius: BorderRadius.circular(30),
    //                 child: Image.asset(
    //                   'lib/images/pfp.jpg',
    //                   width: 60,
    //                   height: 60,
    //                 ),
    //               ),
    //             )
    //           ],
    //         ),
    //         Row(
    //           children: [
    //             Padding(
    //               padding: const EdgeInsets.only(left: 8),
    //               child: Text(
    //                 "David",
    //                 style: GoogleFonts.inter(
    //                   fontWeight: FontWeight.w600,
    //                   fontSize: 18,
    //                   color: const Color.fromARGB(255, 81, 115, 153)
    //                 ),
    //               ),
    //             )
    //           ],
    //         ),
    //         Row(
    //           children: [
    //             const SizedBox(
    //               width: 10,
    //             ),
    //             Column(
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: [
    //                 Text(
    //                   "David",
    //                   style: GoogleFonts.inter(
    //                     fontSize: 14,
    //                     fontWeight: FontWeight.w400
    //                   ),
    //                 ),
    //                 Row(
    //                   children: [
    //                     Text(
    //                       "Man",
    //                       style: GoogleFonts.inter(
    //                         fontSize: 14,
    //                         fontWeight: FontWeight.w400
    //                       ),
    //                     ),
    //                     Icon(
    //                       Icons.male_rounded,
    //                       size: 14,
    //                     )
    //                   ],
    //                 )
    //               ],
    //             ),
    //             SizedBox(
    //               width: 40,
    //             ),
    //             Column(
    //               crossAxisAlignment: CrossAxisAlignment.center,
    //               children: [
    //                 Text(
    //                   "built diff",
    //                   style: GoogleFonts.inter(
    //                     fontSize: 14,
    //                     fontWeight: FontWeight.w400
    //                   ),
    //                 ),
    //                 Text(
    //                   "heavy",
    //                   style: GoogleFonts.inter(
    //                     fontSize: 14,
    //                     fontWeight: FontWeight.w400
    //                   ),
    //                 )
    //               ],
    //             ),
    //           ],
    //         )
    //       ],
    //     ),
    //   ),
    // );
  }
}