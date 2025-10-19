import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_appointment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class VaccinationCompletionDialog extends StatefulWidget {
  final Appointment appointment;

  const VaccinationCompletionDialog({
    super.key,
    required this.appointment,
  });

  @override
  State<VaccinationCompletionDialog> createState() =>
      _VaccinationCompletionDialogState();
}

class _VaccinationCompletionDialogState
    extends State<VaccinationCompletionDialog> {
  final _formKey = GlobalKey<FormState>();

  // Vaccination fields
  final _vaccineNameController = TextEditingController();
  final _vaccineTypeController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _notesController = TextEditingController();
  final _vetNotesController = TextEditingController();

  DateTime? _nextDueDate;
  bool _isBooster = false;

  // Common vaccine types for quick selection
  final List<String> _commonVaccineTypes = [
    'Rabies',
    'DHPP (Distemper, Hepatitis, Parvovirus, Parainfluenza)',
    'Bordetella',
    'Leptospirosis',
    'Lyme Disease',
    'Canine Influenza',
    'Feline Viral Rhinotracheitis',
    'Feline Calicivirus',
    'Feline Panleukopenia',
    'Feline Leukemia',
    'Other',
  ];

  String? _selectedVaccineType;

  @override
  void dispose() {
    _vaccineNameController.dispose();
    _vaccineTypeController.dispose();
    _batchNumberController.dispose();
    _manufacturerController.dispose();
    _notesController.dispose();
    _vetNotesController.dispose();
    super.dispose();
  }

  /// Check if form has any unsaved changes
  bool _hasFormChanges() {
    return _vaccineNameController.text.isNotEmpty ||
        _vaccineTypeController.text.isNotEmpty ||
        _batchNumberController.text.isNotEmpty ||
        _manufacturerController.text.isNotEmpty ||
        _notesController.text.isNotEmpty ||
        _vetNotesController.text.isNotEmpty ||
        _nextDueDate != null ||
        _isBooster;
  }

  /// Show discard changes confirmation dialog
  Future<bool?> _showDiscardChangesDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Discard Vaccination Data?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: const Text(
            'You have unsaved vaccination information. Are you sure you want to discard it? This action cannot be undone.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Continue Editing',
                style: TextStyle(
                  color: Color.fromARGB(255, 81, 115, 153),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Discard Changes',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Dispose of all controllers
  void _disposeControllers() {
    _vaccineNameController.dispose();
    _vaccineTypeController.dispose();
    _batchNumberController.dispose();
    _manufacturerController.dispose();
    _notesController.dispose();
    _vetNotesController.dispose();
  }

  /// Handle back button press
  Future<bool> _onWillPop() async {
    if (_hasFormChanges()) {
      final shouldDiscard = await _showDiscardChangesDialog();
      return shouldDiscard ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebAppointmentController>();
    final petName = controller.getPetName(widget.appointment.petId);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 700,
          constraints: const BoxConstraints(maxHeight: 800),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.vaccines,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Complete Vaccination Service',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 81, 115, 153),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Recording vaccination for $petName',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (_hasFormChanges()) {
                          final shouldDiscard =
                              await _showDiscardChangesDialog();
                          if (shouldDiscard == true) {
                            Navigator.pop(context);
                          }
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vaccine Type Dropdown
                        const Text(
                          'Vaccine Type *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 81, 115, 153),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedVaccineType,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Select vaccine type',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: _commonVaccineTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedVaccineType = value;
                              if (value != 'Other') {
                                _vaccineTypeController.text = value!;
                              } else {
                                _vaccineTypeController.clear();
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a vaccine type';
                            }
                            return null;
                          },
                        ),

                        // Custom vaccine type (if Other is selected)
                        if (_selectedVaccineType == 'Other') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _vaccineTypeController,
                            decoration: const InputDecoration(
                              labelText: 'Custom Vaccine Type *',
                              border: OutlineInputBorder(),
                              hintText: 'Enter vaccine type',
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                            validator: (value) {
                              if (_selectedVaccineType == 'Other' &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter vaccine type';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Vaccine Name
                        TextFormField(
                          controller: _vaccineNameController,
                          decoration: const InputDecoration(
                            labelText: 'Vaccine Brand/Product Name *',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., Nobivac, Purevax, etc.',
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter vaccine name';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Batch Number and Manufacturer
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _batchNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'Batch Number',
                                  border: OutlineInputBorder(),
                                  hintText: 'Optional',
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _manufacturerController,
                                decoration: const InputDecoration(
                                  labelText: 'Manufacturer',
                                  border: OutlineInputBorder(),
                                  hintText: 'Optional',
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Booster checkbox
                        StatefulBuilder(
                          builder: (context, setCheckboxState) {
                            return CheckboxListTile(
                              title: const Text('This is a booster shot'),
                              subtitle: const Text(
                                'Check if this is a follow-up/booster vaccination',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: _isBooster,
                              onChanged: (value) {
                                setCheckboxState(() {
                                  _isBooster = value ?? false;
                                  setState(() {});
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Next Due Date
                        InkWell(
                          onTap: () => _selectNextDueDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Next Due Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _nextDueDate != null
                                  ? DateFormat('MMMM dd, yyyy')
                                      .format(_nextDueDate!)
                                  : 'Select date (Optional)',
                              style: TextStyle(
                                color: _nextDueDate != null
                                    ? Colors.black87
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Vaccination Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Vaccination Notes',
                            border: OutlineInputBorder(),
                            hintText:
                                'Any reactions, special instructions, etc.',
                          ),
                          maxLines: 3,
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),

                        const SizedBox(height: 16),

                        // Veterinary Notes (for medical record)
                        TextFormField(
                          controller: _vetNotesController,
                          decoration: const InputDecoration(
                            labelText: 'Medical Record Notes',
                            border: OutlineInputBorder(),
                            hintText: 'Additional notes for the medical record',
                          ),
                          maxLines: 3,
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),

                        const SizedBox(height: 16),

                        // Info box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This will create both a vaccination record and a medical record for this pet.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        if (_hasFormChanges()) {
                          final shouldDiscard =
                              await _showDiscardChangesDialog();
                          if (shouldDiscard == true) {
                            _disposeControllers();
                            Navigator.pop(context);
                          }
                        } else {
                          _disposeControllers();
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _submitVaccination,
                      icon: const Icon(Icons.check),
                      label: const Text('Complete Vaccination'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectNextDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      helpText: 'Select next vaccination due date',
    );

    if (picked != null) {
      setState(() {
        _nextDueDate = picked;
      });
    }
  }

  void _submitVaccination() {
    if (_formKey.currentState!.validate()) {
      final controller = Get.find<WebAppointmentController>();

      // Get veterinarian name
      final vetName = controller.getVeterinarianName();

      final vaccinationData = {
        'vaccineType': _vaccineTypeController.text.trim(),
        'vaccineName': _vaccineNameController.text.trim(),
        'batchNumber': _batchNumberController.text.trim().isNotEmpty
            ? _batchNumberController.text.trim()
            : null,
        'manufacturer': _manufacturerController.text.trim().isNotEmpty
            ? _manufacturerController.text.trim()
            : null,
        'nextDueDate': _nextDueDate,
        'isBooster': _isBooster,
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        'veterinarianName': vetName,
      };

      // Close dialog
      Navigator.pop(context);

      // Complete vaccination through controller
      controller.completeVaccinationService(
        appointment: widget.appointment,
        vaccinationData: vaccinationData,
        vetNotes: _vetNotesController.text.trim().isNotEmpty
            ? _vetNotesController.text.trim()
            : null,
      );
    }
  }
}
