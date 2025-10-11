import 'package:flutter/material.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/id_verification/screens/id_verification_screen.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:get/get.dart';

/// Guard that checks if user is verified before allowing appointment booking
class AppointmentVerificationGuard {
  final AuthRepository _authRepository;

  AppointmentVerificationGuard(this._authRepository);

  /// Check if user can book appointments
  /// Returns true if user is verified or doesn't need verification
  /// Returns false and shows dialog if verification is required
  Future<bool> canBookAppointment({
    required BuildContext context,
    required String userId,
    required String email,
    required String userRole,
  }) async {
    try {
      print('>>> Checking if user can book appointment...');
      print('>>> User ID: $userId');
      print('>>> Role: $userRole');

      // Admin and staff don't need ID verification
      if (userRole == 'admin' || userRole == 'staff') {
        print('>>> Admin/Staff user - verification not required');
        return true;
      }

      // Check if user is verified
      final isVerified = await _authRepository.isUserIdVerified(userId);
      print('>>> User verified: $isVerified');

      if (isVerified) {
        return true;
      }

      // User is not verified - show dialog
      _showVerificationRequiredDialog(
        context: context,
        userId: userId,
        email: email,
      );

      return false;
    } catch (e) {
      print('>>> Error checking verification status: $e');

      // Show error snackbar
      CustomSnackBar.showErrorSnackBar(
        context: Get.overlayContext,
        title: "Error",
        message: "Unable to verify your account status. Please try again.",
      );

      return false;
    }
  }

  /// Show dialog informing user they need to verify their ID
  void _showVerificationRequiredDialog({
    required BuildContext context,
    required String userId,
    required String email,
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
              Icon(
                Icons.verified_user_outlined,
                color: const Color(0xFF1976D2),
                size: 32,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ID Verification Required',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To ensure the safety and security of our platform, you need to verify your identity before booking appointments.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verification Process:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBulletPoint('Provide a valid government ID'),
                    _buildBulletPoint('Take a selfie for verification'),
                    _buildBulletPoint('Wait for approval (usually instant)'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Maybe Later',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                // Navigate to ID verification screen
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => IdVerificationScreen(
                      userId: userId,
                      email: email,
                      authRepository: _authRepository,
                    ),
                  ),
                );

                // If verification was successful, show success message
                if (result == true) {
                  CustomSnackBar.showSuccessSnackBar(
                    context: Get.overlayContext,
                    title: "Success",
                    message:
                        "Your ID has been verified! You can now book appointments.",
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Verify Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Quick check without showing dialog
  /// Use this for conditional UI rendering
  Future<bool> isUserVerified(String userId, String userRole) async {
    try {
      // Admin and staff don't need verification
      if (userRole == 'admin' || userRole == 'staff') {
        return true;
      }

      return await _authRepository.isUserIdVerified(userId);
    } catch (e) {
      print('>>> Error checking verification: $e');
      return false;
    }
  }
}