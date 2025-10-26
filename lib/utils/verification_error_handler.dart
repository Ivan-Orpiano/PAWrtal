import 'package:flutter/material.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:get/get.dart';

/// Centralized error handling for ID verification
class VerificationErrorHandler {
  /// Handle errors during verification process
  static void handleVerificationError({
    required BuildContext context,
    required dynamic error,
    String? customMessage,
  }) {
    print('>>> Verification Error: $error');

    String title = 'Verification Error';
    String message = customMessage ?? _getErrorMessage(error);

    CustomSnackBar.showErrorSnackBar(
      context: Get.overlayContext ?? context,
      title: title,
      message: message,
    );
  }

  /// Handle network errors specifically
  static void handleNetworkError(BuildContext context) {
    CustomSnackBar.showErrorSnackBar(
      context: Get.overlayContext ?? context,
      title: 'Connection Error',
      message: 'Please check your internet connection and try again.',
    );
  }

  /// Handle timeout errors
  static void handleTimeoutError(BuildContext context) {
    CustomSnackBar.showErrorSnackBar(
      context: Get.overlayContext ?? context,
      title: 'Request Timeout',
      message: 'The verification process took too long. Please try again.',
    );
  }

  /// Handle ARGOS API errors
  static void handleArgosApiError({
    required BuildContext context,
    required int statusCode,
    String? errorMessage,
  }) {
    String title = 'Verification Service Error';
    String message;

    switch (statusCode) {
      case 400:
        message =
            'Invalid request. Please check your information and try again.';
        break;
      case 401:
        message = 'Authentication failed. Please contact support.';
        break;
      case 403:
        message =
            'Access denied. This feature may not be available for your account.';
        break;
      case 404:
        message = 'Verification service not found. Please contact support.';
        break;
      case 429:
        message =
            'Too many verification attempts. Please wait a moment and try again.';
        break;
      case 500:
      case 502:
      case 503:
        message =
            'Verification service is temporarily unavailable. Please try again later.';
        break;
      default:
        message =
            errorMessage ?? 'An unexpected error occurred. Please try again.';
    }

    CustomSnackBar.showErrorSnackBar(
      context: Get.overlayContext ?? context,
      title: title,
      message: message,
    );
  }

  /// Handle Appwrite errors
  static void handleAppwriteError({
    required BuildContext context,
    required dynamic error,
  }) {
    print('>>> Appwrite Error: $error');

    String message = 'Failed to save verification data. Please try again.';

    if (error.toString().contains('permission')) {
      message = 'Permission denied. Please contact support.';
    } else if (error.toString().contains('network')) {
      message = 'Network error. Please check your connection.';
    } else if (error.toString().contains('document not found')) {
      message =
          'Verification record not found. Please start a new verification.';
    }

    CustomSnackBar.showErrorSnackBar(
      context: Get.overlayContext ?? context,
      title: 'Database Error',
      message: message,
    );
  }

  /// NEW: Show name mismatch dialog
  static void showNameMismatchDialog({
    required BuildContext context,
    required String accountName,
    required String idName,
    String? additionalInfo,
    required VoidCallback onUpdateAccountName,
    required VoidCallback onRetry,
    required VoidCallback onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFFF9800),
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Name Mismatch',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The name on your account does not match the name on your ID.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFF9800),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 18,
                            color: Color(0xFFFF9800),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Account Name:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: Text(
                          accountName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 18,
                            color: Color(0xFFFF9800),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ID Name:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: Text(
                          idName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (additionalInfo != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF1976D2),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            additionalInfo,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'To resolve this:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildActionItem(
                  '1. Update your account name to match your ID exactly',
                  Icons.edit_outlined,
                ),
                _buildActionItem(
                  '2. OR verify again with an ID that matches your account name',
                  Icons.refresh_rounded,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onCancel();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onRetry();
              },
              child: const Text('Verify Again'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onUpdateAccountName();
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Update Name'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show verification rejected dialog (updated with name mismatch handling)
  static void showRejectedDialog({
    required BuildContext context,
    String? reason,
    bool isNameMismatch = false,
    String? accountName,
    String? idName,
    required VoidCallback onRetry,
    VoidCallback? onUpdateAccountName,
    required VoidCallback onCancel,
  }) {
    // If it's a name mismatch, show specialized dialog
    if (isNameMismatch && accountName != null && idName != null && onUpdateAccountName != null) {
      showNameMismatchDialog(
        context: context,
        accountName: accountName,
        idName: idName,
        additionalInfo: 'Your account information must match your government ID for security purposes.',
        onUpdateAccountName: onUpdateAccountName,
        onRetry: onRetry,
        onCancel: onCancel,
      );
      return;
    }

    // Otherwise show regular rejection dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.cancel_outlined,
                color: Color(0xFFF44336),
                size: 32,
              ),
              SizedBox(width: 12),
              Text('Verification Rejected'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your ID verification was not successful.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (reason != null && reason.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reason,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Common reasons for rejection:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildRejectionTip('ID document is blurry or unclear'),
              _buildRejectionTip('ID document is expired'),
              _buildRejectionTip('Photo doesn\'t match the ID'),
              _buildRejectionTip('Document is damaged or tampered'),
              _buildRejectionTip('Account name doesn\'t match ID name'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onCancel();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  /// Show pending verification dialog
  static void showPendingDialog({
    required BuildContext context,
    required VoidCallback onClose,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.hourglass_empty,
                color: Color(0xFFFF9800),
                size: 32,
              ),
              SizedBox(width: 12),
              Text('Verification Pending'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your ID verification is being reviewed.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'This usually takes a few minutes. You will receive a notification once the verification is complete.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onClose();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Got It'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildActionItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1976D2)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildRejectionTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Get user-friendly error message from error object
  static String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('socket')) {
      return 'Network connection error. Please check your internet and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('permission')) {
      return 'Permission denied. Please check your app permissions.';
    } else if (errorString.contains('camera')) {
      return 'Camera access is required for verification. Please grant camera permission.';
    } else if (errorString.contains('not found')) {
      return 'Resource not found. Please try again.';
    } else if (errorString.contains('name') && errorString.contains('match')) {
      return 'The name on your account does not match your ID. Please update your account name or verify with a matching ID.';
    } else {
      return 'An unexpected error occurred. Please try again or contact support.';
    }
  }

  /// Show generic error dialog
  static void showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFF44336),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            if (onCancel != null)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onCancel();
                },
                child: const Text('Cancel'),
              ),
            if (onRetry != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onRetry();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              )
            else
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
          ],
        );
      },
    );
  }
}