import 'package:capstone_app/user/components/dashboard_components/dashboard_tile.dart';
import 'package:capstone_app/user/components/dashboard_components/search_bar.dart';
import 'package:capstone_app/user/components/dashboard_components/sort_button.dart';
import 'package:capstone_app/user/components/dashboard_components/tags.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  const Color.fromARGB(255, 248, 253, 255),
      body: ListView(
        children: const [
          Center(
            child: Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 5, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:[
                    MySearchBar(),
                    SizedBox(width: 12,),
                    MySortButton(),
                  ]
                ),
              )
            ),
          MyTags(),
          MyDashboardTile(),
        ],
      ),
    );
  }
}