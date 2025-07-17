import 'package:flutter/material.dart';

class StaffFullDetails extends StatefulWidget {
  final String staffId;
  final Function(List<String>) onAuthoritiesUpdated;
  final List<String> initialAuthorities;

  const StaffFullDetails({
    required this.staffId,
    required this.onAuthoritiesUpdated,
    required this.initialAuthorities,
    super.key,
  });

  @override
  State<StaffFullDetails> createState() => _StaffFullDetailsState();
}

class _StaffFullDetailsState extends State<StaffFullDetails> {
  late bool hasClinicAuthority;
  late bool hasAppointmentsAuthority;
  late bool hasStaffsAuthority;

  @override
  void initState() {
    super.initState();
    hasClinicAuthority = widget.initialAuthorities.contains('Clinic');
    hasAppointmentsAuthority =
        widget.initialAuthorities.contains('Appointments');
    hasStaffsAuthority = widget.initialAuthorities.contains('Staffs');
  }

  void _handleUpdate() {
    List<String> updatedAuthorities = [];
    if (hasClinicAuthority) updatedAuthorities.add('Clinic');
    if (hasAppointmentsAuthority) updatedAuthorities.add('Appointments');
    if (hasStaffsAuthority) updatedAuthorities.add('Staffs');
    widget.onAuthoritiesUpdated(updatedAuthorities);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 30, backgroundColor: Colors.grey),
            const SizedBox(height: 10),
            Text(widget.staffId,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("N/A"),
            const Divider(height: 20),
            const Row(
              children: [
                Icon(Icons.email, size: 16),
                SizedBox(width: 8),
                Text("N/A")
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.phone, size: 16),
                SizedBox(width: 8),
                Text("N/A")
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.location_on, size: 16),
                SizedBox(width: 8),
                Text("N/A")
              ],
            ),
            const Divider(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Authorities:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SwitchListTile(
              title: const Text("Clinic Page"),
              value: hasClinicAuthority,
              onChanged: (value) => setState(() => hasClinicAuthority = value),
            ),
            SwitchListTile(
              title: const Text("Appointments"),
              value: hasAppointmentsAuthority,
              onChanged: (value) =>
                  setState(() => hasAppointmentsAuthority = value),
            ),
            SwitchListTile(
              title: const Text("Staffs"),
              value: hasStaffsAuthority,
              onChanged: (value) => setState(() => hasStaffsAuthority = value),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Close"),
                ),
                ElevatedButton(
                  onPressed: _handleUpdate,
                  child: const Text("Update"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
