import 'package:get/get.dart';
import 'package:capstone_app/data/models/feedback_deletion_request_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';

class VetDeletionRequestController extends GetxController {
  final AuthRepository authRepository;

  VetDeletionRequestController({required this.authRepository});

  // Observable lists
  var allRequests = <FeedbackDeletionRequest>[].obs;
  var filteredRequests = <FeedbackDeletionRequest>[].obs;

  // Loading states
  var isLoading = false.obs;
  var isProcessing = false.obs;

  // Filter states
  var selectedStatus = 'All'.obs;
  var selectedReason = 'All'.obs;
  var searchQuery = ''.obs;

  // Statistics
  var stats = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllDeletionRequests();
  }

  /// Load all deletion requests from all clinics
  Future<void> loadAllDeletionRequests() async {
    try {
      isLoading.value = true;

      // Get all clinics first
      final clinics = await authRepository.getAllClinics();

      List<FeedbackDeletionRequest> allRequestsTemp = [];

      // Fetch deletion requests for each clinic
      for (var clinic in clinics) {
        if (clinic.documentId != null) {
          final requests = await authRepository.getClinicDeletionRequests(
            clinic.documentId!,
          );

          // Add clinic name to each request for display
          for (var request in requests.cast<FeedbackDeletionRequest>()) {
            // Store clinic name in a way we can access it
            allRequestsTemp.add(request); 
          }                                            
        }
      }

      allRequests.value = allRequestsTemp;
      filterRequests();
      calculateStatistics();
    } catch (e) {
      print('Error loading deletion requests: $e');
      _showSnackBar('Failed to load deletion requests: $e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  /// Filter requests based on search, status, and reason
  void filterRequests() {
    filteredRequests.value = allRequests.where((request) {
      // Search filter
      bool matchesSearch = searchQuery.value.isEmpty ||
          request.reason
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()) ||
          request.clinicId
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()) ||
          request.requestedBy
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase());

      // Status filter
      bool matchesStatus = selectedStatus.value == 'All' ||
          request.status.toLowerCase() == selectedStatus.value.toLowerCase();

      // Reason filter
      bool matchesReason = selectedReason.value == 'All' ||
          request.reason == selectedReason.value;

      return matchesSearch && matchesStatus && matchesReason;
    }).toList();

    // Sort by date (newest first)
    filteredRequests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  /// Calculate statistics
  void calculateStatistics() {
    stats.value = {
      'total': allRequests.length,
      'pending': allRequests.where((r) => r.status == 'pending').length,
      'approved': allRequests.where((r) => r.status == 'approved').length,
      'rejected': allRequests.where((r) => r.status == 'rejected').length,
    };
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query.toLowerCase();
    filterRequests();
  }

  /// Update status filter
  void updateStatusFilter(String status) {
    selectedStatus.value = status;
    filterRequests();
  }

  /// Update reason filter
  void updateReasonFilter(String reason) {
    selectedReason.value = reason;
    filterRequests();
  }

  /// Approve deletion request
  Future<void> approveDeletionRequest(
    FeedbackDeletionRequest request,
    String reviewedBy,
    String? reviewNotes,
  ) async {
    try {
      isProcessing.value = true;

      final result = await authRepository.approveDeletionRequest(
        request.documentId!,
        request.reviewId,
        reviewedBy,
        reviewNotes,
      );

      if (result['success'] == true) {
        _showSnackBar('Deletion request approved successfully', Colors.green);
        await loadAllDeletionRequests(); // Reload data
      } else {
        _showSnackBar('Failed to approve request', Colors.red);
      }
    } catch (e) {
      print('Error approving deletion request: $e');
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      isProcessing.value = false;
    }
  }

  /// Reject deletion request
  Future<void> rejectDeletionRequest(
    FeedbackDeletionRequest request,
    String reviewedBy,
    String? reviewNotes,
  ) async {
    try {
      isProcessing.value = true;

      final result = await authRepository.rejectDeletionRequest(
        request.documentId!,
        reviewedBy,
        reviewNotes,
      );

      if (result['success'] == true) {
        _showSnackBar('Deletion request rejected', Colors.orange);
        await loadAllDeletionRequests(); // Reload data
      } else {
        _showSnackBar('Failed to reject request', Colors.red);
      }
    } catch (e) {
      print('Error rejecting deletion request: $e');
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      isProcessing.value = false;
    }
  }

  /// Delete a processed request (approved/rejected)
  Future<void> deleteProcessedRequest(FeedbackDeletionRequest request) async {
    try {
      isProcessing.value = true;

      // Note: You'll need to add this method to your provider
      // await authRepository.deleteFeedbackDeletionRequest(request.documentId!);

      allRequests.removeWhere((r) => r.documentId == request.documentId);
      filterRequests();
      calculateStatistics();

      _showSnackBar('Request deleted successfully', Colors.green);
    } catch (e) {
      print('Error deleting request: $e');
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      isProcessing.value = false;
    }
  }

  /// Get clinic name by ID
  Future<String> getClinicName(String clinicId) async {
    try {
      final clinic = await authRepository.getClinicById(clinicId);
      return clinic?.data['clinicName'] ?? 'Unknown Clinic';
    } catch (e) {
      return 'Unknown Clinic';
    }
  }

  void _showSnackBar(String message, Color color) {
    Get.snackbar(
      color == Colors.red ? 'Error' : 'Success',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}
