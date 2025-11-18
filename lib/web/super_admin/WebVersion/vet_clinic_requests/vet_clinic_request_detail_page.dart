import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_requests/vet_clinic_requests_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/models/vet_clinic_registration_request_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_vet_clinic_register.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get_storage/get_storage.dart';

class VetClinicRequestDetailPage extends StatefulWidget {
  final VetClinicRegistrationRequest request;

  const VetClinicRequestDetailPage({
    super.key,
    required this.request,
  });

  @override
  State<VetClinicRequestDetailPage> createState() =>
      _VetClinicRequestDetailPageState();
}

class _VetClinicRequestDetailPageState
    extends State<VetClinicRequestDetailPage> {
  final AuthRepository authRepository = Get.find<AuthRepository>();
  final GetStorage storage = GetStorage();
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF517399)),
          onPressed: () => Get.back(),
        ),
        title: Image.asset(
          'lib/images/PAWrtal_logo.png',
          height: 35,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isMobile),
                const SizedBox(height: 24),
                _buildDetailsCard(isMobile),
                const SizedBox(height: 24),
                _buildDocumentsSection(isMobile),
                const SizedBox(height: 24),
                if (widget.request.reviewNotes != null &&
                    widget.request.reviewNotes!.isNotEmpty)
                  _buildReviewNotesSection(isMobile),
                if (widget.request.status == 'pending')
                  _buildActionButtons(isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF517399), Color(0xFF6B8EB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF517399).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.request.clinicName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Registration Request',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.request.statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.request.statusIcon,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      widget.request.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Clinic Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF517399),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.business_rounded,
            'Clinic Name',
            widget.request.clinicName,
            isMobile,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.location_on_rounded,
            'Location',
            widget.request.fullAddress,
            isMobile,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.phone_rounded,
            'Contact Number',
            widget.request.contactNumber,
            isMobile,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.email_rounded,
            'Email Address',
            widget.request.email,
            isMobile,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.calendar_today_rounded,
            'Submitted',
            DateFormat('MMMM dd, yyyy • hh:mm a')
                .format(widget.request.submittedAt),
            isMobile,
          ),
          if (widget.request.reviewedAt != null) ...[
            const Divider(height: 24),
            _buildDetailRow(
              Icons.check_circle_rounded,
              'Reviewed',
              DateFormat('MMMM dd, yyyy • hh:mm a')
                  .format(widget.request.reviewedAt!),
              isMobile,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF517399).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF517399), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_file_rounded, color: Color(0xFF517399)),
              const SizedBox(width: 8),
              const Text(
                'Uploaded Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF517399),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF517399).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.request.documentFileIds.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF517399),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.request.documentFileIds.isEmpty)
            const Text(
              'No documents uploaded',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...widget.request.documentFileIds.asMap().entries.map((entry) {
              final index = entry.key;
              final fileId = entry.value;
              return _buildDocumentCard(fileId, index + 1, isMobile);
            }),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String fileId, int index, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF517399).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Color(0xFF517399),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document $index',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'File ID: ${fileId.substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _viewDocument(fileId),
            icon: const Icon(Icons.visibility_rounded, size: 16),
            label: const Text('View'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF517399),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewNotesSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_rounded, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Text(
                'Review Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.request.reviewNotes!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF517399),
            ),
          ),
          const SizedBox(height: 16),
          if (isMobile)
            Column(
              children: [
                _buildRegisterButton(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildRejectButton()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildApproveButton()),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _buildRegisterButton()),
                const SizedBox(width: 12),
                _buildRejectButton(),
                const SizedBox(width: 12),
                _buildApproveButton(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isProcessing ? null : _registerClinic,
        icon: const Icon(Icons.app_registration_rounded),
        label: const Text('Register This Clinic'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF517399),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildApproveButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isProcessing ? null : () => _updateStatus('approved'),
        icon: const Icon(Icons.check_circle_rounded),
        label: const Text('Approve'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildRejectButton() {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: isProcessing ? null : () => _updateStatus('rejected'),
        icon: const Icon(Icons.cancel_rounded),
        label: const Text('Reject'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _viewDocument(String fileId) async {
    try {
      final url = authRepository.getVetRegistrationDocumentUrl(fileId);

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Error',
          'Could not open document',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open document: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    }
  }

  Future<void> _registerClinic() async {
    // Navigate to registration page with pre-filled data from request
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VetClinicRegister(
          preFilledRequest: widget.request,
        ),
      ),
    );

    // If registration was successful, mark as approved
    if (result == true) {
      // NEW: Directly update status and refresh controller
      setState(() => isProcessing = true);

      try {
        final userId = storage.read('userId') ?? '';

        await authRepository.updateVetRegistrationRequestStatus(
          widget.request.documentId!,
          'approved',
          userId,
          'Clinic registered successfully by super admin',
        );

        // Force controller refresh
        try {
          final controller = Get.find<VetClinicRequestsController>();
          await controller.refreshRequests();
        } catch (e) {
          print('Controller not found: $e');
        }

        Get.snackbar(
          'Success',
          'Clinic registered and request approved',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
        );

        Get.back(result: true); // Return to dashboard
      } catch (e) {
        Get.snackbar(
          'Error',
          'Clinic registered but failed to update request status: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
        );
      } finally {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
            newStatus == 'approved' ? 'Approve Request?' : 'Reject Request?'),
        content: Text(
          newStatus == 'approved'
              ? 'This will mark the request as approved. The clinic owner will need to be registered separately.'
              : 'This will reject the registration request. You can optionally add a note.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newStatus == 'approved' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(newStatus == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Get optional notes for rejection
    String? notes;
    if (newStatus == 'rejected') {
      notes = await _getReviewNotes();
      if (notes == null) return; // User cancelled
    }

    setState(() => isProcessing = true);

    try {
      final userId = storage.read('userId') ?? '';

      await authRepository.updateVetRegistrationRequestStatus(
        widget.request.documentId!,
        newStatus,
        userId,
        notes,
      );

      // ✅ FIX: Refresh the controller data FIRST
      try {
        final controller = Get.find<VetClinicRequestsController>();
        await controller.refreshRequests();
      } catch (e) {
        print('Controller not found: $e');
      }

      // ✅ FIX: Use the EXACT same navigation method as the back button
      // This is copied from your AppBar leading button
      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request has been $newStatus'),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate back using Get.back() - same as back button
      Get.back(result: true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<String?> _getReviewNotes() async {
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rejection Notes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejection:',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Enter reason for rejection...',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.of(dialogContext)
                  .pop(text.isEmpty ? 'No reason provided' : text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
