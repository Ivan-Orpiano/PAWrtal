import 'package:capstone_app/web/user_web/components/web_pets_page_components/web_pets_page_pet_tile.dart';
import 'package:capstone_app/web/user_web/components/web_pets_page_components/web_pets_page_search_bar.dart';
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
  final MultiSplitViewController _controller = MultiSplitViewController(areas: [
    Area(flex: 2.5, min: 1.5, builder: (context, area) => const Padding(
      padding: EdgeInsets.only(top: 16, bottom: 16, left: 65),
      child: LeftSidePanel(),
    )),
    Area(flex: 2, max: 1.3, min: 0.8, builder: (context, area) => const Padding(
      padding: EdgeInsets.only(top: 16, bottom: 16, right: 65),
      child: RightSidePanel(),
    ))
  ]);

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
      backgroundColor: Colors.white,
      body: MultiSplitViewTheme(
        data: MultiSplitViewThemeData(
          dividerPainter: DividerPainters.grooved1(
            color: Colors.indigo[100]!,
            highlightedColor: Colors.indigo[900]!
          )
        ),
        child: MultiSplitView(
          controller: _controller,
        ),
      ),
    );
  }
}

class LeftSidePanel extends StatefulWidget {
  const LeftSidePanel({super.key});

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
    final webPetsPage = context.findAncestorStateOfType<_WebPetsPageState>();
    final controller = Get.find<WebPetsController>();
    
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        webPetsPage?.clearRightPanel();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xe6f0ffff),
          borderRadius: BorderRadius.all(Radius.circular(20))
        ),
        child: Column(
          children: [
            // Header with search
            Row(
              children: [
                Flexible(
                  flex: 3,
                  child: SizedBox(
                    height: 50,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search pets...',
                        hintStyle: const TextStyle(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Colors.indigo,
                            width: 1.5
                          )
                        ),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _SearchClearButton(controller: _searchController),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            
            // Pets grid
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final pets = controller.filteredPets;
                
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8, 
                  ),
                  itemCount: pets.length + 1,
                  itemBuilder: (context, index) {
                    if (index == pets.length) {
                      // Add Button Card
                      return GestureDetector(
                        onTap: () {
                          webPetsPage?.showCreatePanel();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.indigo[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.indigo, width: 2, style: BorderStyle.solid),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, size: 48, color: Colors.indigo),
                              const SizedBox(height: 8),
                              Text(
                                "Add New Pet",
                                style: TextStyle(
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      final pet = pets[index];
                      return WebPetsPagePetTile(
                        pet: pet,
                        isSelected: controller.selectedPet.value?.petId == pet.petId,
                        onTap: () {
                          webPetsPage?.showDetailsPanel(pet);
                        },
                      );
                    }
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class RightSidePanel extends StatelessWidget {
  const RightSidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final webPetsPage = context.findAncestorStateOfType<_WebPetsPageState>();
    final controller = Get.find<WebPetsController>();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _buildRightPanelContent(webPetsPage, controller),
    );
  }

  Widget _buildRightPanelContent(_WebPetsPageState? webPetsPage, WebPetsController controller) {
    if (webPetsPage == null) {
      return const SizedBox.shrink();
    }

    switch (webPetsPage.rightPanelView) {
      case RightPanelView.create:
        return WebPetCreationPanel(
          onSuccess: webPetsPage.onPetActionSuccess,
        );
        
      case RightPanelView.edit:
        return WebPetCreationPanel(
          existingPet: webPetsPage.editingPet,
          onSuccess: webPetsPage.onPetActionSuccess,
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
            onEdit: () => webPetsPage.showEditPanel(selectedPet),
            onDelete: () async {
              await controller.deletePet(selectedPet);
              webPetsPage.clearRightPanel();
            },
          );
        });
        
      case RightPanelView.none:
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pets,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                "Select a pet to view details",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "or click the + button to add a new pet",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
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