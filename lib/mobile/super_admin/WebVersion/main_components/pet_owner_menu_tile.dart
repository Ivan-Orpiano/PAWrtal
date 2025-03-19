import 'package:capstone_app/mobile/super_admin/WebVersion/pet_owners_pages/verification_owner.dart';
import 'package:flutter/material.dart';

class PetOwnerTile extends StatelessWidget {
  const PetOwnerTile({super.key});
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
                builder: (context) => const VerificationOwner(),
              ),
            ),
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
                height: 650,
                width: 460,
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
                          'lib/images/user_profile.png',
                          height: screenHeight * 0.4,
                          width: screenWidth * 0.3,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Pet Owners',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )))));
  }
}
