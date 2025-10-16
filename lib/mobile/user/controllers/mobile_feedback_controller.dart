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

  /// Show compact snackbar notification
  void _showNotification(String message, Color bgColor, IconData icon) {
    Get.snackbar(
      '',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: bgColor,
      colorText: Colors.white,
      icon: Icon(icon, color: Colors.white),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(8),
      borderRadius: 8,
    );
  }

  void _showSuccess(String message) {
    _showNotification(message, Colors.green[600]!, Icons.check_circle_outline);
  }

  void _showError(String message) {
    _showNotification(message, Colors.red[600]!, Icons.error_outline);
  }

  void _showInfo(String message) {
    _showNotification(message, Colors.blue[600]!, Icons.info_outline);
  }

  void _showWarning(String message) {
    _showNotification(message, Colors.amber[700]!, Icons.warning_amber);
  }

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
      _showError("Image files must be under 5MB");
      return false;
    }

    if (isVideo && file.size > 25 * 1024 * 1024) {
      _showError("Video files must be under 25MB");
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
          _showWarning("Maximum 5 files allowed");
          break;
        }

        if (_validateFile(file)) {
          selectedFiles.add(file);
          print('Added file: ${file.name}'); // Debug
        }
      }
      
      // FORCE REFRESH TO ENSURE UI UPDATES
      selectedFiles.refresh();
      
      print('Total files: ${selectedFiles.length}'); // Debug
    }
  } catch (e) {
    print('Error picking files: $e'); // Debug
    _showError("Failed to pick files: $e");
  }
}

/// Remove a file from selection - UPDATED VERSION
void removeFile(PlatformFile file) {
  selectedFiles.remove(file);
  
  // FORCE REFRESH TO ENSURE UI UPDATES
  selectedFiles.refresh();
  
  print('Removed file. Total files: ${selectedFiles.length}'); // Debug
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

      print('=== SUBMITTING FEEDBACK ===');
      print('User ID: $userId');
      print('User Name: $userName');
      print('User Email: $userEmail');

      if (userId.isEmpty) {
        _showError("User session data is missing. Please log in again.");
        isSubmitting.value = false;
        return false;
      }

      // Upload attachments
      _showInfo("Uploading ${selectedFiles.length} file(s)...");

      final uploadedFiles = await authRepository.uploadFeedbackAttachments(selectedFiles);
      final attachmentIds = uploadedFiles.map((f) => f.$id).toList();

      print('Uploaded ${attachmentIds.length} attachments');

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
    selectedType.value = FeedbackType.bug; // ← First option
    selectedCategory.value = FeedbackCategory.other; // ← Default
    
    // Force refresh (this tells Obx to update)
    subject.refresh();
    description.refresh();
    selectedFiles.refresh();
    selectedType.refresh(); // ← Important for chips
    selectedCategory.refresh(); // ← Important for dropdown
    
    print('Form cleared successfully');
    print('Type: ${selectedType.value.displayName}');
    print('Category: ${selectedCategory.value.displayName}');
    print('====================');
  }
}