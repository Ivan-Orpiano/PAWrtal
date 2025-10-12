import 'package:capstone_app/data/models/pet_model.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

enum CardView { front, back, medicalHistory, vaccinationHistory }

class WebPetDetailsPanel extends StatefulWidget {
  final Pet pet;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WebPetDetailsPanel({
    super.key,
    required this.pet,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<WebPetDetailsPanel> createState() => _WebPetDetailsPanelState();
}

class _WebPetDetailsPanelState extends State<WebPetDetailsPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  CardView _currentView = CardView.front;
  CardView _previousView = CardView.front;
  bool _isGoingForward = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _getViewLevel(CardView view) {
    switch (view) {
      case CardView.front:
        return 0;
      case CardView.back:
        return 1;
      case CardView.medicalHistory:
      case CardView.vaccinationHistory:
        return 2;
    }
  }

  void _flipToView(CardView newView) {
    setState(() {
      _previousView = _currentView;
      _isGoingForward = _getViewLevel(newView) > _getViewLevel(_currentView);
      _currentView = newView;
    });
    _controller.forward(from: 0);
  }

  void _confirmDelete(BuildContext context) async {
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
          "Are you sure you want to delete ${widget.pet.name}? This action cannot be undone.",
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
      widget.onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * math.pi * (_isGoingForward ? 1 : -1);
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: angle.abs() >= math.pi / 2
              ? Transform(
                  transform: Matrix4.identity()..rotateY(_isGoingForward ? math.pi : -math.pi),
                  alignment: Alignment.center,
                  child: _buildCurrentView(),
                )
              : _buildPreviousView(),
        );
      },
    );
  }

  Widget _buildPreviousView() {
    switch (_previousView) {
      case CardView.front:
        return _buildFrontSide();
      case CardView.back:
        return _buildBackSide();
      case CardView.medicalHistory:
        return _buildMedicalHistoryView();
      case CardView.vaccinationHistory:
        return _buildVaccinationHistoryView();
    }
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case CardView.front:
        return _buildFrontSide();
      case CardView.back:
        return _buildBackSide();
      case CardView.medicalHistory:
        return _buildMedicalHistoryView();
      case CardView.vaccinationHistory:
        return _buildVaccinationHistoryView();
    }
  }

  Widget _buildFrontSide() {
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
            // Header section with small image on top left
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF3498DB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Small circular pet image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        widget.pet.image ?? 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=300&h=300&fit=crop',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.pets,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Pet info next to image
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.pet.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.pet.type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.flip, color: Colors.white),
                        onPressed: () => _flipToView(CardView.back),
                        tooltip: "Flip Card",
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: widget.onEdit,
                        tooltip: "Edit Pet",
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _confirmDelete(context),
                        tooltip: "Delete Pet",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Body section with pet details
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID-style information grid
                  _buildIDRow('Breed', widget.pet.breed),
                  const Divider(height: 24),
                  _buildIDRow('Color', widget.pet.color ?? 'Not specified'),
                  const Divider(height: 24),
                  _buildIDRow('Weight', widget.pet.weight != null ? '${widget.pet.weight} kg' : 'Not specified'),
                  const Divider(height: 24),
                  _buildIDRow('Gender', widget.pet.gender ?? 'Not specified'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackSide() {
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
            // Header for back side
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF2C3E50),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Additional Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flip, color: Colors.white),
                    onPressed: () => _flipToView(CardView.front),
                    tooltip: "Flip Card",
                  ),
                ],
              ),
            ),
            
            // Back side content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medical History section
                  _buildEmptyStateButton(
                    'Medical History',
                    'View Medical History',
                    Icons.medical_services_outlined,
                    () => _flipToView(CardView.medicalHistory),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Vaccination History section
                  _buildEmptyStateButton(
                    'Vaccination History',
                    'View Vaccination History',
                    Icons.vaccines_outlined,
                    () => _flipToView(CardView.vaccinationHistory),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistoryView() {
    // Sample medical history data - replace with actual data from your model
    final medicalRecords = [
      {'date': '2024-03-15', 'condition': 'Annual Checkup', 'treatment': 'Routine examination', 'vet': 'Dr. Smith'},
      {'date': '2024-01-20', 'condition': 'Ear Infection', 'treatment': 'Antibiotics prescribed', 'vet': 'Dr. Johnson'},
      {'date': '2023-11-10', 'condition': 'Dental Cleaning', 'treatment': 'Professional cleaning', 'vet': 'Dr. Smith'},
    ];

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF3498DB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => _flipToView(CardView.back),
                  tooltip: "Back",
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Medical History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Table content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.5),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(2.5),
                            3: FlexColumnWidth(1.5),
                          },
                          border: TableBorder.symmetric(
                            inside: BorderSide(color: Colors.grey[300]!),
                          ),
                          children: [
                            // Header row
                            TableRow(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                              ),
                              children: [
                                _buildTableHeader('Date'),
                                _buildTableHeader('Condition'),
                                _buildTableHeader('Treatment'),
                                _buildTableHeader('Veterinarian'),
                              ],
                            ),
                            // Data rows
                            ...medicalRecords.map((record) => TableRow(
                              children: [
                                _buildTableCell(record['date']!),
                                _buildTableCell(record['condition']!),
                                _buildTableCell(record['treatment']!),
                                _buildTableCell(record['vet']!),
                              ],
                            )),
                          ],
                        ),
                      ),
                    ),
                    
                    if (medicalRecords.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No medical history records available',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationHistoryView() {
    // Sample vaccination data - replace with actual data from your model
    final vaccinationRecords = [
      {'date': '2024-02-15', 'vaccine': 'Rabies', 'nextDue': '2025-02-15', 'vet': 'Dr. Smith'},
      {'date': '2024-01-10', 'vaccine': 'DHPP', 'nextDue': '2025-01-10', 'vet': 'Dr. Johnson'},
      {'date': '2023-12-05', 'vaccine': 'Bordetella', 'nextDue': '2024-12-05', 'vet': 'Dr. Smith'},
    ];

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF2C3E50),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => _flipToView(CardView.back),
                  tooltip: "Back",
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Vaccination History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Table content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.5),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(1.5),
                            3: FlexColumnWidth(1.5),
                          },
                          border: TableBorder.symmetric(
                            inside: BorderSide(color: Colors.grey[300]!),
                          ),
                          children: [
                            // Header row
                            TableRow(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                              ),
                              children: [
                                _buildTableHeader('Date Given'),
                                _buildTableHeader('Vaccine'),
                                _buildTableHeader('Next Due'),
                                _buildTableHeader('Veterinarian'),
                              ],
                            ),
                            // Data rows
                            ...vaccinationRecords.map((record) => TableRow(
                              children: [
                                _buildTableCell(record['date']!),
                                _buildTableCell(record['vaccine']!),
                                _buildTableCell(record['nextDue']!),
                                _buildTableCell(record['vet']!),
                              ],
                            )),
                          ],
                        ),
                      ),
                    ),
                    
                    if (vaccinationRecords.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No vaccination records available',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildIDRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
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

  Widget _buildEmptyStateButton(
    String title,
    String buttonText,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3498DB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}