import 'package:get/get.dart';
import 'package:capstone_app/data/models/feedback_and_report_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/user_web/services/web_snack_bar_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:appwrite/models.dart' as models;

class WebFeedbackController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  WebFeedbackController({
    required this.authRepository,
    required this.session,
  });

  // User-side properties
  RxList<PlatformFile> selectedFiles = <PlatformFile>[].obs;
  RxBool isSubmitting = false.obs;
  Rx<FeedbackType> selectedType = FeedbackType.bug.obs;
  Rx<FeedbackCategory> selectedCategory = FeedbackCategory.other.obs;
  RxString subject = ''.obs;
  RxString description = ''.obs;

  // Admin-side properties
  RxList<FeedbackAndReport> allFeedback = <FeedbackAndReport>[].obs;
  RxList<FeedbackAndReport> filteredFeedback = <FeedbackAndReport>[].obs;
  RxBool isLoadingFeedback = false.obs;
  Rx<FeedbackStatus?> statusFilter = Rx<FeedbackStatus?>(null);
  Rx<Priority?> priorityFilter = Rx<Priority?>(null);
  Rx<FeedbackType?> typeFilter = Rx<FeedbackType?>(null);
  RxString searchQuery = ''.obs;

  // Statistics
  RxMap<String, int> feedbackStats = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Only load feedback if user is admin/staff
    final role = session.userRole;
    if (role == 'admin' || role == 'staff') {
      loadAllFeedback();
    }
  }

  // ============= USER-SIDE METHODS =============

  /// Validate file before adding
  bool _validateFile(PlatformFile file) {
    final extension = file.extension?.toLowerCase() ?? '';
    
    // Check if it's an image or video
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
    final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);
    
    if (!isImage && !isVideo) {
      WebSnackBarService.showError(
        title: "Invalid File",
        message: "Only images (JPG, PNG, GIF) and videos (MP4, MOV, AVI) are allowed",
      );
      return false;
    }

    // Check file size limits
    if (isImage && file.size > 5 * 1024 * 1024) {
      WebSnackBarService.showError(
        title: "File Too Large",
        message: "Image files must be under 5MB. File size: ${(file.size / (1024 * 1024)).toStringAsFixed(2)}MB",
      );
      return false;
    }

    if (isVideo && file.size > 25 * 1024 * 1024) {
      WebSnackBarService.showError(
        title: "File Too Large",
        message: "Video files must be under 25MB. File size: ${(file.size / (1024 * 1024)).toStringAsFixed(2)}MB",
      );
      return false;
    }

    return true;
  }

  /// Pick files (images/videos)
  Future<void> pickFiles() async {
    if (selectedFiles.length >= 5) {
      WebSnackBarService.showError(
        title: "Limit Reached",
        message: "You can only attach up to 5 files",
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'mp4', 'mov', 'avi', 'mkv', 'webm'],
        allowMultiple: true,
      );

      if (result != null) {
        for (var file in result.files) {
          if (selectedFiles.length >= 5) {
            WebSnackBarService.showWarning(
              title: "Limit Reached",
              message: "Maximum 5 files allowed. Remaining files not added.",
            );
            break;
          }

          if (_validateFile(file)) {
            selectedFiles.add(file);
          }
        }
      }
    } catch (e) {
      WebSnackBarService.showError(
        title: "Error",
        message: "Failed to pick files: $e",
      );
    }
  }

  /// Remove a file from selection
  void removeFile(PlatformFile file) {
    selectedFiles.remove(file);
  }

  /// Clear all selected files
  void clearFiles() {
    selectedFiles.clear();
  }

  /// Get file icon based on extension
  String getFileIcon(String? extension) {
    final ext = extension?.toLowerCase() ?? '';
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
      return '🖼️';
    } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
      return '🎥';
    }
    return '📄';
  }

  /// Get file size in readable format
  String getFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Validate feedback form
  bool validateForm() {
    if (subject.value.trim().isEmpty) {
      WebSnackBarService.showError(
        title: "Required Field",
        message: "Please enter a subject",
      );
      return false;
    }

    if (subject.value.trim().length < 5) {
      WebSnackBarService.showError(
        title: "Invalid Subject",
        message: "Subject must be at least 5 characters long",
      );
      return false;
    }

    if (description.value.trim().isEmpty) {
      WebSnackBarService.showError(
        title: "Required Field",
        message: "Please provide details about your feedback",
      );
      return false;
    }

    if (description.value.trim().length < 20) {
      WebSnackBarService.showError(
        title: "More Details Needed",
        message: "Please provide at least 20 characters of description",
      );
      return false;
    }

    if (selectedFiles.isEmpty) {
      WebSnackBarService.showError(
        title: "Required Attachment",
        message: "Please attach at least one image or video",
      );
      return false;
    }

    return true;
  }

  /// Submit feedback
