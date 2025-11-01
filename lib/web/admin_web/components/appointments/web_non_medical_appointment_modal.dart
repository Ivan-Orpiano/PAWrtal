import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebNonMedicalAppointmentModal extends StatefulWidget {
  final Appointment appointment;

  const WebNonMedicalAppointmentModal({
    super.key,
    required this.appointment,
  });

  @override
  State<WebNonMedicalAppointmentModal> createState() =>
      _WebNonMedicalAppointmentModalState();
}

class _WebNonMedicalAppointmentModalState
    extends State<WebNonMedicalAppointmentModal> {
  final notesController = TextEditingController();
  bool hasChanges = false;
  bool isSubmitting = false;

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<bool> _showDiscardDialog() async {
    if (!hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange[700], size: 24),
            const SizedBox(width: 12),
            const Text(
              'Discard Changes?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        content: const Text(
          'You have unsaved notes. If you close now, these will be lost.',
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
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Discard',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WebAppointmentController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return WillPopScope(
      onWillPop: _showDiscardDialog,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: isMobile ? screenWidth * 0.95 : 600,
          constraints: BoxConstraints(
            maxHeight:
                isMobile ? MediaQuery.of(context).size.height * 0.85 : 650,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(controller),
              const SizedBox(height: 20),

              // Service Info Banner
              _buildServiceInfoBanner(),
              const SizedBox(height: 24),

              // Notes Section
              Expanded(
                child: SingleChildScrollView(
                  child: _buildNotesSection(),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WebAppointmentController controller) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.content_cut,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complete Service',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 81, 115, 153),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Basic service for ${controller.getPetName(widget.appointment.petId)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () async {
            final shouldClose = await _showDiscardDialog();
            if (shouldClose) {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.close),
          iconSize: 24,
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _buildServiceInfoBanner() {
    final controller = Get.find<WebAppointmentController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Service Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.pets,
            'Pet',
            controller.getPetName(widget.appointment.petId),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.person_outline,
            'Owner',
            controller.getOwnerName(widget.appointment.userId),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.medical_services_outlined,
            'Service',
            widget.appointment.service,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.content_cut,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Basic Service',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.note_alt_outlined, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 8),
            const Text(
              'Service Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 81, 115, 153),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Add any notes about the service completion (Optional)',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: notesController,
            decoration: InputDecoration(
              hintText:
                  'Example: Service completed successfully. Pet was well-behaved...',
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 6,
            maxLength: 500,
            onChanged: (value) {
              if (!hasChanges && value.isNotEmpty) {
                setState(() {
                  hasChanges = true;
                });
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tip: Notes help provide context for future visits',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[900],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, WebAppointmentController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: isSubmitting
              ? null
              : () async {
                  final shouldClose = await _showDiscardDialog();
                  if (shouldClose) {
                    Navigator.of(context).pop();
                  }
                },
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text('Cancel'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey[700],
            side: BorderSide(color: Colors.grey[300]!),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: isSubmitting
              ? null
              : () async {
                  setState(() {
                    isSubmitting = true;
                  });

                  try {
                    // Close dialog first
                    Navigator.of(context).pop();

                    // Complete the non-medical service
                    await controller.completeNonMedicalService(
                      appointment: widget.appointment,
                      notes: notesController.text.trim().isNotEmpty
                          ? notesController.text.trim()
                          : null,
                    );
                  } catch (e) {
                    setState(() {
                      isSubmitting = false;
                    });
                    Get.snackbar(
                      'Error',
                      'Failed to complete service: $e',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
          icon: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.check_circle, size: 20),
          label: Text(isSubmitting ? 'Completing...' : 'Complete Service'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
        ),
      ],
    );
  }
}
