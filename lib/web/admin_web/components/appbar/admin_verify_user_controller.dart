import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/models/user_model.dart';
import 'package:capstone_app/data/models/id_verification_model.dart';
import 'package:get_storage/get_storage.dart';

class AdminVerifyUserController extends GetxController {
  final AuthRepository authRepository;
  final GetStorage storage = GetStorage();

  AdminVerifyUserController(this.authRepository);

  final isVerifying = false.obs;
  final errorMessage = ''.obs;

  /// Verify user manually by admin
  Future<bool> verifyUser(User user) async {
    try {
      print('>>> ============================================');
      print('>>> ADMIN VERIFY USER');
      print('>>> User ID: ${user.userId}');
      print('>>> User Name: ${user.name}');
      print('>>> ============================================');

      isVerifying.value = true;
      errorMessage.value = '';

      // Get admin's clinic ID
      final clinicId = storage.read('clinicId') as String?;
      final adminName = storage.read('name') as String? ?? 'Admin';

      if (clinicId == null || clinicId.isEmpty) {
        print('>>> ERROR: No clinic ID found');
        errorMessage.value = 'Admin clinic ID not found';
        return false;
      }

      print('>>> Clinic ID: $clinicId');
      print('>>> Admin: $adminName');

      // Step 1: Check if user already has a verification record
      print('>>> Step 1: Checking existing verification records...');
      final existingVerification =
          await authRepository.getIdVerificationByUserId(user.userId);

      IdVerification? verificationRecord;

      if (existingVerification != null) {
        print(
            '>>> Found existing verification record: ${existingVerification.documentId}');
        print('>>> Current status: ${existingVerification.status}');

        // Update existing record
        verificationRecord = existingVerification.copyWith(
          status: 'approved',
          verifyByClinic: clinicId,
          verifiedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        print('>>> Updating existing verification record...');
        await authRepository.updateIdVerification(verificationRecord);
        print('>>> ✓ Verification record updated');
      } else {
        print('>>> No existing verification record, creating new one...');

        // Create new verification record
        verificationRecord = IdVerification(
          userId: user.userId,
          email: user.email,
          status: 'approved',
          verifyByClinic: clinicId,
          verificationType: 'clinic_verified',
          verifiedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        print('>>> Creating new verification record...');
        await authRepository.createIdVerification(verificationRecord);
        print('>>> ✓ Verification record created');
      }

      // Step 2: Update user's verification status in Users collection
      print('>>> Step 2: Updating user verification status...');

      if (user.documentId == null || user.documentId!.isEmpty) {
        print('>>> ERROR: User document ID is null');
        errorMessage.value = 'User document ID not found';
        return false;
      }

      await authRepository.appWriteProvider.databases!.updateDocument(
        databaseId: AppwriteConstants.dbID,
        collectionId: AppwriteConstants.usersCollectionID,
        documentId: user.documentId!,
        data: {
          'idVerified': true,
          'idVerifiedAt': DateTime.now().toIso8601String(),
          'verificationDocumentId': verificationRecord.documentId,
        },
      );

      print('>>> ✓ User verification status updated');

      print('>>> ============================================');
      print('>>> USER VERIFICATION COMPLETE');
      print('>>> ✓ User ${user.name} verified by clinic $clinicId');
      print('>>> ============================================');

      return true;
    } catch (e) {
      print('>>> ============================================');
      print('>>> ERROR VERIFYING USER: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      print('>>> ============================================');

      errorMessage.value = 'Failed to verify user: ${e.toString()}';
      return false;
    } finally {
      isVerifying.value = false;
    }
  }

  /// Get verification details for a user
  Future<Map<String, dynamic>> getVerificationDetails(String userId) async {
    try {
      print('>>> Getting verification details for user: $userId');

      final verification =
          await authRepository.getIdVerificationByUserId(userId);

      if (verification == null) {
        return {
          'hasVerification': false,
          'status': 'not_verified',
          'isVerified': false,
        };
      }

      // Get clinic name if verified by clinic
      String? clinicName;
      if (verification.verifyByClinic != null &&
          verification.verifyByClinic!.isNotEmpty) {
        try {
          final clinicDoc = await authRepository.appWriteProvider.getClinicById(
            verification.verifyByClinic!,
          );
          if (clinicDoc != null) {
            clinicName = clinicDoc.data['clinicName'] ?? 'Unknown Clinic';
          }
        } catch (e) {
          print('>>> Warning: Could not fetch clinic name: $e');
        }
      }

      return {
        'hasVerification': true,
        'status': verification.status,
        'isVerified': verification.status == 'approved',
        'verifiedByClinic': verification.verifyByClinic,
        'clinicName': clinicName,
        'verifiedAt': verification.verifiedAt,
        'verificationType': verification.verificationType,
      };
    } catch (e) {
      print('>>> Error getting verification details: $e');
      return {
        'hasVerification': false,
        'status': 'error',
        'isVerified': false,
        'error': e.toString(),
      };
    }
  }

  /// Check if current admin's clinic already verified this user
  Future<bool> isVerifiedByCurrentClinic(String userId) async {
    try {
      final clinicId = storage.read('clinicId') as String?;
      if (clinicId == null) return false;

      final verification =
          await authRepository.getIdVerificationByUserId(userId);

      if (verification == null) return false;

      return verification.verifyByClinic == clinicId &&
          verification.status == 'approved';
    } catch (e) {
      print('>>> Error checking clinic verification: $e');
      return false;
    }
  }

  @override
  void onClose() {
    isVerifying.close();
    errorMessage.close();
    super.onClose();
  }
}
