import 'package:capstone_app/web/user_web/components/web_pets_page_components/web_pets_page_pet_tile.dart';
import 'package:capstone_app/web/user_web/components/web_pets_page_components/web_pet_creation_panel.dart';
import 'package:capstone_app/web/user_web/components/web_pets_page_components/web_pet_details_panel.dart';
import 'package:capstone_app/web/user_web/controllers/web_pets_controller.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:get/get.dart';

enum RightPanelView { none, details, create, edit }

class WebPetsPage extends StatefulWidget {
  const WebPetsPage({super.key});

  @override
  State<WebPetsPage> createState() => _WebPetsPageState();
}

class _WebPetsPageState extends State<WebPetsPage> {
  late final WebPetsController petsController;
  
  RightPanelView rightPanelView = RightPanelView.none;
  Pet? editingPet;

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
      setState(() {});
    });
  }

  void showCreatePanel() {
    setState(() {
      rightPanelView = RightPanelView.create;
      editingPet = null;
    });
  }

  void showEditPanel(Pet pet) {
    setState(() {
      rightPanelView = RightPanelView.edit;
      editingPet = pet;
    });
  }

  void showDetailsPanel(Pet pet) {
    setState(() {
      rightPanelView = RightPanelView.details;
      petsController.selectPet(pet);
    });
  }

  void clearRightPanel() {
    setState(() {
      rightPanelView = RightPanelView.none;
      editingPet = null;
    });
    petsController.clearSelection();
  }

  void onPetActionSuccess() {
    petsController.refreshPets();
    clearRightPanel();
  }

  @override
  void dispose() {
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
      body: Row(
        children: [
          // Left Panel - Pet Cards
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: LeftSidePanel(
                onShowCreate: showCreatePanel,
                onShowDetails: showDetailsPanel,
                onClearSelection: clearRightPanel,
              ),
            ),
          ),
          
          // Right Panel - Pet Details or Add Form
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: RightSidePanel(
                currentView: rightPanelView,
                editingPet: editingPet,
                onSuccess: onPetActionSuccess,
                onShowEdit: showEditPanel,
                onClearPanel: clearRightPanel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LeftSidePanel extends StatefulWidget {
  final VoidCallback onShowCreate;
  final Function(Pet) onShowDetails;
  final VoidCallback onClearSelection;

  const LeftSidePanel({
    super.key,
    required this.onShowCreate,
    required this.onShowDetails,
    required this.onClearSelection,
  });

  @override
  State<LeftSidePanel> createState() => _LeftSidePanelState();
}

class _LeftSidePanelState extends State<LeftSidePanel> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Get.find<WebPetsController>().updateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebPetsController>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Pets',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 24),
        
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final pets = controller.filteredPets;
            
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: pets.length + 1, // +1 for add button
              itemBuilder: (context, index) {
                if (index == pets.length) {
                  // Add Pet Card
                  return _buildAddPetCard();
                }
                return _buildPetCard(pets[index], controller);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPetCard(Pet pet, WebPetsController controller) {
    final isSelected = controller.selectedPet.value?.petId == pet.petId;
    
    return InkWell(
      onTap: () {
        print('Pet card tapped: ${pet.name}'); // Debug print
        widget.onShowDetails(pet);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF3498DB) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? const Color(0xFF3498DB).withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              spreadRadius: isSelected ? 2 : 1,
              blurRadius: isSelected ? 8 : 4,
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

  Widget _buildAddPetCard() {
    return InkWell(
      onTap: () {
        print('Add pet card tapped'); // Debug print
        widget.onShowCreate();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!, width: 2),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF3498DB).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 30,
                color: Color(0xFF3498DB),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add Pet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3498DB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RightSidePanel extends StatelessWidget {
  final RightPanelView currentView;
  final Pet? editingPet;
  final VoidCallback onSuccess;
  final Function(Pet) onShowEdit;
  final VoidCallback onClearPanel;

  const RightSidePanel({
    super.key,
    required this.currentView,
    this.editingPet,
    required this.onSuccess,
    required this.onShowEdit,
    required this.onClearPanel,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebPetsController>();
    
    switch (currentView) {
      case RightPanelView.create:
        return WebPetCreationPanel(
          onSuccess: onSuccess,
        );
        
      case RightPanelView.edit:
        return WebPetCreationPanel(
          existingPet: editingPet,
          onSuccess: onSuccess,
        );
        
      case RightPanelView.details:
        return Obx(() {
          final selectedPet = controller.selectedPet.value;
          if (selectedPet == null) {
            return const Center(
              child: Text("No pet selected"),
            );
          }
          
          return WebPetDetailsPanel(
            pet: selectedPet,
            onEdit: () => onShowEdit(selectedPet),
            onDelete: () async {
              await controller.deletePet(selectedPet);
              onClearPanel();
            },
          );
        });
        
      case RightPanelView.none:
      default:
        return _buildWelcomeMessage();
    }
  }

  Widget _buildWelcomeMessage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 80,
              color: Color(0xFF3498DB),
            ),
            SizedBox(height: 24),
            Text(
              'Welcome to Pet Manager',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Select a pet to view details\nor add a new pet to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}