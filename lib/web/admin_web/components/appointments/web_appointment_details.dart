import 'package:capstone_app/web/admin_web/components/appointments/web_appointment_pet_details.dart';
import 'package:flutter/material.dart';

void showAppointmentDetailsPopup(
    BuildContext context, Map<String, dynamic> appointmentData,
    {VoidCallback? onComplete}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: WebAppointmentDetails(
        appointmentData: appointmentData,
        onComplete: onComplete,
      ),
    ),
  );
}

class WebAppointmentDetails extends StatefulWidget {
  final Map<String, dynamic> appointmentData;
  final VoidCallback? onComplete;

  const WebAppointmentDetails({
    super.key,
    required this.appointmentData,
    this.onComplete,
  });

  @override
  State<WebAppointmentDetails> createState() => _WebAppointmentDetailsState();
}

class _WebAppointmentDetailsState extends State<WebAppointmentDetails> {
  void _showPetDetails(Map<String, dynamic> petData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: WebAppointmentPetDetails(petData: petData),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'declined':
        return Colors.red;
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.yellow;
      default:
        return const Color(0xff517399);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.appointmentData;
    debugPrint("Appointment Status: ${data['status']}");

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _getStatusColor(data['status']),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Center(
                  child: Text(
                    "Appointment Details",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: AssetImage("lib/images/pfp.jpg"),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            data['owner'] ?? 'Pet Owner',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              "Status: ${data['status'] ?? 'Unknown'}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Divider(
                    indent: 5,
                    endIndent: 5,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Center(
                            child: Text(
                              data['time'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8, left: 8),
                          child: Text(
                            "Pet/s: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showPetDetails({
                            'name': data['petName'],
                            'breed': data['breed'],
                            'service': data['service'],
                            'time': data['time'],
                          }),
                          child: WebAppointmentPetDetails(
                            petData: {
                              'name': data['petName'],
                              'breed': data['breed'],
                              'service': data['service'],
                              'time': data['time'],
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (data['status'] == 'accepted')
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
              child: ElevatedButton(
                onPressed: () {
                  widget.onComplete
                      ?.call(); // This handles removal from accepted[]
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Complete',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
