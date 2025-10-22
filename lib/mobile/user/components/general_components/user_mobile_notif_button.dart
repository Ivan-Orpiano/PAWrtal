import 'package:capstone_app/mobile/user/pages/notification_page.dart';
import 'package:capstone_app/notification/services/in_app_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyNotifButton extends StatelessWidget {
  const MyNotifButton({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = Get.find<InAppNotificationService>();

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
          // Unread badge
          Obx(() {
            final unreadCount = notificationService.unreadCount.value;
            if (unreadCount == 0) return const SizedBox.shrink();

            return Positioned(
              right: 8,
              top: 8,
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
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}