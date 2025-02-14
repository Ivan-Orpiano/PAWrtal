import 'package:capstone_app/user/components/pets_components/floating_action_button.dart';
import 'package:capstone_app/user/components/pets_components/pet_tile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PetsPage extends StatefulWidget {
  const PetsPage({super.key});

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body:  Padding(
      //   padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      //   child: SingleChildScrollView(
      //     child: Wrap(
      //       direction: Axis.horizontal,
      //       spacing: 30,
      //       runSpacing: 20,
      //       children: [
      //         MyPetTile(),
      //         MyPetTile(),
      //         MyPetTile(),
      //       ],
      //     ),
      //   ),
      // ),
      // floatingActionButton: MyFabPets(
      // ),
      backgroundColor: Colors.blue.shade50,
      body: Column(
        children: [
          SizedBox(
            height: 75,
            child: Center(
              child: Text(
                "Pets",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 20
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.maxFinite,
              height: double.maxFinite,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 230, 230, 230),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: ListView(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 10, bottom: 20),
                        child: Text(
                          "Your pets",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 22
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16, top: 10, bottom: 20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 81, 115, 153),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade400,
                                spreadRadius: 2,
                                blurRadius: 3,
                                offset: const Offset(0, 2)
                              )
                            ]
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.filter_list_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      )
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: SingleChildScrollView(
                      child: Wrap(
                        direction: Axis.horizontal,
                        spacing: 20,
                        runSpacing: 30,
                        children: [
                          MyPetTile(),
                          MyPetTile(),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const MyFabPets(),
    );
  }
}