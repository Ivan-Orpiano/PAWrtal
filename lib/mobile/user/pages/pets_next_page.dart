import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/mobile/user/pages/pet_card_creation.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class PetsNextPage extends StatelessWidget {
  final Pet pet;
  const PetsNextPage({super.key, required this.pet});

  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Pet"),
        content: const Text("Are you sure you want to delete this pet?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            child: const Text("Delete"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        await Get.find<AuthRepository>().deletePet(pet.documentId!);
        CustomSnackBar.showSuccessSnackBar(
          context: context,
          title: "Deleted",
          message: "${pet.name} has been removed.",
        );
        Get.back(); // Return to pet list
      } catch (e) {
        CustomSnackBar.showErrorSnackBar(
          context: context,
          title: "Error",
          message: "Failed to delete pet: $e",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 81, 115, 153),
        title: Text(pet.name,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PetCardCreation(existingPet: pet), // Pass existing pet
                  ),
                );

                if (result == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Pet updated successfully")),
                  );
                  Get.back(result: true); // To refresh list if you want
                }
              }),
          IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Delete Pet"),
                    content:
                        const Text("Are you sure you want to delete this pet?"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel")),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Delete")),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    //delete image if exists
                    if (pet.image != null && pet.image!.isNotEmpty) {
                      final imageId =
                          pet.image!.split('/files/')[1].split('/')[0];
                      await Get.find<AuthRepository>().deleteImage(imageId);
                    }

                    //delete pet
                    await Get.find<AuthRepository>().deletePet(pet.documentId!);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Pet deleted successfully")),
                    );

                    Get.back(result: true); // go back and signal refresh
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to delete pet: $e")),
                    );
                  }
                }
              }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    pet.image ?? 'https://via.placeholder.com/150',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 80),
                  ),
                ),
                const SizedBox(height: 20),
                _infoRow(Icons.pets, "Breed", pet.breed),
                _infoRow(Icons.category, "Type", pet.type),
                _infoRow(Icons.palette, "Color", pet.color ?? "N/A"),
                _infoRow(Icons.monitor_weight, "Weight", "${pet.weight} kg"),
                if (pet.notes != null && pet.notes!.isNotEmpty)
                  _infoRow(Icons.notes, "Notes", pet.notes!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700])),
                Text(value,
                    style:
                        GoogleFonts.inter(fontSize: 16, color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
