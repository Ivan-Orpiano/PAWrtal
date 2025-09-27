import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebSnackBarService {
  static void showSuccess({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    Get.closeAllSnackbars();
    Get.snackbar(
      '',
      '',
      titleText: _buildTitle(title, Colors.green),
      messageText: _buildMessage(message),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: Colors.black87,
      borderRadius: 12,
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      duration: duration,
      animationDuration: const Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.fastOutSlowIn,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      leftBarIndicatorColor: Colors.green,
      borderWidth: 1,
      borderColor: Colors.green.withOpacity(0.3),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 20,
        ),
      ),
    );
  }

  static void showError({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 5),
  }) {
    Get.closeAllSnackbars();
    Get.snackbar(
      '',
      '',
      titleText: _buildTitle(title, Colors.red),
      messageText: _buildMessage(message),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: Colors.black87,
      borderRadius: 12,
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      duration: duration,
      animationDuration: const Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.fastOutSlowIn,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      leftBarIndicatorColor: Colors.red,
      borderWidth: 1,
      borderColor: Colors.red.withOpacity(0.3),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error,
          color: Colors.red,
          size: 20,
        ),
      ),
    );
  }

  static void showInfo({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    Get.closeAllSnackbars();
    Get.snackbar(
      '',
      '',
      titleText: _buildTitle(title, Colors.blue),
      messageText: _buildMessage(message),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: Colors.black87,
      borderRadius: 12,
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      duration: duration,
      animationDuration: const Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.fastOutSlowIn,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      leftBarIndicatorColor: Colors.blue,
      borderWidth: 1,
      borderColor: Colors.blue.withOpacity(0.3),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.info,
          color: Colors.blue,
          size: 20,
        ),
      ),
    );
  }

  static void showWarning({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    Get.closeAllSnackbars();
    Get.snackbar(
      '',
      '',
      titleText: _buildTitle(title, Colors.orange),
      messageText: _buildMessage(message),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: Colors.black87,
      borderRadius: 12,
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      duration: duration,
      animationDuration: const Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.fastOutSlowIn,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      leftBarIndicatorColor: Colors.orange,
      borderWidth: 1,
      borderColor: Colors.orange.withOpacity(0.3),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.warning,
          color: Colors.orange,
          size: 20,
        ),
      ),
    );
  }

  static Widget _buildTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  static Widget _buildMessage(String message) {
    return Text(
      message,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
      ),
    );
  }
}

// Extension to keep compatibility with your existing CustomSnackBar
extension CustomSnackBarCompatibility on WebSnackBarService {
  static void showErrorSnackBar({
    required BuildContext? context,
    required String title,
    required String message,
  }) {
    WebSnackBarService.showError(title: title, message: message);
  }

  static void showSuccessSnackBar({
    required BuildContext? context,
    required String title,
    required String message,
  }) {
    WebSnackBarService.showSuccess(title: title, message: message);
  }

  static void showInfoSnackBar({
    required BuildContext? context,
    required String title,
    required String message,
  }) {
    WebSnackBarService.showInfo(title: title, message: message);
  }
}