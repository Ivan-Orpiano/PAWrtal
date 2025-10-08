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
        color: const Color.fromRGBO(249, 253, 255, 1),
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
                  size: 20,
                  color: selectedSort == 'name'
                      ? const Color.fromARGB(255, 81, 115, 153)
                      : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alphabetically (A-Z)',
                        style: TextStyle(
                          fontWeight: selectedSort == 'name'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selectedSort == 'name'
                              ? const Color.fromARGB(255, 81, 115, 153)
                              : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Sort by clinic name',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
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
                  size: 20,
                  color: selectedSort == 'date'
                      ? const Color.fromARGB(255, 81, 115, 153)
                      : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registration Date',
                        style: TextStyle(
                          fontWeight: selectedSort == 'date'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selectedSort == 'date'
                              ? const Color.fromARGB(255, 81, 115, 153)
                              : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Newest first',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
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
                  size: 20,
                  color: selectedSort == 'status'
                      ? const Color.fromARGB(255, 81, 115, 153)
                      : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Operating Status',
                        style: TextStyle(
                          fontWeight: selectedSort == 'status'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selectedSort == 'status'
                              ? const Color.fromARGB(255, 81, 115, 153)
                              : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Open clinics first',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
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