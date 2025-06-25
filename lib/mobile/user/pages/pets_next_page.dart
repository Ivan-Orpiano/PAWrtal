import 'package:flutter/material.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:google_fonts/google_fonts.dart';

class PetsNextPage extends StatelessWidget {
  final Pet pet;

  const PetsNextPage({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 81, 115, 153),
        title: Text(
          pet.name,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left_rounded),
          iconSize: 30,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        color: const Color.fromARGB(255, 248, 253, 255),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  pet.image ?? 'https://via.placeholder.com/150',
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 80),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text("Breed: ${pet.breed}",
                style: GoogleFonts.inter(fontSize: 18)),
            Text("Type: ${pet.type}",
                style: GoogleFonts.inter(fontSize: 18)),
            Text("Color: ${pet.color}",
                style: GoogleFonts.inter(fontSize: 18)),
            Text("Weight: ${pet.weight} kg",
                style: GoogleFonts.inter(fontSize: 18)),
            const SizedBox(height: 10),
            if (pet.notes != null && pet.notes!.isNotEmpty)
              Text("Notes: ${pet.notes}",
                  style: GoogleFonts.inter(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
