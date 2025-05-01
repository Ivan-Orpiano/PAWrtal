import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';


class WebAppointmentPanel extends StatefulWidget {
  const WebAppointmentPanel({super.key});

  @override
  State<WebAppointmentPanel> createState() => _WebAppointmentPanelState();
}

class _WebAppointmentPanelState extends State<WebAppointmentPanel> {
  String? selectedTime;
  DateTime today = DateTime.now();

  void _onDaySelected (DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      height: 540,
      width: 375,
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 2)
          )
        ]        
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TableCalendar(
              focusedDay: today,
              firstDay: DateTime.utc(2025, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              availableGestures: AvailableGestures.all,
              onDaySelected: _onDaySelected,
              selectedDayPredicate: (day) => isSameDay(day, today),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Divider(
              height: 1,
              thickness: 0.5,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10)
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey),
                      left: BorderSide(color: Colors.grey),
                      bottom: BorderSide(color: Colors.grey)
                    )
                  ),
                  child: const DropdownMenu(
                    width: 170,
                    label: Text(
                      "Select time",
                      style: TextStyle(
                        fontSize: 12
                      ),
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none
                      )
                    ),
                    dropdownMenuEntries: [
                      DropdownMenuEntry(
                        value: 'test',
                        label: 'time'
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 50,
                  child: VerticalDivider(
                    color: Colors.grey,
                    width: 1,
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10)
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey),
                      right: BorderSide(color: Colors.grey),
                      bottom: BorderSide(color: Colors.grey)
                    )
                  ),
                  child: const DropdownMenu(
                    width: 170,
                    label: Text(
                      "Select pet",
                      style: TextStyle(
                        fontSize: 12
                      ),
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none
                      )
                    ),
                    dropdownMenuEntries: [
                      DropdownMenuEntry(
                        value: 'test',
                        label: 'Pet'
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 345,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                "Schedule",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}