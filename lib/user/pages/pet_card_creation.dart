import 'package:flutter/material.dart';

class PetCardCreation extends StatefulWidget {
  const PetCardCreation({super.key});

  @override
  State<PetCardCreation> createState() => _PetCardCreationState();
}

class _PetCardCreationState extends State<PetCardCreation> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 150,
        leading: IconButton(
          iconSize: 30,
          icon: const Icon(Icons.keyboard_arrow_left_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Create Pet Card",
        ),
      ),
      body: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Container(
                    height: 250,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50
                    ),
                    child: const Icon(
                      Icons.add_rounded
                    ),
                  ),
                ),
              )
            ],
          ), 
          const Text(
            "Name"
          ),
          const Text(
            "Type"
          ),
          const Text(
            "Breed"
          )
        ],
      ),
    );
  }
}