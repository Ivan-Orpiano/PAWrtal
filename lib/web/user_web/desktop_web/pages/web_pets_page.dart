import 'package:capstone_app/web/user_web/components/web_pets_page_components/web_pet_creation_panel.dart';
import 'package:capstone_app/web/user_web/components/web_pets_page_components/web_pet_details_panel.dart';
import 'package:capstone_app/web/user_web/controllers/web_pets_controller.dart';
import 'package:capstone_app/web/dimensions.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebPetsPage extends StatefulWidget {
  const WebPetsPage({super.key});

  @override
  State<WebPetsPage> createState() => _WebPetsPageState();
}

class _WebPetsPageState extends State<WebPetsPage> with TickerProviderStateMixin {
  late final WebPetsController petsController;
  final TextEditingController _searchController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Palette
  static const Color primaryBlue = Color(0xFF4A6FA5);
  static const Color primaryTeal = Color(0xFF5B9BD5);
  static const Color lightTeal = Color(0xFF9FC5E8);
  static const Color deepBlue = Color(0xFF2F4F7F);
  static const Color softBlue = Color(0xFF6FA8DC);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color darkText = Color(0xFF374151);
  static const Color petGreen = Color(0xFF34D399);
  static const Color lightPetGreen = Color(0xFFE5F7E5);

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<WebPetsController>()) {
        petsController = Get.put(WebPetsController(
          authRepository: Get.find(),
          session: Get.find(),
        ));
      } else {
        petsController = Get.find();
      }
      _animationController.forward();
      setState(() {});
    });

    _searchController.addListener(() {
      if (Get.isRegistered<WebPetsController>()) {
        petsController.updateSearchQuery(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    if (Get.isRegistered<WebPetsController>()) {
      Get.delete<WebPetsController>();
    }
    super.dispose();
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          child: WebPetCreationPanel(
            onSuccess: () {
              Navigator.of(context).pop();
              petsController.refreshPets();
            },
          ),
        ),
      ),
    );
  }

  void _showEditDialog(Pet pet) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          child: WebPetCreationPanel(
            existingPet: pet,
            onSuccess: () {
              Navigator.of(context).pop();
              petsController.refreshPets();
            },
          ),
        ),
      ),
    );
  }

  void _showDetailsDialog(Pet pet) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          child: WebPetDetailsPanel(
            pet: pet,
            onEdit: () {
              Navigator.of(context).pop();
              _showEditDialog(pet);
            },
            onDelete: () async {
              Navigator.of(context).pop();
              await petsController.deletePet(pet);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<WebPetsController>()) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: lightGray,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: Container(
                color: lightGray,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > tabletWidth;
    
    // Search bar
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.8),
            lightGray.withOpacity(0.5)
          ],
        ),
      ),
      child: _buildSearchBar(),
    );
  }

  Widget _buildTitleSection(bool isTablet) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryTeal.withOpacity(0.2),
                primaryBlue.withOpacity(0.15)
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: primaryTeal.withOpacity(0.3), width: 1.5),
          ),
          child: const Icon(Icons.pets, color: primaryTeal, size: 26),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    const LinearGradient(colors: [darkText, deepBlue, primaryTeal])
                        .createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: const Text(
                  'My Pets',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage your beloved pets and their information',
                style: TextStyle(
                    fontSize: 15,
                    color: mediumGray,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, lightPetGreen.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: primaryTeal.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search pets by name, type, or breed...',
            hintStyle:
                TextStyle(fontSize: 15, color: mediumGray.withOpacity(0.8)),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryTeal.withOpacity(0.2),
                    primaryBlue.withOpacity(0.1)
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded,
                  size: 20, color: primaryTeal),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.clear, size: 16, color: mediumGray),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > tabletWidth;
    
    return Padding(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: _buildPetGrid(),
    );
  }

  Widget _buildPetGrid() {
    return Obx(() {
      if (petsController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final filteredPets = petsController.filteredPets;
      
      if (filteredPets.isEmpty && _searchController.text.isNotEmpty) {
        return _buildEmptyState();
      }

      return _buildResponsivePetGrid(filteredPets);
    });
  }

  Widget _buildResponsivePetGrid(List<Pet> pets) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double spacing = w > tabletWidth ? 20.0 : 12.0;

        // Columns by width
        int cols;
        if (w >= 1600) {
          cols = 8;
        } else if (w >= 1400) {
          cols = 7;
        } else if (w >= 1200) {
          cols = 6;
        } else if (w >= 1000) {
          cols = 5;
        } else if (w >= 820) {
          cols = 4;
        } else if (w >= 620) {
          cols = 3;
        } else {
          cols = 2;
        }

        // Compute tile dimensions
        final double tileWidth = (w - (cols - 1) * spacing) / cols;
        final double aspectRatio = (cols <= 2) ? 0.75 : 0.8;

        return GridView.builder(
          itemCount: pets.length + 1, // +1 for add button
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            if (index == pets.length) {
              return _buildAddPetCard();
            }
            return _buildPetCard(pets[index]);
          },
        );
      },
    );
  }

  Widget _buildPetCard(Pet pet) {
    return InkWell(
      onTap: () => _showDetailsDialog(pet),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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

  Widget _buildAddPetCard() {
    return InkWell(
      onTap: _showCreateDialog,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: primaryTeal.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.search_off_rounded, size: 72, color: mediumGray),
          ),
          const SizedBox(height: 20),
          const Text('No pets found',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: darkText)),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No pets match your search criteria.\nTry adjusting your search terms.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: mediumGray, height: 1.5),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
            icon: const Icon(Icons.clear_all_rounded, color: Colors.white),
            label: const Text('Clear Search',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}