/// Submit feedback - FIXED VERSION
Future<bool> submitFeedback() async {
  if (!validateForm()) return false;

  isSubmitting.value = true;

  try {
    // Get user information
    final userId = session.userId;
    final userName = session.userName;
    final userEmail = session.userEmail;
    
    // DEBUG: Print to verify data
    print('=== SUBMITTING FEEDBACK ===');
    print('User ID: $userId');
    print('User Name: $userName');
    print('User Email: $userEmail');
    print('Subject: ${subject.value}');
    print('Description: ${description.value}');
    print('Type: ${selectedType.value}');
    print('Category: ${selectedCategory.value}');
    print('Files: ${selectedFiles.length}');
    
    // Validate user data exists
    if (userId.isEmpty) {
      WebSnackBarService.showError(
        title: "Session Error",
        message: "User session data is missing. Please log in again.",
      );
      isSubmitting.value = false;
      return false;
    }

    // Upload attachments first
    WebSnackBarService.showInfo(
      title: "Uploading",
      message: "Uploading ${selectedFiles.length} file(s)...",
    );

    final uploadedFiles = await authRepository.uploadFeedbackAttachments(selectedFiles);
    final attachmentIds = uploadedFiles.map((f) => f.$id).toList();

    print('Uploaded ${attachmentIds.length} attachments: $attachmentIds');

    // Get device/platform info
    final platform = 'web';
    final appVersion = '1.0.0';
    final deviceInfo = 'Web Browser';
    final now = DateTime.now();

    // Create feedback object - ensure ALL required fields are present
    final feedback = FeedbackAndReport(
      userId: userId,
      userName: userName.isNotEmpty ? userName : 'Unknown User',
      userEmail: userEmail.isNotEmpty ? userEmail : 'unknown@email.com',
      feedbackType: selectedType.value,
      category: selectedCategory.value,
      subject: subject.value.trim(),
      description: description.value.trim(),
      attachments: attachmentIds,
      priority: Priority.medium,
      status: FeedbackStatus.pending,
      appVersion: appVersion,
      deviceInfo: deviceInfo,
      platform: platform,
      submittedAt: now,
    );

    print('Feedback object created, submitting to database...');
    print('Feedback data map: ${feedback.toMap()}');

    // Submit to database
    final createdFeedback = await authRepository.createFeedbackAndReport(feedback);
    
    print('Feedback created successfully with ID: ${createdFeedback.documentId}');

    // Clear form only after successful submission
    clearForm();

    WebSnackBarService.showSuccess(
      title: "Success",
      message: "Thank you! Your feedback has been submitted successfully.",
    );

    return true;
  } catch (e, stackTrace) {
    print('=== ERROR SUBMITTING FEEDBACK ===');
    print('Error: $e');
    print('Stack trace: $stackTrace');
    print('================================');
    
    WebSnackBarService.showError(
      title: "Submission Failed",
      message: "Failed to submit feedback. Please try again.",
    );
    return false;
  } finally {
    isSubmitting.value = false;
  }
}

