import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';

class OAuthCallbackPage extends StatefulWidget {
  const OAuthCallbackPage({super.key});

  @override
  State<OAuthCallbackPage> createState() => _OAuthCallbackPageState();
}

class _OAuthCallbackPageState extends State<OAuthCallbackPage> {
  final _storage = GetStorage();
  final _appwriteProvider = AppWriteProvider();

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      print('>>> ============================================');
      print('>>> OAUTH CALLBACK HANDLER');
      print('>>> ============================================');

      // Wait a bit for session to be established
      await Future.delayed(const Duration(seconds: 1));

      // Get current user
      final user = await _appwriteProvider.getUser();

      if (user != null) {
        print('>>> User authenticated: ${user.email}');

        // Store user info
        await _storage.write('userId', user.$id);
        await _storage.write('email', user.email);
        await _storage.write('userName', user.name);
        await _storage.write('role', 'user'); // Default role for Google sign-in

        // Get session
        final session = await _appwriteProvider.account!.getSession(sessionId: 'current');
        await _storage.write('sessionId', session.$id);

        print('>>> Redirecting to home...');
        
        // Navigate to home
        Get.offAllNamed(Routes.userHome);
      } else {
        throw Exception('User not found after OAuth');
      }
    } catch (e) {
      print('>>> OAuth callback error: $e');
      
      // Navigate to login with error message
      Get.offAllNamed(Routes.login);
      Get.snackbar(
        'Authentication Error',
        'Failed to complete Google Sign-In',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Completing Google Sign-In...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}