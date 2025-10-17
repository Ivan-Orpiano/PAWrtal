import 'dart:async';
import 'package:capstone_app/notifications/controllers/admin_notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/models/notification_model.dart';

class ToastNotificationService {
  static OverlayEntry? _currentToast;
  static Timer? _toastTimer;

  /// Show a small toast notification near the notification button
  static void showToastNotification(NotificationModel notification) {
    // Remove any existing toast
    hideCurrentToast();

    _currentToast = OverlayEntry(
      builder: (context) => Positioned(
        top: 80, // Position below the header
        right: 20, // Distance from right edge
        child: ToastNotificationWidget(
          notification: notification,
          onDismiss: hideCurrentToast,
          onTap: () {
            hideCurrentToast();
            _handleNotificationTap(notification);
          },
        ),
      ),
    );

    // Insert the toast
    if (Get.overlayContext != null) {
      Overlay.of(Get.overlayContext!).insert(_currentToast!);

      // Auto-dismiss after 5 seconds
      _toastTimer = Timer(const Duration(seconds: 5), hideCurrentToast);
    }
  }

  static void hideCurrentToast() {
    _toastTimer?.cancel();
    _toastTimer = null;

    _currentToast?.remove();
    _currentToast = null;
  }

  static void _handleNotificationTap(NotificationModel notification) {
    try {
      final controller = Get.find<NotificationController>();
      controller.handleNotificationTap(notification);
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  static void showSuccessToast(String title, String message) {
    _showSimpleToast(
      title: title,
      message: message,
      color: Colors.green,
      icon: Icons.check_circle,
    );
  }

  static void showErrorToast(String title, String message) {
    _showSimpleToast(
      title: title,
      message: message,
      color: Colors.red,
      icon: Icons.error,
    );
  }

  static void showInfoToast(String title, String message) {
    _showSimpleToast(
      title: title,
      message: message,
      color: Colors.blue,
      icon: Icons.info,
    );
  }

  static void _showSimpleToast({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    hideCurrentToast();

    _currentToast = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        right: 20,
        child: _SimpleToastWidget(
          title: title,
          message: message,
          color: color,
          icon: icon,
          onDismiss: hideCurrentToast,
        ),
      ),
    );

    if (Get.overlayContext != null) {
      Overlay.of(Get.overlayContext!).insert(_currentToast!);
      _toastTimer = Timer(const Duration(seconds: 3), hideCurrentToast);
    }
  }
}

class ToastNotificationWidget extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const ToastNotificationWidget({
    super.key,
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<ToastNotificationWidget> createState() =>
      _ToastNotificationWidgetState();
}

class _ToastNotificationWidgetState extends State<ToastNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Start from right
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getNotificationColor().withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getNotificationColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getNotificationIcon(),
                        color: _getNotificationColor(),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.notification.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Just now',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          size: 16, color: Colors.grey.shade600),
                      onPressed: widget.onDismiss,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Message
                Text(
                  widget.notification.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getNotificationColor(),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon() {
    switch (widget.notification.type) {
      case NotificationType.appointmentBooked:
        return Icons.calendar_today;
      case NotificationType.appointmentAccepted:
        return Icons.check_circle;
      case NotificationType.appointmentDeclined:
        return Icons.cancel;
      case NotificationType.newMessage:
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor() {
    switch (widget.notification.type) {
      case NotificationType.appointmentBooked:
        return Colors.blue;
      case NotificationType.appointmentAccepted:
        return Colors.green;
      case NotificationType.appointmentDeclined:
        return Colors.red;
      case NotificationType.newMessage:
        return Colors.purple;
      default:
        return const Color.fromARGB(255, 81, 115, 153);
    }
  }
}

class _SimpleToastWidget extends StatelessWidget {
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback onDismiss;

  const _SimpleToastWidget({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 16, color: Colors.grey.shade600),
              onPressed: onDismiss,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
