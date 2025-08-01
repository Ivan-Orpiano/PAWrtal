// import 'package:flutter/material.dart';

// class AcceptedTile extends StatelessWidget {
//   const AcceptedTile({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 10),
//       child: Container(
//         width: MediaQuery.of(context).size.width,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(25),
//         ),
//         child: Row(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(70),
//                     child: const Image(
//                       image: AssetImage('lib/images/pfp.jpg'),
//                       height: 60,
//                       width: 60,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const Padding(
//               padding: EdgeInsets.only(left: 10, top: 10, bottom: 10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Padding(
//                     padding: EdgeInsets.only(bottom: 2),
//                     child: Text(
//                       'Pet Owner 1',
//                       style: TextStyle(
//                         color: Color.fromARGB(255, 81, 115, 153),
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                   Text(
//                     'December 32, 8080',
//                     style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 12,
//                     ),
//                   ),
//                   Text(
//                     'Pet: Kongwu',
//                     style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 12,
//                     ),
//                   ),
//                   Text(
//                     'Breed: Macaque',
//                     style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 12,
//                     ),
//                   ),
//                   Text(
//                     'Service: Training',
//                     style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
