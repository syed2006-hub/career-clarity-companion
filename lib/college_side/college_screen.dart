import 'package:careerclaritycompanion/features/screens/drawer_pages/leader_board_screen.dart';
import 'package:careerclaritycompanion/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ⚠️ Make sure to import your actual LeaderboardScreen file
// import 'package:careerclaritycompanion/features/screens/drawer_pages/leader_board_screen.dart';

// This is a placeholder for your actual screen

// --- Main Screen with Bottom Navigation ---

class CollegeScreen extends StatefulWidget {
  const CollegeScreen({super.key});

  @override
  State<CollegeScreen> createState() => _CollegeScreenState();
}

class _CollegeScreenState extends State<CollegeScreen> {
  int _selectedIndex = 1;

  // List of the pages to be displayed
  static const List<Widget> _pages = <Widget>[
    LeaderboardScreen(flag: 'college',), // Your existing leaderboard screen
    HomePage(),
    StaffProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body will display the page corresponding to the selected nav item
      body: Center(child: _pages.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF1E212A), // Dark background color
        selectedItemColor:
            Colors.cyanAccent, // Highlight color for selected item
        unselectedItemColor: Colors.white70, // Color for unselected items
      ),
    );
  }
}

// --- 1. Home Page Widget ---

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C24),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your Logo
            Image.asset('assets/logo.jpeg', width: 150, height: 150),
            const SizedBox(height: 24),
            // Greeting Message
            Text(
              'Welcome to Career Clarity Companion!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StaffProfilePage extends StatelessWidget {
  const StaffProfilePage({super.key});

  // --- Logout Function ---
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Navigate to login or welcome page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthGate(),
      ), // replace with your login page
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("No user logged in")));
    }

    final userDoc =
        FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

    return FutureBuilder<DocumentSnapshot>(
      future: userDoc,
      builder: (context, snapshot) {
        String phone = 'Not provided';
        String name = currentUser.displayName ?? 'No Name';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          phone = data['phone'] ?? 'Not provided';
          name = data['name'] ?? name;
        }

        return Scaffold(
          backgroundColor: const Color(0xFF1A1C24),
          appBar: AppBar(
            title: Text(
              'Profile',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF1E212A),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _logout(context),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage:
                    currentUser.photoURL != null
                        ? NetworkImage(currentUser.photoURL!)
                        : const NetworkImage('https://via.placeholder.com/150'),
                backgroundColor: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              _buildInfoTile(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: currentUser.email ?? 'Not provided',
              ),
              _buildInfoTile(
                icon: Icons.phone_outlined,
                title: 'Phone',
                subtitle: phone,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      color: const Color(0xFF2C313C),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.cyanAccent),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
      ),
    );
  }
}
