import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/notifications/controllers/notification_controller.dart';

class NotificationButton extends StatefulWidget {
  final double? right;
  final double? top;
  final double? width;

  const NotificationButton({
    super.key,
    this.right = 125,
    this.top = 70,
    this.width = 450,
  });

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  OverlayEntry? _overlayEntry;
  late NotificationController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize or get existing controller
    if (Get.isRegistered<NotificationController>()) {
      _controller = Get.find<NotificationController>();
    } else {
      _controller = Get.put(NotificationController(
        authRepository: Get.find(),
        session: Get.find(),
      ));
    }
  }

  void _togglePopup(BuildContext context) {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _closePopup();
    }
  }

  void _closePopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Backdrop to close panel
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closePopup,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Notification Panel
          Positioned(
            right: widget.right,
            top: widget.top,
            width: widget.width,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              child: NotificationPanel(onClose: _closePopup),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_rounded),
              onPressed: () => _togglePopup(context),
              tooltip: 'Notifications',
            ),
            // Unread count badge
            if (_controller.hasUnreadNotifications)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    _controller.unreadCount.value > 99 
                        ? '99+' 
                        : _controller.unreadCount.value.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ));
  }
}

class NotificationPanel extends StatelessWidget {
  final VoidCallback onClose;

  const NotificationPanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(controller),
          
          // Filter Tabs
          _buildFilterTabs(controller),
          
          // Notifications List
          Expanded(
            child: _buildNotificationsList(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(NotificationController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 81, 115, 153),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Mark all as read button
          Obx(() => controller.hasUnreadNotifications
              ? IconButton(
                  icon: const Icon(Icons.done_all, color: Colors.white),
                  onPressed: controller.markAllAsRead,
                  tooltip: 'Mark all as read',
                )
              : const SizedBox.shrink()),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showNotificationSettings(),
            tooltip: 'Notification settings',
          ),
          // Close button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(NotificationController controller) {
    final filters = [
      {'key': 'all', 'label': 'All', 'icon': Icons.inbox},
      {'key': 'unread', 'label': 'Unread', 'icon': Icons.mark_email_unread},
      {'key': 'appointments', 'label': 'Appointments', 'icon': Icons.calendar_today},
      {'key': 'messages', 'label': 'Messages', 'icon': Icons.message},
    ];

    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: filters.map((filter) {
          return Expanded(
            child: Obx(() => InkWell(
              onTap: () => controller.setFilter(filter['key'] as String),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: controller.selectedFilter.value == filter['key']
                          ? const Color.fromARGB(255, 81, 115, 153)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 18,
                      color: controller.selectedFilter.value == filter['key']
                          ? const Color.fromARGB(255, 81, 115, 153)
                          : Colors.grey,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      filter['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: controller.selectedFilter.value == filter['key']
                            ? const Color.fromARGB(255, 81, 115, 153)
                            : Colors.grey,
                        fontWeight: controller.selectedFilter.value == filter['key']
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            )),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationsList(NotificationController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.notifications.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 81, 115, 153),
          ),
        );
      }

      if (controller.notifications.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadNotifications(refresh: true),
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: controller.notifications.length + 
              (controller.isLoadingMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= controller.notifications.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final notification = controller.notifications[index];
            return NotificationTile(
              notification: notification,
              onTap: () {
                controller.handleNotificationTap(notification);
                onClose();
              },
              onArchive: () => controller.archiveNotification(notification),
              onDelete: () => controller.deleteNotification(notification),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see notifications here when\nsomething important happens',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    Get.dialog(
      AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications on your device'),
              value: true, // Get from user preferences
              onChanged: (value) {
                // Update notification preferences
              },
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive notifications via email'),
              value: false, // Get from user preferences
              onChanged: (value) {
                // Update notification preferences
              },
            ),
            SwitchListTile(
              title: const Text('Sound'),
              subtitle: const Text('Play sound for new notifications'),
              value: true, // Get from user preferences
              onChanged: (value) {
                // Update notification preferences
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save settings
              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: notification.isUnread 
            ? const Color.fromARGB(255, 81, 115, 153).withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: notification.isUnread 
                    ? const Color.fromARGB(255, 81, 115, 153).withOpacity(0.3)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getNotificationColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getNotificationIcon(),
                    color: _getNotificationColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notification.isUnread 
                                    ? FontWeight.bold 
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            notification.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (notification.isHigh || notification.isUrgent) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: notification.isUrgent 
                                ? Colors.red.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            notification.isUrgent ? 'URGENT' : 'HIGH PRIORITY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: notification.isUrgent 
                                  ? Colors.red 
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Actions
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 16, color: Colors.grey.shade600),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(Icons.archive, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          const Text('Archive'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'archive':
                        onArchive();
                        break;
                      case 'delete':
                        _showDeleteConfirmation(context);
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.appointmentBooked:
        return Icons.calendar_today;
      case NotificationType.appointmentAccepted:
        return Icons.check_circle;
      case NotificationType.appointmentDeclined:
        return Icons.cancel;
      case NotificationType.appointmentCancelled:
        return Icons.event_busy;
      case NotificationType.appointmentCompleted:
        return Icons.task_alt;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.paymentReceived:
        return Icons.payment;
      case NotificationType.appointmentReminder:
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case NotificationType.appointmentBooked:
        return Colors.blue;
      case NotificationType.appointmentAccepted:
        return Colors.green;
      case NotificationType.appointmentDeclined:
      case NotificationType.appointmentCancelled:
        return Colors.red;
      case NotificationType.appointmentCompleted:
        return Colors.teal;
      case NotificationType.newMessage:
        return Colors.purple;
      case NotificationType.paymentReceived:
        return Colors.orange;
      case NotificationType.appointmentReminder:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}