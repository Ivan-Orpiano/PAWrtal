import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:appwrite/appwrite.dart';

class OAuthCallbackPage extends StatefulWidget {
  const OAuthCallbackPage({super.key});

  @override
  State<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends State<OAuthCallbackPage> {
  final _storage = GetStorage();
  late AppWriteProvider _appwriteProvider;
  late AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    
    // Initialize providers
    _appwriteProvider = Get.find<AppWriteProvider>();
    _authRepository = Get.find<AuthRepository>();
    
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      print('>>> ============================================');
      print('>>> OAUTH CALLBACK HANDLER START');
      print('>>> Current URL: ${Uri.base}');
      print('>>> ============================================');

      // Wait for Appwrite session to be fully established
      await Future.delayed(const Duration(milliseconds: 2000));

      // Step 1: Get authenticated user from Appwrite Auth
      print('>>> Step 1: Getting authenticated user...');
      final user = await _appwriteProvider.account!.get();

      if (user == null) {
        throw Exception('❌ User not found in Appwrite Auth after OAuth');
      }

      print('>>> ✅ User authenticated via OAuth');
      print('>>> User ID: ${user.$id}');
      print('>>> User Email: ${user.email}');
      print('>>> User Name: ${user.name}');

      // Step 2: Get current session
      print('>>> Step 2: Getting session...');
      final session = await _appwriteProvider.account!.getSession(sessionId: 'current');
      print('>>> ✅ Session ID: ${session.$id}');

      // Step 3: Check if user exists in Users database collection
      print('>>> Step 3: Checking if user exists in Users database...');
      final existingUserDoc = await _authRepository.getUserById(user.$id);

      if (existingUserDoc == null) {
        print('>>> ❌ User NOT found in database');
        print('>>> 📝 Creating new user record in Users collection...');

        // CRITICAL: Create user in database
        try {
          final newUserDoc = await _authRepository.createUser({
            "userId": user.$id,
            "name": user.name,
            "email": user.email,
            "role": "user", // Default role for Google OAuth users
            "phone": "", // Empty for OAuth users
            "profilePictureId": "", // Will be set later if user uploads
            "idVerified": false,
            "idVerifiedAt": null,
            "verificationDocumentId": null,
            "isArchived": false,
            "archivedAt": null,
            "archivedBy": null,
            "archiveReason": null,
            "archivedDocumentId": null,
          });

          print('>>> ✅ User created in database successfully!');
          print('>>> Document ID: ${newUserDoc.$id}');
          
          // Store document ID
          await _storage.write('userDocumentId', newUserDoc.$id);
          
        } catch (createError) {
          print('>>> ❌ ERROR creating user in database: $createError');
          throw Exception('Failed to create user in database: $createError');
        }
      } else {
        print('>>> ✅ User already exists in database (Sign-In flow)');
        print('>>> User Document ID: ${existingUserDoc.$id}');
        print('>>> Existing Role: ${existingUserDoc.data['role']}');
        
        // Store document ID
        await _storage.write('userDocumentId', existingUserDoc.$id);
        
        // Get profile picture if exists
        final profilePictureId = existingUserDoc.data['profilePictureId'] as String?;
        if (profilePictureId != null && profilePictureId.isNotEmpty) {
          await _storage.write('userProfilePictureId', profilePictureId);
          print('>>> Profile Picture ID: $profilePictureId');
        }
      }

      // Step 4: Store authentication info in GetStorage
      print('>>> Step 4: Storing session data...');
      await _storage.write('userId', user.$id);
      await _storage.write('sessionId', session.$id);
      await _storage.write('email', user.email);
      await _storage.write('userName', user.name);
      await _storage.write('role', 'user'); // OAuth users are always "user" role

      print('>>> ============================================');
      print('>>> STORAGE SUMMARY:');
      print('>>> - userId: ${_storage.read("userId")}');
      print('>>> - sessionId: ${_storage.read("sessionId")}');
      print('>>> - email: ${_storage.read("email")}');
      print('>>> - userName: ${_storage.read("userName")}');
      print('>>> - role: ${_storage.read("role")}');
      print('>>> - userDocumentId: ${_storage.read("userDocumentId")}');
      print('>>> ============================================');

      // Step 5: Navigate to user home
      print('>>> Step 5: Navigating to home...');
      
      // Small delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navigate and clear navigation stack
      Get.offAllNamed(Routes.userHome);
      
      print('>>> ✅ OAuth flow completed successfully!');
      print('>>> ============================================');

    } catch (e, stackTrace) {
      print('>>> ============================================');
      print('>>> ❌ OAUTH CALLBACK ERROR');
      print('>>> Error: $e');
      print('>>> Stack trace: $stackTrace');
      print('>>> ============================================');

      // Show error dialog
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Authentication Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to complete Google Sign-In. Please try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Get.back(); // Close dialog
                      Get.offAllNamed(Routes.login); // Go to login
                    },
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'lib/images/PAWrtal_logo.png',
              height: 80,
              width: 200,
            ),
            const SizedBox(height: 32),
            
            // Loading indicator
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(255, 81, 115, 153),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Status text
            Text(
              'Completing Google Sign-In...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtext
            Text(
              'Please wait while we set up your account',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}