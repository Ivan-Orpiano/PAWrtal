import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';

class EmailTemplateEditor extends StatefulWidget {
  final ClinicSettings clinicSettings;
  final VoidCallback onTemplateUpdated;

  const EmailTemplateEditor({
    super.key,
    required this.clinicSettings,
    required this.onTemplateUpdated,
  });

  @override
  State<EmailTemplateEditor> createState() => _EmailTemplateEditorState();
}

class _EmailTemplateEditorState extends State<EmailTemplateEditor> {
  late TextEditingController _templateController;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;

  static const Color primaryBlue = Color(0xFF4A6FA5);
  static const Color primaryTeal = Color(0xFF5B9BD5);
  static const Color vetGreen = Color(0xFF34D399);
  static const Color mediumGray = Color(0xFF9CA3AF);
  static const Color lightVetGreen = Color(0xFFE5F7E5);

  @override
  void initState() {
    super.initState();
    _templateController = TextEditingController(
      text: widget.clinicSettings.staffEmailTemplate,
    );
  }

  @override
  void dispose() {
    _templateController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    final newTemplate = _templateController.text.trim();

    // Validate template
    if (!ClinicSettings.isValidEmailTemplate(newTemplate)) {
      setState(() {
        _errorMessage =
            'Invalid template. Must contain @ and a valid domain (e.g., @clinic.vet)';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final authRepo = Get.find<AuthRepository>();

      // Update clinic settings email template
      await authRepo.updateClinicSettingsEmailTemplate(
        widget.clinicSettings.documentId!,
        newTemplate,
      );

      // Show confirmation dialog before updating staff emails
      final shouldUpdateStaff = await _showUpdateConfirmation();

      if (shouldUpdateStaff == true) {
        // Update all existing staff emails
        await authRepo.updateAllStaffEmailsForClinic(
          widget.clinicSettings.clinicId,
          newTemplate,
        );

        Get.snackbar(
          'Success',
          'Email template and all staff emails updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: vetGreen,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Success',
          'Email template updated. New staff will use the new template.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: vetGreen,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      }

      setState(() {
        _isEditing = false;
      });

      widget.onTemplateUpdated();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update template: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<bool?> _showUpdateConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.update, color: primaryTeal),
            SizedBox(width: 12),
            Text('Update Existing Staff Emails?'),
          ],
        ),
        content: const Text(
          'Do you want to update email addresses for all existing staff members? '
          'This will regenerate their email addresses using the new template.\n\n'
          'Note: Authentication emails cannot be changed and will remain the same.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Skip', style: TextStyle(color: mediumGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update All'),
          ),
        ],
      ),
    );
  }

  String _generatePreview() {
    final template = _templateController.text.trim();
    if (template.isEmpty) return 'example@domain.vet';

    // If template starts with @, prepend example name
    if (template.startsWith('@')) {
      return 'johndoe$template';
    }

    // For backward compatibility with {name} format
    return template.replaceAll('{name}', 'john.doe');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditing) {
      return _buildDisplayMode();
    } else {
      return _buildEditMode();
    }
  }

  Widget _buildDisplayMode() {
    // Display template without {name} for cleaner look
    String displayTemplate = widget.clinicSettings.staffEmailTemplate;
    if (displayTemplate.contains('{name}')) {
      displayTemplate = displayTemplate.replaceAll('{name}', '');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            lightVetGreen.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.email, color: primaryTeal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Staff Email Template',
                  style: TextStyle(
                    fontSize: 12,
                    color: mediumGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayTemplate,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.edit, color: primaryTeal, size: 20),
            tooltip: 'Edit template',
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.edit_note, color: primaryTeal, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Edit Email Template',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _templateController,
            decoration: const InputDecoration(
              labelText: 'Email Template',
              hintText: '@yourclinic.vet',
              helperText: 'Staff emails will be: staffname@yourclinic.vet',
              helperMaxLines: 2,
              prefixIcon: Icon(Icons.alternate_email),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryTeal, width: 2),
              ),
            ),
            onChanged: (_) => setState(() => _errorMessage = null),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightVetGreen.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryTeal.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.visibility, color: primaryTeal, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Preview: ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _generatePreview(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        _templateController.text =
                            widget.clinicSettings.staffEmailTemplate;
                        setState(() {
                          _isEditing = false;
                          _errorMessage = null;
                        });
                      },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: mediumGray),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveTemplate,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text(_isSaving ? 'Saving...' : 'Save Template'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
