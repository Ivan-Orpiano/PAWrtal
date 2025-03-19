import 'package:capstone_app/mobile/user/pages/dashboard_next_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyDashboardTile extends StatelessWidget {
  const MyDashboardTile({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardNextPage(),
          )
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
              offset: const Offset(0, 2)
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // clinic image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'lib/images/test_image.jpg',
                  fit: BoxFit.fill,
                  width: double.infinity,
                ),
              ),
            ),
          
            // clinic name
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 10, bottom: 5),
              child: Text(
                "Qualipaws Animal Health Clinic",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: const Color.fromARGB(255, 81, 115, 153),
                ),
              ),
            ),
          
            // clinic address
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 5),
              child: Text(
                "Tungkong Mangga Rd, San Jose del Monte City, 3023 Bulacan",
                style: GoogleFonts.dmSans(
                  fontStyle: FontStyle.italic,
                  fontSize: 14
                ),
              ),
            ),
            // row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    // rooms
                      Row(
                        children: [
                          const Icon(Icons.house_outlined),
                          Padding(
                            padding: const EdgeInsets.only(left: 3, right: 20),
                            child: Text(
                              "4 Rooms",
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w400,
                                fontSize: 16
                              ),
                              
                              ),
                          ),
                          const Icon(Icons.medical_services),
                          Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Text(
                              "1 Veterinarian",
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w400,
                                fontSize: 16
                              ),
                              ),
                          ),
                        ],
                    ),
                    const Row(
                      children: [
                      Icon(
                        Icons.star,
                        color: Colors.yellow,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 3),
                        child: Text("5.0"),
                      ),
                    ] ,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}