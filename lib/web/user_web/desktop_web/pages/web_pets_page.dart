import 'package:flutter/material.dart';

// Pet model
class Pet {
  final String id;
  final String name;
  final String breed;
  final String petType;
  final String imageUrl;
  final String description;
  final String medicalHistory;
  final String age;
  final String weight;
  final String color;
  final String ownerNotes;

  Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.petType,
    required this.imageUrl,
    required this.description,
    required this.medicalHistory,
    required this.age,
    required this.weight,
    required this.color,
    required this.ownerNotes,
  });
}

class WebPetsPage extends StatefulWidget {
  const WebPetsPage({super.key});

  @override
  State<WebPetsPage> createState() => _WebPetsPageState();
}

class _WebPetsPageState extends State<WebPetsPage> {
  List<Pet> pets = [
    Pet(
      id: '1',
      name: 'Buddy',
      breed: 'Golden Retriever',
      petType: 'Dog',
      imageUrl: 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=300&h=300&fit=crop',
      description: 'Friendly and energetic dog who loves playing fetch and going for walks.',
      medicalHistory: 'Vaccinated, dewormed. Last checkup: Jan 2024. No known allergies.',
      age: '3 years',
      weight: '32 kg',
      color: 'Golden',
      ownerNotes: 'Loves treats and belly rubs. Gets excited around other dogs.',
    ),
    Pet(
      id: '2',
      name: 'Whiskers',
      breed: 'Persian',
      petType: 'Cat',
      imageUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=300&h=300&fit=crop',
      description: 'Calm and affectionate cat who enjoys sunbathing and being petted.',
      medicalHistory: 'Spayed, vaccinated. Regular dental cleanings. Last vet visit: Dec 2023.',
      age: '2 years',
      weight: '4.5 kg',
      color: 'White and Gray',
      ownerNotes: 'Prefers quiet environments. Loves tuna treats.',
    ),
  ];

  Pet? selectedPet;
  bool showAddForm = false;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _petTypeController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();
  final _ownerNotesController = TextEditingController();

  void _clearForm() {
    _nameController.clear();
    _breedController.clear();
    _petTypeController.clear();
    _imageUrlController.clear();
    _descriptionController.clear();
    _medicalHistoryController.clear();
    _ageController.clear();
    _weightController.clear();
    _colorController.clear();
    _ownerNotesController.clear();
  }

  void _savePet() {
    if (_nameController.text.isEmpty || _breedController.text.isEmpty) return;
    
    final newPet = Pet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      breed: _breedController.text,
      petType: _petTypeController.text,
      imageUrl: _imageUrlController.text.isEmpty 
          ? 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=300&h=300&fit=crop'
          : _imageUrlController.text,
      description: _descriptionController.text,
      medicalHistory: _medicalHistoryController.text,
      age: _ageController.text,
      weight: _weightController.text,
      color: _colorController.text,
      ownerNotes: _ownerNotesController.text,
    );

    setState(() {
      pets.add(newPet);
      showAddForm = false;
      selectedPet = newPet;
      _clearForm();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              child: Column(
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
                    child: GridView.builder(
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
                        return _buildPetCard(pets[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right Panel - Pet Details or Add Form
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: showAddForm 
                  ? _buildAddPetForm()
                  : selectedPet != null 
                      ? _buildPetDetails()
                      : _buildWelcomeMessage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Pet pet) {
    final isSelected = selectedPet?.id == pet.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPet = pet;
          showAddForm = false;
        });
      },
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
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(pet.imageUrl),
                    fit: BoxFit.cover,
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
                        pet.petType,
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
    return GestureDetector(
      onTap: () {
        setState(() {
          showAddForm = true;
          selectedPet = null;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
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

  Widget _buildPetDetails() {
    if (selectedPet == null) return Container();
    
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image: DecorationImage(
                  image: NetworkImage(selectedPet!.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedPet!.name,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3498DB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          selectedPet!.petType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick info cards
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard('Breed', selectedPet!.breed)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoCard('Age', selectedPet!.age)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoCard('Weight', selectedPet!.weight)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  _buildDetailSection('About', selectedPet!.description),
                  
                  const SizedBox(height: 20),
                  
                  // Medical History
                  _buildDetailSection('Medical History', selectedPet!.medicalHistory),
                  
                  const SizedBox(height: 20),
                  
                  // Owner Notes
                  _buildDetailSection('Owner Notes', selectedPet!.ownerNotes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            content.isEmpty ? 'No information available' : content,
            style: TextStyle(
              fontSize: 14,
              color: content.isEmpty ? Colors.grey[500] : const Color(0xFF2C3E50),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPetForm() {
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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New Pet',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        showAddForm = false;
                        _clearForm();
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Form fields
              _buildFormField('Pet Name *', _nameController),
              _buildFormField('Breed *', _breedController),
              _buildFormField('Pet Type (Dog, Cat, etc.)', _petTypeController),
              _buildFormField('Image URL', _imageUrlController),
              _buildFormField('Age', _ageController),
              _buildFormField('Weight', _weightController),
              _buildFormField('Color', _colorController),
              _buildFormField('Description', _descriptionController, maxLines: 3),
              _buildFormField('Medical History', _medicalHistoryController, maxLines: 3),
              _buildFormField('Owner Notes', _ownerNotesController, maxLines: 3),
              
              const SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _savePet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Pet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3498DB), width: 2),
              ),
              fillColor: Colors.grey[50],
              filled: true,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
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