import 'package:capstone_app/user/pages/appointment_next_page.dart';
import 'package:flutter/material.dart';

class MyPendingTile extends StatelessWidget {
  const MyPendingTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return const AppointmentNextPage();
            }
          );
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade400,
                blurRadius: 1.0,
                spreadRadius: 1,
                offset: const Offset(0, 2)
              )
            ]
          ),
          child:  Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        'lib/images/pfp.jpg',
                        width: 60,
                        height: 60,
                      ),
                    )
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.timer_rounded),
                      ),
                      Text("9 : 00 - 10 : 00 AM")
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      "Clinic name",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 5),
                      child: Text(
                      "Type of Service",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 16
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}