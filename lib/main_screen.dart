import 'package:careerclaritycompanion/features/screens/home_screen.dart';
import 'package:careerclaritycompanion/features/screens/profile_screens.dart';
import 'package:careerclaritycompanion/features/screens/saved_courses_screen.dart';
import 'package:careerclaritycompanion/features/screens/skill_up_screen.dart';
import 'package:careerclaritycompanion/graggable_fab.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// --- Placeholder for missing screens ---
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title Screen',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
// ----------------------------------------------------------------

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final userdata = FirebaseAuth.instance.currentUser;

  int _currentIndex = 2;

  // Pages list
  final List<Widget> _pages = [
    SavedCoursesPage(),
    const PlaceholderScreen(title: 'Milestones'),
    HomePage(),
    SkillUpScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Using IndexedStack keeps state of all pages
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pages),
          const DraggableFab(), // floating widget above all
        ],
      ),

      // Bottom navigation using ConvexAppBar
      bottomNavigationBar: ConvexAppBar(
        height: 60,
        style: TabStyle.reactCircle,
        backgroundColor: Colors.white,
        activeColor: Theme.of(context).colorScheme.secondary,
        color: Theme.of(context).colorScheme.secondary,

        items: [
          TabItem(icon: Icons.bookmark_added_outlined, title: 'Saved'),
          TabItem(icon: Icons.track_changes, title: 'Milestones'),
          TabItem(icon: Icons.home_outlined, title: 'Home'),
          TabItem(icon: Icons.trending_up, title: 'Skill Up'),
          TabItem(
            icon: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.userChanges(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                if (user != null &&
                    user.photoURL != null &&
                    user.photoURL!.isNotEmpty) {
                  return CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(user.photoURL!),
                  );
                } else {
                  return const Icon(Icons.account_circle_rounded);
                }
              },
            ),
            title: 'Profile',
          ),
        ],
        initialActiveIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        
      ),
    );
  }
}
