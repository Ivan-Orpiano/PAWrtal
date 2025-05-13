import 'package:capstone_app/web/user_web/pages/web_maps.dart';
import 'package:flutter/material.dart';

class WebClinicLocation extends StatefulWidget {
  const WebClinicLocation({super.key});

  @override
  State<WebClinicLocation> createState() => _WebClinicLocationState();
}

class _WebClinicLocationState extends State<WebClinicLocation> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 380),
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