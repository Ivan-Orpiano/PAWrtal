import 'package:capstone_app/web/dimensions.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_dashboard_tile.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:flutter/material.dart';

class WebDashboardGridTile extends StatefulWidget {
  final List<Clinic> clinics;

  const WebDashboardGridTile({super.key, required this.clinics});

  @override
  State<WebDashboardGridTile> createState() => _WebDashboardGridTileState();
}

class _WebDashboardGridTileState extends State<WebDashboardGridTile> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileWidth) {
          return LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = constraints.maxWidth;
              const double spacing = 25;
              const double minTileWidth = 200;
              int tilesPerRow =
                  (screenWidth / (minTileWidth + spacing)).floor();
              tilesPerRow = tilesPerRow.clamp(1, 1);
              double tileWidth =
                  (screenWidth - (spacing * (tilesPerRow - 1))) / tilesPerRow;

              return Wrap(
                spacing: spacing,
                runSpacing: 10,
                children: widget.clinics
                    .map((clinic) => WebDashboardTile(
                          clinic: clinic,
                          tileWidth: tileWidth,
                          tileHeight: tileWidth * 0.8,
                        ))
                    .toList(),
              );
            },
          );
        } else {
          return LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = constraints.maxWidth;
              const double spacing = 25;
              const double minTileWidth = 200;
              int tilesPerRow =
                  (screenWidth / (minTileWidth + spacing)).floor();
              tilesPerRow = tilesPerRow.clamp(1, 7);
              double tileWidth =
                  (screenWidth - (spacing * (tilesPerRow - 1))) / tilesPerRow;

              return Wrap(
                spacing: spacing,
                runSpacing: 10,
                children: widget.clinics
                    .map((clinic) => WebDashboardTile(
                          clinic: clinic,
                          tileWidth: tileWidth,
                        ))
                    .toList(),
              );
            },
          );
        }
      },
    );
  }
}