// Also add this helper method to check the toMap output
void debugFeedbackData() {
  print('=== FEEDBACK FORM DATA ===');
  print('Subject: ${subject.value}');
  print('Description: ${description.value}');
  print('Type: ${selectedType.value}');
  print('Category: ${selectedCategory.value}');
  print('Files: ${selectedFiles.length}');
  print('User ID: ${session.userId}');
  print('User Name: ${session.userName}');
  print('User Email: ${session.userEmail}');
  print('========================');
}

  /// Clear the feedback form
  void clearForm() {
    subject.value = '';
    description.value = '';
    selectedFiles.clear();
    selectedType.value = FeedbackType.bug;
    selectedCategory.value = FeedbackCategory.other;
  }

  // ============= ADMIN-SIDE METHODS =============

  /// Load all feedback for admin
  Future<void> loadAllFeedback() async {
    isLoadingFeedback.value = true;

    try {
      final feedback = await authRepository.getAllFeedback(
        status: statusFilter.value,
        priority: priorityFilter.value,
      );

      allFeedback.value = feedback;
      filterFeedback();
      updateStatistics();

      WebSnackBarService.showSuccess(
        title: "Loaded",
        message: "Feedback loaded successfully",
      );
    } catch (e) {
      WebSnackBarService.showError(
        title: "Error",
        message: "Failed to load feedback: $e",
      );
    } finally {
      isLoadingFeedback.value = false;
    }
  }

  /// Filter feedback based on current filters
  void filterFeedback() {
    var filtered = allFeedback.toList();

    // Apply search query
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((f) {
        final query = searchQuery.value.toLowerCase();
        return f.subject.toLowerCase().contains(query) ||
            f.description.toLowerCase().contains(query) ||
            f.userName.toLowerCase().contains(query) ||
            f.userEmail.toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filter
    if (statusFilter.value != null) {
      filtered = filtered.where((f) => f.status == statusFilter.value).toList();
    }

    // Apply priority filter
    if (priorityFilter.value != null) {
      filtered = filtered.where((f) => f.priority == priorityFilter.value).toList();
    }

    // Apply type filter
    if (typeFilter.value != null) {
      filtered = filtered.where((f) => f.feedbackType == typeFilter.value).toList();
    }

    // Sort by priority and date
    filtered.sort((a, b) {
      // First sort by priority
      final priorityOrder = {
        Priority.critical: 0,
        Priority.high: 1,
        Priority.medium: 2,
        Priority.low: 3,
      };
      
      final aPriority = priorityOrder[a.priority] ?? 999;
      final bPriority = priorityOrder[b.priority] ?? 999;
      
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      
      // Then sort by date (newest first)
      return b.submittedAt.compareTo(a.submittedAt);
    });

    filteredFeedback.value = filtered;
  }

  /// Update feedback statistics
  void updateStatistics() {
    feedbackStats.value = {
      'total': allFeedback.length,
      'pending': allFeedback.where((f) => f.status == FeedbackStatus.pending).length,
      'inProgress': allFeedback.where((f) => f.status == FeedbackStatus.inProgress).length,
      'resolved': allFeedback.where((f) => f.status == FeedbackStatus.resolved).length,
      'closed': allFeedback.where((f) => f.status == FeedbackStatus.closed).length,
      'archived': allFeedback.where((f) => f.status == FeedbackStatus.archived).length,
      'critical': allFeedback.where((f) => f.priority == Priority.critical).length,
      'high': allFeedback.where((f) => f.priority == Priority.high).length,
    };
  }

  /// Update feedback status
  Future<void> updateStatus(String documentId, FeedbackStatus status) async {
    try {
      await authRepository.updateFeedbackStatus(documentId, status);
      
      // Update local list
      final index = allFeedback.indexWhere((f) => f.documentId == documentId);
      if (index != -1) {
        allFeedback[index] = allFeedback[index].copyWith(status: status);
      }
      
      filterFeedback();
      updateStatistics();

      WebSnackBarService.showSuccess(
        title: "Updated",
        message: "Feedback status updated to ${status.displayName}",
      );
    } catch (e) {
      WebSnackBarService.showError(
        title: "Error",
        message: "Failed to update status: $e",
      );
    }
  }

  /// Update feedback priority
  Future<void> updatePriority(String documentId, Priority priority) async {
    try {
      await authRepository.updateFeedbackPriority(documentId, priority);
      
      // Update local list
      final index = allFeedback.indexWhere((f) => f.documentId == documentId);
      if (index != -1) {
        allFeedback[index] = allFeedback[index].copyWith(priority: priority);
      }
      
      filterFeedback();
      updateStatistics();

      WebSnackBarService.showSuccess(
        title: "Updated",
        message: "Feedback priority updated to ${priority.displayName}",
      );
    } catch (e) {
      WebSnackBarService.showError(
        title: "Error",
        message: "Failed to update priority: $e",
      );
    }
  }

  /// Add admin reply
  Future<void> addReply(String documentId, String reply) async {
    try {
      final adminName = session.userName;
      await authRepository.addFeedbackReply(documentId, reply, adminName);
      
      // Reload feedback
      await loadAllFeedback();

      WebSnackBarService.showSuccess(
        title: "Reply Sent",
        message: "Your reply has been sent successfully",
      );
    } catch (e) {
      WebSnackBarService.showError(
        title: "Error",
        message: "Failed to send reply: $e",
      );
    }
  }

  /// Archive feedback
  Future<void> archiveFeedback(String documentId) async {
    try {
      final archivedBy = session.userName;
      await authRepository.archiveFeedback(documentId, archivedBy);
      
      // Update local list
      final index = allFeedback.indexWhere((f) => f.documentId == documentId);
      if (index != -1) {
        allFeedback[index] = allFeedback[index].copyWith(
          status: FeedbackStatus.archived,
          archivedAt: DateTime.now(),
          archivedBy: archivedBy,
        );
      }
      
      filterFeedback();
      updateStatistics();

      WebSnackBarService.showSuccess(
        title: "Archived",
        message: "Feedback has been archived",
      );
    } catch (e) {
      WebSnackBarService.showError(
        title: "Error",
        message: "Failed to archive feedback: $e",
      );
    }
  }

  /// Delete feedback permanently
  Future<void> deleteFeedback(String documentId, List<String> attachmentIds) async {
    try {
      await authRepository.deleteFeedback(documentId, attachmentIds);
      
      // Remove from local list
      allFeedback.removeWhere((f) => f.documentId == documentId);
      
      filterFeedback();
      updateStatistics();

      WebSnackBarService.showSuccess(
        title: "Deleted",
        message: "Feedback has been permanently deleted",
      );
    } catch (e) {
      WebSnackBarService.showError(
        title: "Error",
        message: "Failed to delete feedback: $e",
      );
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    filterFeedback();
  }

  /// Update filters
  void updateFilters({
    FeedbackStatus? status,
    Priority? priority,
    FeedbackType? type,
  }) {
    if (status != null) statusFilter.value = status;
    if (priority != null) priorityFilter.value = priority;
    if (type != null) typeFilter.value = type;
    
    filterFeedback();
  }

  /// Clear all filters
  void clearFilters() {
    statusFilter.value = null;
    priorityFilter.value = null;
    typeFilter.value = null;
    searchQuery.value = '';
    filterFeedback();
  }

  /// Get attachment URL
  String getAttachmentUrl(String fileId) {
    return authRepository.getFeedbackAttachmentUrl(fileId);
  }
}