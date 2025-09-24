import 'package:careerclaritycompanion/features/screens/staff_login.dart';
import 'package:careerclaritycompanion/features/screens/student_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SwipeLoginPage extends StatefulWidget {
  const SwipeLoginPage({super.key});

  @override
  State<SwipeLoginPage> createState() => _SwipeLoginPageState();
}

class _SwipeLoginPageState extends State<SwipeLoginPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<String> _titles = ["Student Login", "Staff Login"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _titles[_currentIndex],
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: const [
          LoginScreen(),        // student login
          StaffLoginScreen(),   // staff login
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF42382D),
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.white54,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: "Student",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: "Staff",
          ),
        ],
      ),
    );
  }
}
