import 'package:capstone_app/web/user_web/components/web_pets_page_components/web_pet_creation_panel.dart';
import 'package:capstone_app/web/user_web/components/web_pets_page_components/web_pet_details_panel.dart';
import 'package:capstone_app/web/user_web/controllers/web_pets_controller.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum TabletPanelView { grid, details, create, edit }

class WebTabletPetsPage extends StatefulWidget {
  const WebTabletPetsPage({super.key});

  @override
  State<WebTabletPetsPage> createState() => _WebTabletPetsPageState();
}

class _WebTabletPetsPageState extends State<WebTabletPetsPage> {
  late final WebPetsController petsController;
  TabletPanelView currentView = TabletPanelView.grid;
  Pet? selectedPet;
  Pet? editingPet;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<WebPetsController>()) {
        petsController = Get.put(WebPetsController(
          authRepository: Get.find(),
          session: Get.find(),
        ));
      } else {
        petsController = Get.find();
      }
      
      _searchController.addListener(() {
        petsController.updateSearchQuery(_searchController.text);
      });
      
      setState(() {});
    });
  }

  void showCreatePanel() {
    setState(() {
      currentView = TabletPanelView.create;
      editingPet = null;
    });
  }

  void showEditPanel(Pet pet) {
    setState(() {
      currentView = TabletPanelView.edit;
      editingPet = pet;
    });
  }

  void showDetailsPanel(Pet pet) {
    setState(() {
      currentView = TabletPanelView.details;
      selectedPet = pet;
    });
    petsController.selectPet(pet);
  }

  void showGridView() {
    setState(() {
      currentView = TabletPanelView.grid;
      selectedPet = null;
      editingPet = null;
    });
    petsController.clearSelection();
  }

  void onPetActionSuccess() {
    petsController.refreshPets();
    showGridView();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (Get.isRegistered<WebPetsController>()) {
      Get.delete<WebPetsController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<WebPetsController>()) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    switch (currentView) {
      case TabletPanelView.create:
        return AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
            onPressed: showGridView,
          ),
          title: const Text(
            "Add New Pet",
            style: TextStyle(
              color: Color(0xFF2C3E50), 
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        );
        
      case TabletPanelView.edit:
        return AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
            onPressed: showGridView,
          ),
          title: Text(
            "Edit ${editingPet?.name ?? 'Pet'}",
            style: const TextStyle(
              color: Color(0xFF2C3E50), 
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        );
        
      case TabletPanelView.details:
        return AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
            onPressed: showGridView,
          ),
          title: Text(
            selectedPet?.name ?? "Pet Details",
            style: const TextStyle(
              color: Color(0xFF2C3E50), 
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF3498DB)),
              onPressed: () => showEditPanel(selectedPet!),
              tooltip: "Edit Pet",
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(selectedPet!),
              tooltip: "Delete Pet",
            ),
          ],
        );
        
      case TabletPanelView.grid:
      default:
        return AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text(
            "My Pets",
            style: TextStyle(
              color: Color(0xFF2C3E50), 
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: showCreatePanel,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Add Pet",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3498DB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildBody() {
    switch (currentView) {
      case TabletPanelView.create:
        return Container(
          color: Colors.white,
          child: WebPetCreationPanel(
            onSuccess: onPetActionSuccess,
          ),
        );
        
      case TabletPanelView.edit:
        return Container(
          color: Colors.white,
          child: WebPetCreationPanel(
            existingPet: editingPet,
            onSuccess: onPetActionSuccess,
          ),
        );
        
      case TabletPanelView.details:
        if (selectedPet == null) {
          return const Center(child: Text("Pet not found"));
        }
        return Container(
          color: Colors.white,
          child: WebPetDetailsPanel(
            pet: selectedPet!,
            onEdit: () => showEditPanel(selectedPet!),
            onDelete: () => _confirmDelete(selectedPet!),
          ),
        );
        
      case TabletPanelView.grid:
      default:
        return _buildGridView();
    }
  }

  Widget _buildGridView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar with improved styling
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search pets...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search_rounded, 
                  color: Colors.grey[500],
                ),
                suffixIcon: _SearchClearButton(controller: _searchController),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Pets Grid
          Expanded(
            child: Obx(() {
              if (petsController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3498DB),
                  ),
                );
              }

              final pets = petsController.filteredPets;
              
              if (pets.isEmpty) {
                return _buildEmptyState();
              }
              
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  final pet = pets[index];
                  return _buildPetCard(pet);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Pet pet) {
    return GestureDetector(
      onTap: () => showDetailsPanel(pet),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!, width: 1),
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
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    pet.image ?? 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=300&h=300&fit=crop',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.pets,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      pet.breed,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3498DB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pet.type,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3498DB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isNotEmpty 
                ? "No pets found matching your search"
                : "No pets yet",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchController.text.isNotEmpty 
                ? "Try adjusting your search terms"
                : "Add your first pet to get started",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (_searchController.text.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: showCreatePanel,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Add Pet",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(Pet pet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Delete Pet",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        content: Text(
          "Are you sure you want to delete ${pet.name}? This action cannot be undone.",
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey[600]),
            ),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Delete"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      await petsController.deletePet(pet);
      showGridView();
    }
  }
}

class _SearchClearButton extends StatelessWidget {
  final TextEditingController controller;

  const _SearchClearButton({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return value.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.grey[500],
                ),
                onPressed: () {
                  controller.clear();
                },
              )
            : const SizedBox.shrink();
      },
    );
  }
}