import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/mobile/user/pages/dashboard_next_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyDashboardTile extends StatelessWidget {
  final Clinic clinic;

  const MyDashboardTile({super.key, required this.clinic});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // You can also pass the clinic to the next page if needed
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardNextPage(clinic: clinic),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 350,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              blurRadius: 1,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic clinic image
            Container(
              height: 220,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: clinic.image.isNotEmpty
                    ? Image.network(
                        clinic.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Image.asset(
                        'lib/images/test_image.jpg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
              ),
            ),

            // Dynamic clinic name
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 10, bottom: 5),
              child: Text(
                clinic.clinicName,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: const Color.fromARGB(255, 81, 115, 153),
                ),
              ),
            ),

            // Dynamic clinic address
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 5),
              child: Text(
                clinic.address,
                style: GoogleFonts.dmSans(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
              ),
            ),

            // Placeholder info (rooms, vet count, rating)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.house_outlined),
                      const SizedBox(width: 3),
                      Text("4 Rooms", style: GoogleFonts.dmSans(fontSize: 16)),
                      const SizedBox(width: 20),
                      const Icon(Icons.medical_services),
                      const SizedBox(width: 3),
                      Text("1 Veterinarian",
                          style: GoogleFonts.dmSans(fontSize: 16)),
                    ],
                  ),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow),
                      SizedBox(width: 3),
                      Text("5.0"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
