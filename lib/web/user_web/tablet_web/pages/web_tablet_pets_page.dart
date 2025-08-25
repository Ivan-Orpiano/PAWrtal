import 'package:capstone_app/web/user_web/components/web_pets_page_components/web_pets_page_pet_tile.dart';
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
      backgroundColor: Colors.grey.shade50,
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
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: showGridView,
          ),
          title: const Text(
            "Add New Pet",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
        );
        
      case TabletPanelView.edit:
        return AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: showGridView,
          ),
          title: Text(
            "Edit ${editingPet?.name ?? 'Pet'}",
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
        );
        
      case TabletPanelView.details:
        return AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: showGridView,
          ),
          title: Text(
            selectedPet?.name ?? "Pet Details",
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => showEditPanel(selectedPet!),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(selectedPet!),
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
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.indigo),
              onPressed: showCreatePanel,
            ),
          ],
        );
    }
  }

  Widget _buildBody() {
    switch (currentView) {
      case TabletPanelView.create:
        return WebPetCreationPanel(
          onSuccess: onPetActionSuccess,
        );
        
      case TabletPanelView.edit:
        return WebPetCreationPanel(
          existingPet: editingPet,
          onSuccess: onPetActionSuccess,
        );
        
      case TabletPanelView.details:
        if (selectedPet == null) {
          return const Center(child: Text("Pet not found"));
        }
        return WebPetDetailsPanel(
          pet: selectedPet!,
          onEdit: () => showEditPanel(selectedPet!),
          onDelete: () => _confirmDelete(selectedPet!),
        );
        
      case TabletPanelView.grid:
      default:
        return _buildGridView();
    }
  }

  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
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
                hintStyle: const TextStyle(fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                suffixIcon: _SearchClearButton(controller: _searchController),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Pets Grid
          Expanded(
            child: Obx(() {
              if (petsController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final pets = petsController.filteredPets;
              
              if (pets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pets,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isNotEmpty 
                            ? "No pets found matching your search"
                            : "No pets yet",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchController.text.isNotEmpty 
                            ? "Try adjusting your search terms"
                            : "Add your first pet to get started",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (_searchController.text.isEmpty) ...[
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: showCreatePanel,
                          icon: const Icon(Icons.add),
                          label: const Text("Add Pet"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
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
              
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns for tablet
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2, 
                ),
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  final pet = pets[index];
                  return WebPetsPagePetTile(
                    pet: pet,
                    onTap: () => showDetailsPanel(pet),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Pet pet) async {
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
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  controller.clear();
                },
              )
            : const SizedBox.shrink();
      },
    );
  }
}