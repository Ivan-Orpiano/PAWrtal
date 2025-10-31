import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class OTPService {
  static final OTPService _instance = OTPService._internal();
  factory OTPService() => _instance;
  OTPService._internal();

  final GetStorage _storage = GetStorage();
  
  // OTP Configuration
  static const int otpLength = 6;
  static const int otpValidityMinutes = 5; // OTP expires in 5 minutes
  static const int maxResendAttempts = 3;
  
  // OPTION 1: Resend API (RECOMMENDED - Better deliverability)
  // Get free API key from: https://resend.com/
  static const String resendApiKey = 're_CRtovg46_HDqZn3PbjeUY72RSnHFuwR44'; // Replace with your key
  static const String fromEmail = 'PAWrtal <noreply@pawrtal.online>'; // Use your verified domain
  
  // OPTION 2: SendGrid API (Your existing setup)
  // static const String sendGridApiKey = 'YOUR_SENDGRID_API_KEY';
  // static const String fromEmail = 'noreply@pawrtal.com';

  /// Generate a random 6-digit OTP
  String generateOTP() {
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    print('>>> Generated OTP: $otp'); // For debugging - remove in production
    return otp;
  }

  /// Store OTP with expiry time
  Future<void> storeOTP(String email, String otp) async {
    final expiryTime = DateTime.now().add(Duration(minutes: otpValidityMinutes));
    
    final otpData = {
      'otp': otp,
      'email': email,
      'expiryTime': expiryTime.toIso8601String(),
      'attempts': 0,
      'createdAt': DateTime.now().toIso8601String(),
    };

    _storage.write('otp_${email.toLowerCase()}', json.encode(otpData));
    print('>>> OTP stored for $email, expires at $expiryTime');
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String email, String enteredOTP) async {
    try {
      final key = 'otp_${email.toLowerCase()}';
      final storedDataJson = _storage.read(key);

      if (storedDataJson == null) {
        return {
          'success': false,
          'message': 'OTP not found. Please request a new OTP.',
        };
      }

      final storedData = json.decode(storedDataJson);
      final storedOTP = storedData['otp'];
      final expiryTime = DateTime.parse(storedData['expiryTime']);
      final attempts = storedData['attempts'] ?? 0;

      // Check if OTP has expired
      if (DateTime.now().isAfter(expiryTime)) {
        _storage.remove(key);
        return {
          'success': false,
          'message': 'OTP has expired. Please request a new OTP.',
        };
      }

      // Check if max attempts exceeded
      if (attempts >= 5) {
        _storage.remove(key);
        return {
          'success': false,
          'message': 'Too many failed attempts. Please request a new OTP.',
        };
      }

      // Verify OTP
      if (storedOTP == enteredOTP) {
        _storage.remove(key); // Remove OTP after successful verification
        return {
          'success': true,
          'message': 'Email verified successfully!',
        };
      } else {
        // Increment attempts
        storedData['attempts'] = attempts + 1;
        _storage.write(key, json.encode(storedData));
        
        final remainingAttempts = 5 - (attempts + 1);
        return {
          'success': false,
          'message': 'Invalid OTP. $remainingAttempts attempt(s) remaining.',
        };
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      return {
        'success': false,
        'message': 'Error verifying OTP. Please try again.',
      };
    }
  }

  /// Send OTP via email using Resend (RECOMMENDED)
  Future<Map<String, dynamic>> sendOTPViaResend(String email, String name) async {
    try {
      print('>>> Sending OTP to $email via Resend...');

      // Generate and store OTP
      final otp = generateOTP();
      await storeOTP(email, otp);

      // Prepare email content
      final emailContent = _buildOTPEmailHTML(name, otp);

      // Send via Resend API
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $resendApiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'from': fromEmail,
          'to': [email],
          'subject': 'PAWrtal - Email Verification Code',
          'html': emailContent,
        }),
      );

      if (response.statusCode == 200) {
        print('>>> OTP sent successfully via Resend');
        return {
          'success': true,
          'message': 'Verification code sent to your email',
        };
      } else {
        print('>>> Resend API error: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Failed to send verification code. Please try again.',
        };
      }
    } catch (e) {
      print('Error sending OTP via Resend: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Send OTP via email using SendGrid (Alternative)
  Future<Map<String, dynamic>> sendOTPViaSendGrid(String email, String name) async {
    try {
      print('>>> Sending OTP to $email via SendGrid...');

      // Generate and store OTP
      final otp = generateOTP();
      await storeOTP(email, otp);

      // Prepare email content
      final emailContent = _buildOTPEmailHTML(name, otp);

      // Send via SendGrid API
      final response = await http.post(
        Uri.parse('https://api.sendgrid.com/v3/mail/send'),
        headers: {
          'Authorization': 'Bearer YOUR_SENDGRID_API_KEY', // Replace with your key
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'personalizations': [
            {
              'to': [
                {'email': email}
              ],
            }
          ],
          'from': {
            'email': 'noreply@pawrtal.com', // Replace with your verified sender
            'name': 'PAWrtal'
          },
          'subject': 'PAWrtal - Email Verification Code',
          'content': [
            {
              'type': 'text/html',
              'value': emailContent,
            }
          ],
        }),
      );

      if (response.statusCode == 202) {
        print('>>> OTP sent successfully via SendGrid');
        return {
          'success': true,
          'message': 'Verification code sent to your email',
        };
      } else {
        print('>>> SendGrid API error: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Failed to send verification code. Please try again.',
        };
      }
    } catch (e) {
      print('Error sending OTP via SendGrid: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Build OTP email HTML template
  String _buildOTPEmailHTML(String name, String otp) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Email Verification - PAWrtal</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f5f5f5;">
    <table role="presentation" cellspacing="0" cellpadding="0" width="100%" style="background-color: #f5f5f5; padding: 20px 0;">
        <tr>
            <td align="center">
                <table role="presentation" cellspacing="0" cellpadding="0" width="600" style="background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                    <!-- Header -->
                    <tr>
                        <td align="center" style="background: linear-gradient(135deg, #517399 0%, #2c475c 100%); padding: 30px;">
                            <h1 style="margin: 0; color: #ffffff; font-size: 28px;">PAWrtal</h1>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style="padding: 40px 30px;">
                            <h2 style="margin: 0 0 20px 0; color: #333; font-size: 24px;">Email Verification</h2>
                            
                            <p style="margin: 0 0 15px 0; color: #666; font-size: 16px; line-height: 1.5;">
                                Hello <strong>$name</strong>,
                            </p>
                            
                            <p style="margin: 0 0 25px 0; color: #666; font-size: 16px; line-height: 1.5;">
                                Thank you for signing up with PAWrtal! To complete your registration, please use the verification code below:
                            </p>
                            
                            <!-- OTP Box -->
                            <div style="background-color: #f8f9fa; border: 2px dashed #517399; border-radius: 8px; padding: 20px; text-align: center; margin: 30px 0;">
                                <p style="margin: 0 0 10px 0; color: #666; font-size: 14px;">Your Verification Code:</p>
                                <p style="margin: 0; color: #517399; font-size: 36px; font-weight: bold; letter-spacing: 8px;">$otp</p>
                            </div>
                            
                            <p style="margin: 0 0 15px 0; color: #666; font-size: 14px; line-height: 1.5;">
                                <strong>Important:</strong> This code will expire in <strong>5 minutes</strong>.
                            </p>
                            
                            <p style="margin: 0 0 15px 0; color: #666; font-size: 14px; line-height: 1.5;">
                                If you didn't request this code, please ignore this email.
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f8f9fa; padding: 20px 30px; border-top: 1px solid #e0e0e0;">
                            <p style="margin: 0; color: #999; font-size: 12px; text-align: center;">
                                This is an automated email. Please do not reply to this message.<br>
                                © 2025 PAWrtal. All rights reserved.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
''';
  }

  /// Check if OTP is still valid (not expired)
  bool isOTPValid(String email) {
    try {
      final key = 'otp_${email.toLowerCase()}';
      final storedDataJson = _storage.read(key);

      if (storedDataJson == null) return false;

      final storedData = json.decode(storedDataJson);
      final expiryTime = DateTime.parse(storedData['expiryTime']);

      return DateTime.now().isBefore(expiryTime);
    } catch (e) {
      return false;
    }
  }

  /// Get remaining time for OTP in seconds
  int getRemainingTime(String email) {
    try {
      final key = 'otp_${email.toLowerCase()}';
      final storedDataJson = _storage.read(key);

      if (storedDataJson == null) return 0;

      final storedData = json.decode(storedDataJson);
      final expiryTime = DateTime.parse(storedData['expiryTime']);
      
      final remaining = expiryTime.difference(DateTime.now()).inSeconds;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return 0;
    }
  }

  /// Clear OTP for email
  void clearOTP(String email) {
    _storage.remove('otp_${email.toLowerCase()}');
  }

  /// Main method to send OTP (uses Resend by default)
  Future<Map<String, dynamic>> sendOTP(String email, String name) async {
    // Choose your preferred method:
    return await sendOTPViaResend(email, name); // RECOMMENDED
    // return await sendOTPViaSendGrid(email, name); // Alternative
  }
}