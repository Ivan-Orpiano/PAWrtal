import 'package:flutter/material.dart';
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
 final Rxn<FeedbackStatus> statusFilter = Rxn<FeedbackStatus>();
final Rxn<FeedbackType> typeFilter = Rxn<FeedbackType>();
final Rxn<FeedbackCategory> categoryFilter = Rxn<FeedbackCategory>();
final Rxn<Priority> priorityFilter = Rxn<Priority>();
final RxString searchQuery = ''.obs;

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

  // ============= NOTIFICATION HELPER =============

  /// Show compact toast notification at top right
  void _showCompactNotification(String message,
      {required Color bgColor,
      required IconData icon,
      required Color iconColor}) {
    Get.rawSnackbar(
      messageText: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      snackPosition: SnackPosition.TOP,
      borderRadius: 4,
      margin: const EdgeInsets.only(top: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      duration: const Duration(seconds: 2),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      maxWidth: 300,
    );
  }

  void _showSuccess(String message) {
    _showCompactNotification(message,
        bgColor: Colors.green[600]!,
        icon: Icons.check_circle_outline,
        iconColor: Colors.white);
  }

  void _showError(String message) {
    _showCompactNotification(message,
        bgColor: Colors.red[600]!,
        icon: Icons.error_outline,
        iconColor: Colors.white);
  }

  void _showInfo(String message) {
    _showCompactNotification(message,
        bgColor: Colors.blue[600]!,
        icon: Icons.info_outline,
        iconColor: Colors.white);
  }

  void _showWarning(String message) {
    _showCompactNotification(message,
        bgColor: Colors.amber[700]!,
        icon: Icons.warning_amber,
        iconColor: Colors.white);
  }

  // ============= USER-SIDE METHODS =============

  /// Validate file before adding
  bool _validateFile(PlatformFile file) {
    final extension = file.extension?.toLowerCase() ?? '';

    // Check if it's an image or video
    final isImage =
        ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
    final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);

    if (!isImage && !isVideo) {
      _showError(
          "Only images (JPG, PNG, GIF) and videos (MP4, MOV, AVI) allowed");
      return false;
    }

    // Check file size limits
    if (isImage && file.size > 5 * 1024 * 1024) {
      _showError(
          "Image files must be under 5MB (${(file.size / (1024 * 1024)).toStringAsFixed(2)}MB)");
      return false;
    }

    if (isVideo && file.size > 25 * 1024 * 1024) {
      _showError(
          "Video files must be under 25MB (${(file.size / (1024 * 1024)).toStringAsFixed(2)}MB)");
      return false;
    }

    return true;
  }

  /// Pick files (images/videos)
  Future<void> pickFiles() async {
    if (selectedFiles.length >= 5) {
      _showError("You can only attach up to 5 files");
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'bmp',
          'mp4',
          'mov',
          'avi',
          'mkv',
          'webm'
        ],
        allowMultiple: true,
      );

      if (result != null) {
        for (var file in result.files) {
          if (selectedFiles.length >= 5) {
            _showWarning("Maximum 5 files allowed. Remaining files not added.");
            break;
          }

          if (_validateFile(file)) {
            selectedFiles.add(file);
          }
        }
      }
    } catch (e) {
      _showError("Failed to pick files: $e");
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
      _showError("Please enter a subject");
      return false;
    }

    if (subject.value.trim().length < 5) {
      _showError("Subject must be at least 5 characters long");
      return false;
    }

    if (description.value.trim().isEmpty) {
      _showError("Please provide details about your feedback");
      return false;
    }

    if (description.value.trim().length < 20) {
      _showError("Please provide at least 20 characters of description");
      return false;
    }

    if (selectedFiles.isEmpty) {
      _showError("Please attach at least one image or video");
      return false;
    }

    return true;
  }

  /// Submit feedback
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
        _showError("User session data is missing. Please log in again.");
        isSubmitting.value = false;
        return false;
      }

      // Upload attachments first
      _showInfo("Uploading ${selectedFiles.length} file(s)...");

      final uploadedFiles =
          await authRepository.uploadFeedbackAttachments(selectedFiles);
      final attachmentIds = uploadedFiles.map((f) => f.$id).toList();

      print('Uploaded ${attachmentIds.length} attachments: $attachmentIds');

      // Get device/platform info
      final platform = 'web';
      final appVersion = '1.0.0';
      final deviceInfo = 'Web Browser';
      final now = DateTime.now();

      // Create feedback object
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
      final createdFeedback =
          await authRepository.createFeedbackAndReport(feedback);

      print(
          'Feedback created successfully with ID: ${createdFeedback.documentId}');

      // Clear form COMPLETELY before showing success
      clearForm();

      // Show success notification
      _showSuccess("Feedback submitted successfully");

      return true;
    } catch (e, stackTrace) {
      print('=== ERROR SUBMITTING FEEDBACK ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('================================');

      _showError("Failed to submit feedback. Please try again.");
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Clear the feedback form completely
  void clearForm() {
    subject.value = '';
    description.value = '';
    selectedFiles.clear();
    selectedType.value = FeedbackType.bug;
    selectedCategory.value = FeedbackCategory.other;

    // Force refresh to ensure UI updates
    subject.refresh();
    description.refresh();
    selectedFiles.refresh();
    selectedType.refresh();
    selectedCategory.refresh();
  }

  /// Debug helper method
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
    } catch (e) {
      _showError("Failed to load feedback: $e");
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

        final subjectMatch = f.subject.toLowerCase().contains(query);
        final categoryMatch =
            f.category.displayName.toLowerCase().contains(query);
        final typeMatch =
            f.feedbackType.displayName.toLowerCase().contains(query);
        final nameMatch = f.userName.toLowerCase().contains(query);
        final emailMatch = f.userEmail.toLowerCase().contains(query);
        final descriptionMatch = f.description.toLowerCase().contains(query);

        return subjectMatch ||
            categoryMatch ||
            typeMatch ||
            nameMatch ||
            emailMatch ||
            descriptionMatch;
      }).toList();
    }

    // Apply status filter - Only filter if a specific status is selected (not null)
    if (statusFilter.value != null) {
      filtered = filtered.where((f) => f.status == statusFilter.value).toList();
    }
    // If statusFilter.value is null, show all statuses (no filtering)

    // Apply priority filter - Only filter if a specific priority is selected (not null)
    if (priorityFilter.value != null) {
      filtered =
          filtered.where((f) => f.priority == priorityFilter.value).toList();
    }
    // If priorityFilter.value is null, show all priorities (no filtering)

    // Apply type filter - Only filter if a specific type is selected (not null)
    if (typeFilter.value != null) {
      filtered =
          filtered.where((f) => f.feedbackType == typeFilter.value).toList();
    }
    // If typeFilter.value is null, show all types (no filtering)

    // Apply category filter - Only filter if a specific category is selected (not null)
    if (categoryFilter.value != null) {
      filtered =
          filtered.where((f) => f.category == categoryFilter.value).toList();
    }
    // If categoryFilter.value is null, show all categories (no filtering)

    // Sort by priority and date
    filtered.sort((a, b) {
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

      return b.submittedAt.compareTo(a.submittedAt);
    });

    filteredFeedback.value = filtered;
  }

  /// Update feedback statistics
  void updateStatistics() {
    feedbackStats.value = {
      'total': allFeedback.length,
      'pending':
          allFeedback.where((f) => f.status == FeedbackStatus.pending).length,
      'inProgress': allFeedback
          .where((f) => f.status == FeedbackStatus.inProgress)
          .length,
      'resolved':
          allFeedback.where((f) => f.status == FeedbackStatus.resolved).length,
      'closed':
          allFeedback.where((f) => f.status == FeedbackStatus.closed).length,
      'archived':
          allFeedback.where((f) => f.status == FeedbackStatus.archived).length,
      'critical':
          allFeedback.where((f) => f.priority == Priority.critical).length,
      'high': allFeedback.where((f) => f.priority == Priority.high).length,
    };
  }

  /// Update feedback status
  Future<void> updateStatus(String documentId, FeedbackStatus status) async {
    try {
      await authRepository.updateFeedbackStatus(documentId, status);

      final index = allFeedback.indexWhere((f) => f.documentId == documentId);
      if (index != -1) {
        allFeedback[index] = allFeedback[index].copyWith(status: status);
      }

      filterFeedback();
      updateStatistics();

      _showSuccess("Feedback status updated to ${status.displayName}");
    } catch (e) {
      _showError("Failed to update status: $e");
    }
  }

  /// Update feedback priority
  Future<void> updatePriority(String documentId, Priority priority) async {
    try {
      await authRepository.updateFeedbackPriority(documentId, priority);

      final index = allFeedback.indexWhere((f) => f.documentId == documentId);
      if (index != -1) {
        allFeedback[index] = allFeedback[index].copyWith(priority: priority);
      }

      filterFeedback();
      updateStatistics();

      _showSuccess("Feedback priority updated to ${priority.displayName}");
    } catch (e) {
      _showError("Failed to update priority: $e");
    }
  }

  /// Add admin reply
  Future<void> addReply(String documentId, String reply) async {
    try {
      final adminName = session.userName;
      await authRepository.addFeedbackReply(documentId, reply, adminName);

      await loadAllFeedback();

      _showSuccess("Reply sent successfully");
    } catch (e) {
      _showError("Failed to send reply: $e");
    }
  }

  /// Archive feedback
  Future<void> archiveFeedback(String documentId) async {
    try {
      final archivedBy = session.userName;
      await authRepository.archiveFeedback(documentId, archivedBy);

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

      _showSuccess("Feedback has been archived");
    } catch (e) {
      _showError("Failed to archive feedback: $e");
    }
  }

  /// Delete feedback permanently
  Future<void> deleteFeedback(
      String documentId, List<String> attachmentIds) async {
    try {
      await authRepository.deleteFeedback(documentId, attachmentIds);

      allFeedback.removeWhere((f) => f.documentId == documentId);

      filterFeedback();
      updateStatistics();

      _showSuccess("Feedback has been permanently deleted");
    } catch (e) {
      _showError("Failed to delete feedback: $e");
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    filterFeedback();
  }

  /// Update filters
/// Update filters
void updateFilters({
  FeedbackStatus? status,
  Priority? priority,
  FeedbackType? type,
  FeedbackCategory? category,
  bool clearStatus = false,
  bool clearPriority = false,
  bool clearType = false,
  bool clearCategory = false,
}) {
  // Clear filters if explicitly requested OR if null value is passed
  if (clearStatus || status == null) {
    statusFilter.value = null;
  } else {
    statusFilter.value = status;
  }
  
  if (clearPriority || priority == null) {
    priorityFilter.value = null;
  } else {
    priorityFilter.value = priority;
  }
  
  if (clearType || type == null) {
    typeFilter.value = null;
  } else {
    typeFilter.value = type;
  }
  
  if (clearCategory || category == null) {
    categoryFilter.value = null;
  } else {
    categoryFilter.value = category;
  }

  filterFeedback();
}

  /// Clear all filters
  void clearFilters() {
    statusFilter.value = null;
    priorityFilter.value = null;
    typeFilter.value = null;
    categoryFilter.value = null;
    searchQuery.value = '';
    filterFeedback();
  }

  /// Get attachment URL
  String getAttachmentUrl(String fileId) {
    return authRepository.getFeedbackAttachmentUrl(fileId);
  }
}
