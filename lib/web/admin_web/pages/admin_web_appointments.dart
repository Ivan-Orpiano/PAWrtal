import 'package:capstone_app/web/admin_web/components/appointments/web_accepted_tile.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_declined_tile.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_pending_tile.dart';
import 'package:flutter/material.dart';

class AdminWebAppointments extends StatefulWidget {
  const AdminWebAppointments({super.key});

  @override
  State<AdminWebAppointments> createState() => _AdminWebAppointmentsState();
}

class _AdminWebAppointmentsState extends State<AdminWebAppointments> {
  int selectedIndex = 0;

  void selectColumn(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildColumn(0, "Accepted", const WebAcceptedTile()),
            const SizedBox(width: 1),
            buildColumn(1, "Pending", const WebPendingTile()),
            const SizedBox(width: 1),
            buildColumn(2, "Declined", const WebDeclinedTile()),
          ],
        ),
      ),
    );
  }

  Widget buildColumn(int index, String title, Widget tileWidget) {
    final bool isSelected = selectedIndex == index;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          border: Border.all(
              color: isSelected ? const Color(0xff517399) : Colors.grey, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => selectColumn(index),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xff517399) : Colors.grey,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Container(
                  width: double.infinity,
                  color: isSelected ? Colors.white : Colors.grey[200],
                  child: NotificationListener<OverscrollIndicatorNotification>(
                    onNotification:
                        (OverscrollIndicatorNotification notification) {
                      notification.disallowIndicator();
                      return true;
                    },
                    child: SingleChildScrollView(
                      physics: isSelected
                          ? const AlwaysScrollableScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      child: AbsorbPointer(
                        absorbing: !isSelected,
                        child: Opacity(
                          opacity: isSelected ? 1.0 : 0.5,
                          child: Column(
                            children: List.generate(10, (_) => tileWidget),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
