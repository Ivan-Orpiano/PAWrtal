import 'package:capstone_app/mobile/super_admin/WebVersion/vet_clinic_pages/vet_clinic_components/vet_services.dart';
import 'package:flutter/material.dart';

class VetProfileServices extends StatefulWidget {
  const VetProfileServices({super.key});

  @override
  State<VetProfileServices> createState() => _VetProfileServicesState();
}

class _VetProfileServicesState extends State<VetProfileServices> {
  @override
  Widget build(BuildContext context) {
    return  GridView.count(
      crossAxisCount: 2, 
      mainAxisSpacing: 12, 
      crossAxisSpacing: 12, 
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 10,
      children: const [
        VetServices(),
        VetServices(),
        VetServices(),
        VetServices(),
        VetServices(),
        VetServices(),
        VetServices(),
        VetServices(),
      ],
    );
  }
}