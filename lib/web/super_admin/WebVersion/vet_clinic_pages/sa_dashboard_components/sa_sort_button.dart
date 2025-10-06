import 'package:flutter/material.dart';

class SuperAdminSortButton extends StatefulWidget {
  final Function(String)? onSortChanged;

  const SuperAdminSortButton({
    super.key,
    this.onSortChanged,
  });

  @override
  State<SuperAdminSortButton> createState() => _SuperAdminSortButtonState();
}

class _SuperAdminSortButtonState extends State<SuperAdminSortButton> {
  String selectedSort = 'name';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 81, 115, 153),
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.sort, color: Colors.white),
        tooltip: 'Sort',
        onSelected: (value) {
          setState(() {
            selectedSort = value;
          });
          widget.onSortChanged?.call(value);
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'name',
            child: Row(
              children: [
                Icon(
                  Icons.sort_by_alpha,
                  color: selectedSort == 'name'
                      ? const Color.fromARGB(255, 81, 115, 153)
                      : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Text(
                  'Name (A-Z)',
                  style: TextStyle(
                    fontWeight: selectedSort == 'name'
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selectedSort == 'name'
                        ? const Color.fromARGB(255, 81, 115, 153)
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'date',
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: selectedSort == 'date'
                      ? const Color.fromARGB(255, 81, 115, 153)
                      : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Text(
                  'Registration Date',
                  style: TextStyle(
                    fontWeight: selectedSort == 'date'
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selectedSort == 'date'
                        ? const Color.fromARGB(255, 81, 115, 153)
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'status',
            child: Row(
              children: [
                Icon(
                  Icons.toggle_on,
                  color: selectedSort == 'status'
                      ? const Color.fromARGB(255, 81, 115, 153)
                      : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Text(
                  'Status (Open/Closed)',
                  style: TextStyle(
                    fontWeight: selectedSort == 'status'
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selectedSort == 'status'
                        ? const Color.fromARGB(255, 81, 115, 153)
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}