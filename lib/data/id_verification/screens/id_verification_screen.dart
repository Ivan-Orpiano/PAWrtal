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
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
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
    
    // Check if running on web platform
    if (kIsWeb) {
      _handleWebPlatform();
    } else {
      _initializeVerification();
    }
  }

  /// Handle web platform differently (no WebView support)
  void _handleWebPlatform() {
    final url = _argosService.generateVerificationUrl(
      userId: widget.userId,
      email: widget.email,
    );
    
    // Open in new tab/window
    _openInBrowser(url);
    
    // Show pending screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPendingScreen();
    });
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
      
      // Check if user already has a verification in progress
      final existingVerification = await widget.authRepository
          .getIdVerificationByUserId(widget.userId);

      if (existingVerification != null) {
        setState(() {
          _currentVerification = existingVerification;
        });

        // If already approved, show success screen
        if (existingVerification.isVerified) {
          _showSuccessScreen();
          return;
        }

        // If rejected, allow retry
        if (existingVerification.isRejected) {
          _showRejectedScreen();
          return;
        }

        // If pending, show pending screen
        if (existingVerification.isPending) {
          _showPendingScreen();
          return;
        }
      }

      // Create new verification record
      final newVerification = IdVerification(
        userId: widget.userId,
        email: widget.email,
        status: 'pending',
      );

      final doc = await widget.authRepository.createIdVerification(newVerification);
      newVerification.documentId = doc.$id;

      // Generate ARGOS URL
      final url = _argosService.generateVerificationUrl(
        userId: widget.userId,
        email: widget.email,
      );

      // Initialize WebView controller with file upload support
      late final PlatformWebViewControllerCreationParams params;
      
      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        // iOS
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        // Android
        params = const PlatformWebViewControllerCreationParams();
      }

      _webViewController = WebViewController.fromPlatformCreationParams(params)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('>>> Page started loading: $url');
            },
            onPageFinished: (String url) {
              print('>>> Page finished loading: $url');
              setState(() {
                _isLoading = false;
              });
            },
            onNavigationRequest: (NavigationRequest request) {
              print('>>> Navigation request: ${request.url}');
              
              // Check if user completed verification
              if (request.url.contains('success') || 
                  request.url.contains('complete') ||
                  request.url.contains('thank')) {
                _handleVerificationComplete();
                return NavigationDecision.prevent;
              }
              
              return NavigationDecision.navigate;
            },
            onWebResourceError: (WebResourceError error) {
              print('>>> WebView error: ${error.description}');
            },
          ),
        )
        ..loadRequest(Uri.parse(url));

      // CRITICAL: Enable file uploads AND camera for Android
      if (_webViewController.platform is AndroidWebViewController) {
        print('>>> Configuring Android WebView for file uploads and camera');
        final androidController = _webViewController.platform as AndroidWebViewController;
        
        await androidController.setMediaPlaybackRequiresUserGesture(false);
        
        // Enable file access
        await androidController.setAllowFileAccess(true);
        
        // Enable camera access for WebView
        await androidController.setGeolocationPermissionsPromptCallbacks(
          onShowPrompt: (request) async {
            return GeolocationPermissionsResponse(
              allow: true,
              retain: true,
            );
          },
        );
        
        // IMPORTANT: Set file chooser to allow BOTH camera AND file selection
        androidController.setOnShowFileSelector(_androidFilePicker);
      }

      setState(() {
        _verificationUrl = url;
        _currentVerification = newVerification;
      });
    } catch (e) {
      print('>>> Error initializing verification: $e');
      _showErrorScreen(e.toString());
    }
  }

  /// Android file picker handler with CAMERA support
  Future<List<String>> _androidFilePicker(FileSelectorParams params) async {
    try {
      print('>>> File picker called');
      print('>>> Accept types: ${params.acceptTypes}');
      print('>>> Mode: ${params.mode}');
      print('>>> Capture: ${params.isCaptureEnabled}');
      
      // Check if camera is preferred
      final bool preferCamera = params.isCaptureEnabled == true ||
          params.acceptTypes.contains('image/*');
      
      if (preferCamera) {
        // Show bottom sheet to choose camera or gallery
        final source = await showModalBottomSheet<String>(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
                ListTile(
                  leading: const Icon(Icons.cancel),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(context, null),
                ),
              ],
            ),
          ),
        );

        if (source == 'camera') {
          // Use image_picker for camera
          final ImagePicker picker = ImagePicker();
          final XFile? photo = await picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
          );
          
          if (photo != null) {
            print('>>> Camera photo taken: ${photo.path}');
            return [photo.path];
          }
        } else if (source == 'gallery') {
          // Use file_picker for gallery
          final result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: params.mode == FileSelectorMode.openMultiple,
          );

          if (result != null && result.files.isNotEmpty) {
            print('>>> File selected: ${result.files.first.name}');
            return result.files
                .where((file) => file.path != null)
                .map((file) => file.path!)
                .toList();
          }
        }
      } else {
        // Regular file picker for non-image files
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
          allowMultiple: params.mode == FileSelectorMode.openMultiple,
        );

        if (result != null && result.files.isNotEmpty) {
          print('>>> File selected: ${result.files.first.name}');
          return result.files
              .where((file) => file.path != null)
              .map((file) => file.path!)
              .toList();
        }
      }
      
      print('>>> No file selected');
      return [];
    } catch (e) {
      print('>>> Error in file picker: $e');
      return [];
    }
  }

  void _handleVerificationComplete() {
    // Update status to in_progress
    if (_currentVerification != null) {
      widget.authRepository.updateIdVerification(
        _currentVerification!.copyWith(status: 'in_progress'),
      );
    }
    
    // Show pending screen while waiting for webhook
    _showPendingScreen();
  }

  void _showSuccessScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => _VerificationResultScreen(
          success: true,
          message: 'Your ID has been successfully verified!',
          onComplete: () => Navigator.of(context).pop(true),
        ),
      ),
    );
  }

  void _showPendingScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => _VerificationResultScreen(
          success: null,
          message: 'Your ID verification is being processed. You will be notified once it\'s complete.',
          onComplete: () => Navigator.of(context).pop(false),
        ),
      ),
    );
  }

  void _showRejectedScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => _VerificationResultScreen(
          success: false,
          message: 'Your ID verification was rejected. ${_currentVerification?.rejectionReason ?? "Please try again with a valid ID."}',
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
    );
  }

  void _showErrorScreen(String error) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => _VerificationResultScreen(
          success: false,
          message: 'An error occurred: $error',
          onComplete: () => Navigator.of(context).pop(false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If web platform, show message
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ID Verification'),
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
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
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ID Verification'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading verification form...'),
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

// Result screen widget (unchanged)
class _VerificationResultScreen extends StatelessWidget {
  final bool? success;
  final String message;
  final VoidCallback onComplete;
  final VoidCallback? onRetry;

  const _VerificationResultScreen({
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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
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
          ),
        ),
      ),
    );
  }
}