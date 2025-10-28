import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/id_verification/services/argos_service.dart';
import 'package:capstone_app/data/models/id_verification_model.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class IdVerificationScreen extends StatefulWidget {
  final String userId;
  final String email;
  final AuthRepository authRepository;

  const IdVerificationScreen({
    Key? key,
    required this.userId,
    required this.email,
    required this.authRepository,
  }) : super(key: key);

  @override
  State<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends State<IdVerificationScreen> {
  final ArgosService _argosService = ArgosService();
  bool _isLoading = true;
  String? _verificationUrl;
  IdVerification? _currentVerification;
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _handleWebPlatform();
    } else {
      _initializeVerification();
    }
  }

  Future<void> _requestCameraPermission() async {
    try {
      print('>>> Requesting camera permission...');

      final status = await Permission.camera.request();

      if (status.isGranted) {
        print('>>> Camera permission granted');
        _initializeVerification();
      } else if (status.isDenied) {
        print('>>> Camera permission denied');
        _showPermissionDeniedDialog();
      } else if (status.isPermanentlyDenied) {
        print('>>> Camera permission permanently denied');
        _showPermissionPermanentlyDeniedDialog();
      }
    } catch (e) {
      print('>>> Error requesting camera permission: $e');
      _initializeVerification();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Camera access is required for ID verification. Please grant camera permission to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestCameraPermission();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Camera permission is permanently denied. Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleWebPlatform() async {
    try {
      print('>>> ============================================');
      print('>>> WEB PLATFORM VERIFICATION INITIALIZATION');
      print('>>> User ID: ${widget.userId}');
      print('>>> Email: ${widget.email}');
      print('>>> ============================================');

      // Check for existing verification
      final existingVerification =
          await widget.authRepository.getIdVerificationByUserId(widget.userId);

      if (existingVerification != null) {
        print(
            '>>> Found existing verification: ${existingVerification.status}');
        setState(() {
          _currentVerification = existingVerification;
          _isLoading = false;
        });

        if (existingVerification.isVerified) {
          _showSuccessScreen();
          return;
        }

        if (existingVerification.isRejected) {
          _showRejectedScreen();
          return;
        }

        if (existingVerification.isPending) {
          _showPendingScreen();
          return;
        }
      }

      // CRITICAL FIX: Create verification record BEFORE opening browser
      print('>>> Creating new verification record...');
      final newVerification = IdVerification(
        userId: widget.userId,
        email: widget.email,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final doc =
          await widget.authRepository.createIdVerification(newVerification);
      newVerification.documentId = doc.$id;

      print('>>> Verification record created: ${doc.$id}');

      setState(() {
        _currentVerification = newVerification;
        _isLoading = false;
      });

      // Generate and open verification URL
      final url = _argosService.generateVerificationUrl(
        userId: widget.userId,
        email: widget.email,
      );

      print('>>> Opening verification in browser: $url');
      _openInBrowser(url);

      // Show pending screen with instructions
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showBrowserOpenedScreen();
      });

      print('>>> ============================================');
      print('>>> WEB VERIFICATION INITIALIZED SUCCESSFULLY');
      print('>>> ============================================');
    } catch (e) {
      print('>>> ============================================');
      print('>>> ERROR INITIALIZING WEB VERIFICATION: $e');
      print('>>> ============================================');
      _showErrorScreen(e.toString());
    }
  }

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _initializeVerification() async {
    try {
      print('>>> Initializing ID verification...');

      await widget.authRepository.cleanupStuckVerifications(widget.userId);

      final existingVerification =
          await widget.authRepository.getIdVerificationByUserId(widget.userId);

      if (existingVerification != null) {
        setState(() {
          _currentVerification = existingVerification;
        });

        if (existingVerification.isVerified) {
          _showSuccessScreen();
          return;
        }

        if (existingVerification.isRejected) {
          _showRejectedScreen();
          return;
        }

        if (existingVerification.isPending) {
          _showPendingScreen();
          return;
        }
      }

      final newVerification = IdVerification(
        userId: widget.userId,
        email: widget.email,
        status: 'pending',
      );

      final doc =
          await widget.authRepository.createIdVerification(newVerification);
      newVerification.documentId = doc.$id;

      final url = _argosService.generateVerificationUrl(
        userId: widget.userId,
        email: widget.email,
      );

      // SIMPLER SOLUTION: Just open in system browser
      print('>>> Opening verification in system browser');
      final uri = Uri.parse(url);

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Forces system browser
      );

      if (launched) {
        print('>>> System browser opened successfully');

        setState(() {
          _currentVerification = newVerification;
          _isLoading = false;
        });

        // Show instructions screen
        _showBrowserOpenedScreen();
      } else {
        print('>>> Failed to open system browser');
        _showErrorScreen('Could not open browser for verification');
      }
    } catch (e) {
      print('>>> Error initializing verification: $e');
      _showErrorScreen(e.toString());
    }
  }

  void _showBrowserOpenedScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => _ResponsiveVerificationScreen(
          child: _BrowserOpenedContent(
            onBackToHome: () => Navigator.of(context).pop(false),
          ),
        ),
      ),
    );
  }

  /// CRITICAL: Force ARGOS to use camera mode instead of file upload
  void _forceCameraMode() async {
    try {
      // Wait a bit for the page to fully render
      await Future.delayed(const Duration(milliseconds: 1500));

      const script = '''
        (function() {
          console.log('=== FORCING CAMERA MODE ===');
          
          // Override mobile detection
          Object.defineProperty(navigator, 'userAgent', {
            get: function() { 
              return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
            }
          });
          
          // Force desktop mode
          if (window.matchMedia) {
            window.matchMedia = function(query) {
              return {
                matches: query === '(min-width: 1024px)',
                media: query,
                addListener: function() {},
                removeListener: function() {}
              };
            };
          }
          
          // Grant camera permission
          if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
            console.log('Requesting camera access...');
            
            navigator.mediaDevices.getUserMedia({ 
              video: { 
                facingMode: 'environment',
                width: { min: 640, ideal: 1920, max: 1920 },
                height: { min: 480, ideal: 1080, max: 1080 }
              },
              audio: false
            }).then(function(stream) {
              console.log('âœ“ Camera access granted!');
              
              // Find video elements and attach stream
              const videos = document.getElementsByTagName('video');
              if (videos.length > 0) {
                for (let i = 0; i < videos.length; i++) {
                  videos[i].srcObject = stream;
                  videos[i].play();
                  console.log('âœ“ Video stream attached to element', i);
                }
              }
              
              // Hide file input if it exists
              const fileInputs = document.querySelectorAll('input[type="file"]');
              fileInputs.forEach(function(input) {
                input.style.display = 'none';
                console.log('âœ“ Hidden file input');
              });
              
            }).catch(function(err) {
              console.error('âœ— Camera access error:', err.name, err.message);
            });
          }
          
          // Click any "Use Camera" button if it exists
          setTimeout(function() {
            const cameraButtons = document.querySelectorAll('button');
            cameraButtons.forEach(function(btn) {
              const text = btn.textContent.toLowerCase();
              if (text.includes('camera') || text.includes('scan')) {
                console.log('âœ“ Clicking camera button:', btn.textContent);
                btn.click();
              }
            });
          }, 1000);
          
          console.log('=== CAMERA MODE SCRIPT COMPLETE ===');
        })();
      ''';

      await _webViewController.runJavaScript(script);
      print('>>> Camera mode script executed');

      // Run again after a delay to ensure it takes effect
      await Future.delayed(const Duration(milliseconds: 2000));
      await _webViewController.runJavaScript(script);
      print('>>> Camera mode script executed (second attempt)');
    } catch (e) {
      print('>>> Error forcing camera mode: $e');
    }
  }

  void _handleVerificationComplete() {
    if (_currentVerification != null) {
      widget.authRepository.updateIdVerification(
        _currentVerification!.copyWith(status: 'in_progress'),
      );
    }

    _showPendingScreen();
  }

  void _showSuccessScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => _ResponsiveVerificationScreen(
          child: _VerificationResultContent(
            success: true,
            message: 'Your ID has been successfully verified!',
            onComplete: () => Navigator.of(context).pop(true),
          ),
        ),
      ),
    );
  }

  void _showPendingScreen() {
    widget.authRepository.cleanupStuckVerifications(widget.userId);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => _ResponsiveVerificationScreen(
          child: _VerificationResultContent(
            success: null,
            message:
                'Your ID verification is being processed. You will be notified once it\'s complete.',
            onComplete: () => Navigator.of(context).pop(false),
          ),
        ),
      ),
    );
  }

  void _showRejectedScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => _ResponsiveVerificationScreen(
          child: _VerificationResultContent(
            success: false,
            message:
                'Your ID verification was rejected. ${_currentVerification?.rejectionReason ?? "Please try again with a valid ID."}',
            onComplete: () => Navigator.of(context).pop(false),
            onRetry: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => IdVerificationScreen(
                    userId: widget.userId,
                    email: widget.email,
                    authRepository: widget.authRepository,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showErrorScreen(String error) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => _ResponsiveVerificationScreen(
          child: _VerificationResultContent(
            success: false,
            message: 'An error occurred: $error',
            onComplete: () => Navigator.of(context).pop(false),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _ResponsiveVerificationScreen(
        child: _WebVerificationContent(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ID Verification'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          // Add refresh button to retry camera mode
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _forceCameraMode();
            },
            tooltip: 'Retry Camera',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading verification form...'),
                  SizedBox(height: 8),
                  Text(
                    'Camera will activate automatically',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : _verificationUrl != null
              ? WebViewWidget(controller: _webViewController)
              : const Center(
                  child: Text('Unable to load verification form'),
                ),
    );
  }
}

// Responsive wrapper for desktop/mobile layouts
class _ResponsiveVerificationScreen extends StatelessWidget {
  final Widget child;

  const _ResponsiveVerificationScreen({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ID Verification'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;

          if (isDesktop) {
            // Desktop layout - center content with max width
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(24.0),
                child: child,
              ),
            );
          } else {
            // Mobile layout - full width
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: child,
              ),
            );
          }
        },
      ),
    );
  }
}

