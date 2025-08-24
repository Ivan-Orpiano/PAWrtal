import 'package:capstone_app/data/models/pet_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebPetDetailsPanel extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WebPetDetailsPanel({
    super.key,
    required this.pet,
    this.onEdit,
    this.onDelete,
  });

  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Pet"),
        content: Text("Are you sure you want to delete ${pet.name}?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with actions
          // Row(
          //   children: [
          //     Icon(
          //       Icons.pets,
          //       color: Colors.indigo,
          //       size: 24,
          //     ),
          //     const SizedBox(width: 12),
          //     Expanded(
          //       child: Text(
          //         pet.name,
          //         style: const TextStyle(
          //           fontSize: 24,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //     ),
          //     IconButton(
          //       icon: const Icon(Icons.edit, color: Colors.blue),
          //       onPressed: onEdit,
          //       tooltip: "Edit Pet",
          //     ),
          //     IconButton(
          //       icon: const Icon(Icons.delete, color: Colors.red),
          //       onPressed: () => _confirmDelete(context),
          //       tooltip: "Delete Pet",
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pet Image
                  Center(
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          pet.image ?? 'https://via.placeholder.com/300x250?text=No+Image',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Pet Information Cards
                  _buildInfoSection([
                    _buildInfoCard(Icons.category, "Type", pet.type),
                    _buildInfoCard(Icons.pets_outlined, "Breed", pet.breed),
                  ]),
                  
                  const SizedBox(height: 16),
                  
                  _buildInfoSection([
                    _buildInfoCard(Icons.palette, "Color", pet.color ?? "Not specified"),
                    _buildInfoCard(Icons.monitor_weight, "Weight", 
                      pet.weight != null ? "${pet.weight} kg" : "Not specified"),
                  ]),

                  if (pet.notes != null && pet.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildNotesCard(),
                  ],

                  const SizedBox(height: 24),

                  // Additional sections can be added here
                  // For example: Medical records, appointments, etc.
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(List<Widget> children) {
    return Row(
      children: children.map((child) => 
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: child,
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              Text(
                "Notes",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pet.notes!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}