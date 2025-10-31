import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class OTPVerificationDialog extends StatefulWidget {
  final String email;
  final String name;
  final Function(String otp) onVerify;
  final Function() onResend;

  const OTPVerificationDialog({
    Key? key,
    required this.email,
    required this.name,
    required this.onVerify,
    required this.onResend,
  }) : super(key: key);

  @override
  State<OTPVerificationDialog> createState() => _OTPVerificationDialogState();
}

class _OTPVerificationDialogState extends State<OTPVerificationDialog> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  final isVerifying = false.obs;
  final errorMessage = Rx<String?>(null);
  final resendCooldown = 0.obs;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendCooldown() {
    resendCooldown.value = 60; // 60 seconds cooldown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown.value > 0) {
        resendCooldown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  void _handleVerify() {
    final otp = _controllers.map((c) => c.text).join();
    
    if (otp.length != 6) {
      setState(() {
        errorMessage.value = 'Please enter the complete 6-digit code';
      });
      return;
    }

    errorMessage.value = null;
    widget.onVerify(otp);
  }

  void _handleResend() {
    if (resendCooldown.value > 0) {
      return;
    }

    // Clear all fields
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    
    errorMessage.value = null;
    widget.onResend();
    _startResendCooldown();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // All fields filled, trigger verify
        _handleVerify();
      }
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.email_outlined,
                color: Color(0xFF517399),
                size: 48,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'Verify Your Email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF517399),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              'We\'ve sent a 6-digit verification code to',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 4),
            
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  width: 50,
                  height: 60,
                  margin: EdgeInsets.only(
                    right: index < 5 ? 12 : 0,
                  ),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF517399),
                          width: 2,
                        ),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) => _onChanged(value, index),
                    onTap: () {
                      // Select all text when tapping
                      _controllers[index].selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _controllers[index].text.length,
                      );
                    },
                    onSubmitted: (_) {
                      if (index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 24),
            
            // Error Message
            Obx(() {
              if (errorMessage.value != null) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFD32F2F),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMessage.value!,
                          style: const TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            
            const SizedBox(height: 24),
            
            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Obx(
                () => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF517399),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isVerifying.value ? null : _handleVerify,
                  child: isVerifying.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Verify Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Resend Code
            Obx(() {
              if (resendCooldown.value > 0) {
                return Text(
                  'Resend code in ${resendCooldown.value}s',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                );
              }
              
              return TextButton(
                onPressed: _handleResend,
                child: const Text(
                  'Didn\'t receive the code? Resend',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF517399),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 8),
            
            // Cancel Button
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}