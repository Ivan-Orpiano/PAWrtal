import 'package:capstone_app/super_admin/WebVersion/vet_clinic_pages/super_ad_vet_maps/vet_map.dart';
import 'package:flutter/material.dart';
// import 'package:capstone_app/super_admin/WebVersion/vet_clinic_pages/super_ad_vet_clinic_page.dart';

class VetProfileLocation extends StatefulWidget {
  const VetProfileLocation({super.key});

  @override
  State<VetProfileLocation> createState() => _VetProfileLocationState();
}

    double getResponsivePadding(double screenWidth) {
    const double minScreen = 1100;
    const double maxScreen = 1920;
    const double minPadding = 16;
    const double maxPadding = 380;

    if (screenWidth <= minScreen) return minPadding;
    if (screenWidth >= maxScreen) return maxPadding;

    double t = (screenWidth - minScreen) / (maxScreen - minScreen);
    return minPadding + t * (maxPadding - minPadding);
  }

class _VetProfileLocationState extends State<VetProfileLocation> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: getResponsivePadding(screenWidth)),
      child: Column(
        children: [
          const Row(
            children: [
              Text(
                "Location",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Text(
                "Exact address kung kaya",
                style: TextStyle(
                  fontSize: 18
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.maxFinite,
            height: 700,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const WebMaps(),
          )
        ],
      ),
    );
  }
}