import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ScheduleAppointment extends StatefulWidget {
  const ScheduleAppointment({super.key});

  @override
  State<ScheduleAppointment> createState() => _ScheduleAppointmentState();
}

class _ScheduleAppointmentState extends State<ScheduleAppointment> {

  DateTime today = DateTime.now();

  void _onDaySelected (DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
    });
  } 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
      body: Column(
        children: [
          SizedBox(
            height: 100,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12,top: 35),
                  child: IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_left_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.maxFinite,
              height: double.maxFinite,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 230, 230, 230),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TableCalendar(
                      focusedDay: today,
                      firstDay: DateTime.utc(2025, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true
                      ),
                      availableGestures: AvailableGestures.all,
                      onDaySelected: _onDaySelected,
                      selectedDayPredicate: (day) => isSameDay(day, today),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownMenu(
                      width: double.infinity,
                      label: const Text(
                        "Select a Time"
                      ),
                      inputDecorationTheme: InputDecorationTheme(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)
                        )
                      ),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(
                          value: "bing_bong",
                          label: 'Bing bong'
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownMenu(
                      width: double.infinity,
                      label: const Text(
                        "Service"
                      ),
                      inputDecorationTheme: InputDecorationTheme(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)
                        )
                      ),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(
                          value: "check_up",
                          label: 'Check Up'
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownMenu(
                      width: double.infinity,
                      label: const Text(
                        "Pet"
                      ),
                      inputDecorationTheme: InputDecorationTheme(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)
                        )
                      ),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(
                          value: "pet",
                          label: 'Aki'
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20, right: 10),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 15),
                              backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)
                                )
                              ),
                              onPressed: () {
                                // Fluttertoast.showToast(
                                //   msg: "You have scheduled an appointment",
                                //   toastLength: Toast.LENGTH_SHORT,
                                //   gravity: ToastGravity.CENTER,
                                //   timeInSecForIosWeb: 1,
                                //   backgroundColor: Colors.red,
                                //   textColor: Colors.white,
                                //   fontSize: 16.0
                                // );
                              },
                              child: const Text(
                                "Continue",
                                style: TextStyle(
                                  color: Colors.white
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),    
    );
  }
}