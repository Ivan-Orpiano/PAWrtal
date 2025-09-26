import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_vet_feedback/super_admin_feedback_manager.dart';
import 'package:flutter/material.dart';

class ViewReportTile extends StatelessWidget {
  const ViewReportTile({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VeterinaryReport(),
            )),
        child: Padding(
            padding: const EdgeInsets.all(5),
            child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                width: MediaQuery.of(context).size.width * 0.8,
                child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(81, 115, 153, 0.8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'lib/images/view_report_icon.png',
                          fit: BoxFit.cover,
                        ),
                        //const SizedBox(height: 10),
                        const Text(
                          'View Reports',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )))));
  }
}
