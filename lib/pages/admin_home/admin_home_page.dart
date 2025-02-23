import 'package:capstone_app/admin/components/gnav_bar.dart';
import 'package:capstone_app/admin/pages/admin_landing_page.dart';
import 'package:capstone_app/admin/pages/appointment_list.dart';
import 'package:capstone_app/admin/pages/messages.dart';
import 'package:capstone_app/admin/pages/staff_accounts.dart';
import 'package:flutter/material.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();  
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedPage = 0;

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedPage = index;
    });
  }

  final List _pages = [
    const AdminLandingPage(),
    const AppointmentListPage(),
    const MessagesPage(),
    const StaffAccountsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: GnavBar(
        onTabChange: (index) => _navigateBottomBar(index),
      ),
      body: _pages[_selectedPage],
    );
  }
}
