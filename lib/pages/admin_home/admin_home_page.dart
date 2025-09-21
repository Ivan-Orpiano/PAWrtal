import 'package:capstone_app/mobile/admin/components/gnav_bar.dart';
import 'package:capstone_app/mobile/admin/pages/admin_landing_page.dart';
import 'package:capstone_app/mobile/admin/pages/appointment_list.dart';
import 'package:capstone_app/mobile/admin/pages/messages.dart';
import 'package:capstone_app/mobile/admin/pages/staff_account_list.dart';
import 'package:flutter/material.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => AdminHomePageState();  
}

class AdminHomePageState extends State<AdminHomePage> {
  int _selectedPage = 0;

  void navigateBottomBar(int index) {
    setState(() {
      _selectedPage = index;
    });
  }

  final List<Widget> _pages = [
    const AdminLandingPage(),
    const EnhancedAppointmentListPage(),
    const MessagesPage(),
    const StaffAccountsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: GnavBar(
        selectedIndex: _selectedPage, // Pass the selected index
        onTabChange: (index) => navigateBottomBar(index),
      ),
      body: IndexedStack( // Use IndexedStack to preserve state
        index: _selectedPage,
        children: _pages,
      ),
    );
  }
}