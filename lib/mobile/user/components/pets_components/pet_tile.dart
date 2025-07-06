import 'package:capstone_app/mobile/user/components/pets_components/pets_controller.dart';
import 'package:capstone_app/mobile/user/pages/pets_next_page.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:get/get.dart';

class MyPetTile extends StatelessWidget {
  final Pet pet;
  const MyPetTile({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PetsNextPage(pet: pet),
          ),
        );

        if (result == true) {
          // Refresh the pet list after deletion or edit
          Get.find<PetsController>().fetchPets();
        }
      },
      child: SizedBox(
        height: 200,
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: Container(
            width: 160,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 81, 115, 153),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: Image.network(
                    pet.image ?? 'https://via.placeholder.com/150',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(pet.breed, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
