import 'package:flutter/material.dart';

class MyTags extends StatefulWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final int Function(String) getFilterCount;

  const MyTags({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.getFilterCount,
  });

  @override
  State<MyTags> createState() => _MyTagsState();
}

class _MyTagsState extends State<MyTags> {
  final List<String> tags = [
    "All",
    "Open",
    "Available Today",
    "Closed",
    "Popular",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags[index];
          final isSelected = widget.selectedFilter == tag;
          final count = widget.getFilterCount(tag);

          return Padding(
            padding: const EdgeInsets.only(left: 10, right: 5),
            child: ChoiceChip(
              checkmarkColor: Colors.white,
              elevation: 3,
              selectedColor: const Color.fromARGB(255, 81, 115, 153),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? const Color.fromARGB(255, 81, 115, 153)
                    : Colors.grey.shade300,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              label: Text(
                count > 0 && tag != 'All' ? '$tag ($count)' : tag,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                if (selected) {
                  widget.onFilterChanged(tag);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
