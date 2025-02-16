import 'package:capstone_app/admin/pages/staff_details_page.dart';
import 'package:flutter/material.dart';

class StaffAccountTile extends StatefulWidget {
  const StaffAccountTile({super.key});

  @override
  State<StaffAccountTile> createState() => _StaffAccountTileState();
}

class _StaffAccountTileState extends State<StaffAccountTile> {
  void _staffDetailsPopUp() {
    showModalBottomSheet(
        context: context,
        builder: (ctx) => const StaffDetailsPage(),
        isScrollControlled: true);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _staffDetailsPopUp,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.all(50.0),
                child: Icon(Icons.person),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Jin Mori",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Text(
                          "Front desk staff",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          "Authorities: ",
                          style: TextStyle(
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