// Web verification content
class _WebVerificationContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.open_in_new,
          size: 64,
          color: Color(0xFF1976D2),
        ),
        SizedBox(height: 24),
        Text(
          'Verification opened in new window',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'Please complete the verification process in the opened browser window.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Browser opened content
class _BrowserOpenedContent extends StatelessWidget {
  final VoidCallback onBackToHome;

  const _BrowserOpenedContent({required this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.open_in_browser,
          size: 80,
          color: Color(0xFF1976D2),
        ),
        const SizedBox(height: 32),
        const Text(
          'Verification Opened in Browser',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Please complete the ID verification process in your browser. The camera will activate automatically for scanning your ID.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF1976D2)),
              SizedBox(height: 8),
              Text(
                'After completing verification in the browser, return to this app. Your verification status will be updated automatically.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: onBackToHome,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
          ),
          child: const Text('Back to Home'),
        ),
      ],
    );
  }
}

// Verification result content
class _VerificationResultContent extends StatelessWidget {
  final bool? success;
  final String message;
  final VoidCallback onComplete;
  final VoidCallback? onRetry;

  const _VerificationResultContent({
    required this.success,
    required this.message,
    required this.onComplete,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String title;

    if (success == null) {
      icon = Icons.hourglass_empty;
      color = Colors.orange;
      title = 'Verification Pending';
    } else if (success == true) {
      icon = Icons.check_circle;
      color = Colors.green;
      title = 'Verified!';
    } else {
      icon = Icons.error;
      color = Colors.red;
      title = 'Verification Failed';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 100,
          color: color,
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (onRetry != null)
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 16,
              ),
            ),
            child: const Text('Retry Verification'),
          ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: onComplete,
          child: const Text(
            'Back to Home',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
