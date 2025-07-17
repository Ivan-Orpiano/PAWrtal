import 'package:flutter/material.dart';

class Staff {
  final String name;
  final List<String> authorities;
  final String imagePath;

  Staff({
    required this.name,
    required this.authorities,
    required this.imagePath,
  });
}

void showStaffPopup(
  BuildContext context, {
  required Staff staff,
  required void Function(List<String>) onAuthoritiesUpdated,
  required VoidCallback onRemove,
}) {
  showDialog(
    context: context,
    builder: (_) => StaffFullDetails(
      staffId: staff.name,
      initialAuthorities: staff.authorities,
      onAuthoritiesUpdated: onAuthoritiesUpdated,
      onRemove: onRemove,
    ),
  );
}

class StaffTile extends StatelessWidget {
  final Staff staff;
  final void Function(List<String>) onUpdate;
  final VoidCallback onRemove;

  const StaffTile(
      {super.key,
      required this.staff,
      required this.onUpdate,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showStaffPopup(
          context,
          staff: staff,
          onAuthoritiesUpdated: (updatedAuthorities) {
            onUpdate(updatedAuthorities);
          },
          onRemove: onRemove,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 40),
            const SizedBox(height: 10),
            Text(
              staff.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text("Authorities:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...staff.authorities.map((auth) => Text("- $auth")).toList(),
          ],
        ),
      ),
    );
  }
}

class StaffFullDetails extends StatefulWidget {
  final String staffId;
  final Function(List<String>) onAuthoritiesUpdated;
  final List<String> initialAuthorities;
  final VoidCallback onRemove;

  const StaffFullDetails({
    super.key,
    required this.staffId,
    required this.onAuthoritiesUpdated,
    required this.initialAuthorities,
    required this.onRemove,
  });

  @override
  State<StaffFullDetails> createState() => _StaffFullDetailsState();
}

class _StaffFullDetailsState extends State<StaffFullDetails> {
  late bool hasClinicAuthority;
  late bool hasAppointmentsAuthority;
  late bool hasStaffsAuthority;
  late bool hasMessagesAuthority;

  @override
  void initState() {
    super.initState();
    hasClinicAuthority = widget.initialAuthorities.contains('Clinic');
    hasAppointmentsAuthority =
        widget.initialAuthorities.contains('Appointments');
    hasStaffsAuthority = widget.initialAuthorities.contains('Staffs');
    hasMessagesAuthority = widget.initialAuthorities.contains('Messages');
  }

  void _handleUpdate() {
    List<String> updatedAuthorities = [];
    if (hasClinicAuthority) updatedAuthorities.add('Clinic');
    if (hasAppointmentsAuthority) updatedAuthorities.add('Appointments');
    if (hasStaffsAuthority) updatedAuthorities.add('Staffs');
    if (hasMessagesAuthority) updatedAuthorities.add('Messages');
    widget.onAuthoritiesUpdated(updatedAuthorities);
    Navigator.of(context).pop();
  }

  void _handleRemove() {
    widget.onRemove();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(radius: 30, backgroundColor: Colors.grey),
              const SizedBox(height: 10),
              Text(widget.staffId,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
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
                onChanged: (value) =>
                    setState(() => hasClinicAuthority = value),
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
                onChanged: (value) =>
                    setState(() => hasStaffsAuthority = value),
              ),
              SwitchListTile(
                title: const Text("Messages"),
                value: hasMessagesAuthority,
                onChanged: (value) =>
                    setState(() => hasMessagesAuthority = value),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _handleRemove,
                    child: const Text("Remove",
                        style: TextStyle(color: Colors.red)),
                  ),
                  Row(
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
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
