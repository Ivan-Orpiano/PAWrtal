import 'package:flutter/material.dart';

class MyTags extends StatefulWidget {
  const MyTags({super.key});

  @override
  State<MyTags> createState() => _MyTagsState();
}

class _MyTagsState extends State<MyTags> {

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left:10, top: 10, right: 5, bottom: 10 ),
            child: ChoiceChip(
              elevation: 5,
              selectedColor: const Color.fromARGB(255, 81, 115, 153),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)
              ),
              label: const Text(
                "All",
                style: TextStyle(
                  fontSize: 15
                ),
              ),
              selected: _selectedIndex == 0,
              onSelected: (newState){
                setState(() {
                  _selectedIndex = 0;
                });
              },
            ),
          ),
                    Padding(
            padding: const EdgeInsets.only(left:10, top: 10, right: 5, bottom: 10 ),
            child: ChoiceChip(
              elevation: 5,
              selectedColor: const Color.fromARGB(255, 81, 115, 153),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)
              ),
              label: const Text(
                "Nearby",
                style: TextStyle(
                  fontSize: 15
                ),
              ),
              selected: _selectedIndex == 1,
              onSelected: (newState){
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left:10, top: 10, right: 5, bottom: 10 ),
            child: ChoiceChip(
              elevation: 5,
              selectedColor: const Color.fromARGB(255, 81, 115, 153),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)
              ),
              label: const Text(
                "Popular",
                style: TextStyle(
                  fontSize: 15
                ),
              ),
              selected: _selectedIndex == 2,
              onSelected: (newState){
                setState(() {
                  _selectedIndex = 2;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left:10, top: 10, right: 5, bottom: 10 ),
            child: ChoiceChip(
              elevation: 5,
              selectedColor: const Color.fromARGB(255, 81, 115, 153),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)
              ),
              label: const Text(
                "Reccomended",
                style: TextStyle(
                  fontSize: 15
                ),
              ),
              selected: _selectedIndex == 3,
              onSelected: (newState){
                setState(() {
                  _selectedIndex = 3;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}