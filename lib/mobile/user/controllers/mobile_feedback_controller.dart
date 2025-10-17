import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/models/feedback_and_report_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:appwrite/models.dart' as models;

class MobileFeedbackController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  MobileFeedbackController({
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

  // ============= NOTIFICATION HELPER =============

  /// Show compact toast notification
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
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
    final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);

    if (!isImage && !isVideo) {
      _showError("Only images (JPG, PNG, GIF) and videos (MP4, MOV, AVI) allowed");
      return false;
    }

    // Check file size limits
    if (isImage && file.size > 5 * 1024 * 1024) {
      _showError("Image files must be under 5MB (${(file.size / (1024 * 1024)).toStringAsFixed(2)}MB)");
      return false;
    }

    if (isVideo && file.size > 25 * 1024 * 1024) {
      _showError("Video files must be under 25MB (${(file.size / (1024 * 1024)).toStringAsFixed(2)}MB)");
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
          'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp',
          'mp4', 'mov', 'avi', 'mkv', 'webm'
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
    selectedFiles.refresh();
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

    // Attachments are now OPTIONAL

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

      print('=== SUBMITTING FEEDBACK ===');
      print('User ID: $userId');
      print('User Name: $userName');
      print('User Email: $userEmail');

      if (userId.isEmpty) {
        _showError("User session data is missing. Please log in again.");
        isSubmitting.value = false;
        return false;
      }

      List<String> attachmentIds = [];

      // Upload attachments ONLY if files are selected (optional)
      if (selectedFiles.isNotEmpty) {
        _showInfo("Uploading ${selectedFiles.length} file(s)...");

        final uploadedFiles = await authRepository.uploadFeedbackAttachments(selectedFiles);
        attachmentIds = uploadedFiles.map((f) => f.$id).toList();

        print('Uploaded ${attachmentIds.length} attachments');
      } else {
        print('No attachments provided (optional)');
      }

      // Get device/platform info
      final platform = 'mobile';
      final appVersion = '1.0.0';
      final deviceInfo = 'Mobile Device';

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
        submittedAt: DateTime.now(),
      );

      print('Submitting feedback to database...');

      // Submit to database
      await authRepository.createFeedbackAndReport(feedback);

      print('Feedback submitted successfully');

      // Clear form
      clearForm();

      // Show success notification
      _showSuccess("Feedback submitted successfully");

      return true;
    } catch (e, stackTrace) {
      print('=== ERROR SUBMITTING FEEDBACK ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');

      _showError("Failed to submit feedback. Please try again.");
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Clear the feedback form completely
  void clearForm() {
    print('=== CLEARING FORM ===');
    
    // Clear text values
    subject.value = '';
    description.value = '';
    
    // Clear file selections
    selectedFiles.clear();
    
    // Reset to DEFAULT selections
    selectedType.value = FeedbackType.bug;
    selectedCategory.value = FeedbackCategory.other;
    
    // Force refresh
    subject.refresh();
    description.refresh();
    selectedFiles.refresh();
    selectedType.refresh();
    selectedCategory.refresh();
    
    print('Form cleared successfully');
    print('Type: ${selectedType.value.displayName}');
    print('Category: ${selectedCategory.value.displayName}');
    print('====================');
  }
}