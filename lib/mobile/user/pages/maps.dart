import 'package:capstone_app/mobile/user/components/dashboard_components/search_bar.dart';
import 'package:capstone_app/mobile/user/components/dashboard_components/tags.dart';
import 'package:flutter/material.dart';

class Maps extends StatelessWidget {
  const Maps({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 45),
        child: FloatingActionButton(
          heroTag: "btn3",
          shape: const CircleBorder(),
          child: const Icon(
            Icons.close_rounded
          ),
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.transparent,
            child: const SizedBox(
              height: 50,
              
            ),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  MySearchBar(),
                ]
              ),
            )
          ),
          const MyTags()
        ]
      ),
    );
  }
}