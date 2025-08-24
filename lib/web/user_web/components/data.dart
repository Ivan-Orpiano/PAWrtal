// import 'package:capstone_app/web/dimensions.dart';
// import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_dashboard_tile.dart';
// import 'package:flutter/material.dart';

// class DashboardTiles extends StatefulWidget {
//   const DashboardTiles({super.key});

//   @override
//   State<DashboardTiles> createState() => _DashboardTilesState();
// }

// class _DashboardTilesState extends State<DashboardTiles> {
//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//         builder: (context, constraints) {
//         if (constraints.maxWidth < mobileWidth ) {
//           return LayoutBuilder(
//               builder: (context, constraints) {
//               double screenWidth = constraints.maxWidth;
//               const double spacing = 25;
//               const double minTileWidth = 200;
//               int tilesPerRow = (screenWidth / (minTileWidth + spacing)).floor();
//               tilesPerRow = tilesPerRow.clamp(1, 1); 
//               double tileWidth = (screenWidth - (spacing * (tilesPerRow - 1))) / tilesPerRow;
//               return Wrap(
//                 spacing: spacing,
//                 runSpacing: 10,
//                 children: List.generate(7, (index) => WebDashboardTile(tileWidth: tileWidth, tileHeight: tileWidth * 0.8,),
//                 ),
//               );
//             },
//           );
//         //tablet body para mas smooth ewan ko kung paano diyan lang yan
//         // } else if (constraints.maxWidth < tabletWidth){
//         //   return LayoutBuilder(
//         //       builder: (context, constraints) {
//         //       double screenWidth = constraints.maxWidth;
//         //       const double spacing = 25;
//         //       const double minTileWidth = 200;
//         //       int tilesPerRow = (screenWidth / (minTileWidth + spacing)).floor();
//         //       tilesPerRow = tilesPerRow.clamp(1, 7); 
//         //       double tileWidth = (screenWidth - (spacing * (tilesPerRow - 1))) / tilesPerRow;
//         //       return Wrap(
//         //         spacing: spacing,
//         //         runSpacing: 10,
//         //         children: List.generate(7, (index) => WebDashboardTile(tileWidth: tileWidth),
//         //         ),
//         //       );
//         //     },
//         //   );
//         } else {
//           return LayoutBuilder(
//               builder: (context, constraints) {
//               double screenWidth = constraints.maxWidth;
//               const double spacing = 25;
//               const double minTileWidth = 200;
//               int tilesPerRow = (screenWidth / (minTileWidth + spacing)).floor();
//               tilesPerRow = tilesPerRow.clamp(1, 7); 
//               double tileWidth = (screenWidth - (spacing * (tilesPerRow - 1))) / tilesPerRow;
//               return Wrap(
//                 spacing: spacing,
//                 runSpacing: 10,
//                 children: List.generate(7, (index) => WebDashboardTileU(tileWidth: tileWidth),
//                 ),
//               );
//             },
//           );
//         }
//       },
//     );
//   }
// }