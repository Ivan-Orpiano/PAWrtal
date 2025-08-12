import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/super_ad_vet_clinic_dashboard.dart';
import 'package:flutter/material.dart';

class VetClinicTile extends StatelessWidget {
  const VetClinicTile({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return InkWell(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SuperAdminVetClinic(),
            )),
        child: Padding(
            padding: const EdgeInsets.all(5),
            child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                width: MediaQuery.of(context).size.width * 0.8,
                child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(81, 115, 153, 0.8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'lib/images/vet_clinic_icon.png',
                          fit: BoxFit.cover,
                        ),
                        //const SizedBox(height: 10),
                        const Text(
                          'Veterinary Clinic',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )))));
  }
}
