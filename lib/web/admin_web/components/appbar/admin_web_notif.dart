import 'package:flutter/material.dart';
import 'package:capstone_app/notifications/components/admin_notification_panel.dart';

class AdminWebNotif extends StatefulWidget {
  final double? right;
  final double? top;
  final double? width;

  const AdminWebNotif({
    super.key,
    this.right = 125,
    this.top = 70,
    this.width = 500,
  });

  @override
  State<AdminWebNotif> createState() => _AdminWebNotifState();
}

class _AdminWebNotifState extends State<AdminWebNotif> {
  @override
  Widget build(BuildContext context) {
    return NotificationButton(
      right: widget.right,
      top: widget.top,
      width: widget.width,
    );
  }
}
