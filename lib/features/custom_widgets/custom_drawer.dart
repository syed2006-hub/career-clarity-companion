import 'package:careerclaritycompanion/features/custom_widgets/confirmation_dialog.dart';
import 'package:careerclaritycompanion/features/screens/drawer_pages/add_achivements_page.dart';
import 'package:careerclaritycompanion/features/screens/drawer_pages/edit_user.dart';
import 'package:careerclaritycompanion/features/screens/drawer_pages/leader_board_screen.dart';
import 'package:careerclaritycompanion/features/screens/drawer_pages/project_add_page.dart';
import 'package:careerclaritycompanion/features/screens/drawer_pages/resume_page.dart';
import 'package:careerclaritycompanion/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  void _refreshUser() {
    setState(() {
      user = FirebaseAuth.instance.currentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🔹 Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
            ),
            currentAccountPicture: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage:
                  user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child:
                  user?.photoURL == null
                      ? Text(
                        user?.displayName?[0].toUpperCase() ?? "U",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      )
                      : null,
            ),
            accountName: Text(
              user?.displayName ?? "Student",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              user?.email ?? "student@gmail.com",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          _buildDrawerTile(
            icon: Icons.leaderboard,
            title: "LeaderBoard",
            page: const LeaderboardScreen(),
          ),
          // 🔹 Drawer Items
          _buildDrawerTile(
            icon: Icons.edit,
            title: "Edit Profile",
            page: const EditUserPage(),
          ),
          _buildDrawerTile(
            icon: Icons.emoji_events,
            title: "Add Achievements",
            page: const AddAchievementPage(),
          ),
          _buildDrawerTile(
            icon: Icons.work,
            title: "Add Projects",
            page: const AddProjectPage(),
          ),
          _buildDrawerTile(
            icon: Icons.picture_as_pdf,
            title: "Resume Generator",
            page: ResumeGeneratorPage(),
          ),
          const Spacer(),

          // 🔹 Logout Button
          ListTile(
            tileColor: Colors.red.shade50,
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder:
                    (context) => ConfirmationDialog(
                      title: 'Log Out',
                      content: 'Are you sure you want to log out?',
                      confirmText: 'Log Out',
                      cancelText: 'Cancel',
                      icon: Icons.logout,
                      confirmOnPressed: () async {
                        await FirebaseAuth.instance.signOut();

                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const AuthGate(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                    ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      trailing: const Icon(Icons.arrow_right),
      onTap: () async {
        final updated = await Navigator.of(
          context,
        ).push(CupertinoPageRoute(builder: (context) => page));

        if (updated == true) {
          // 🔄 refresh the user object and rebuild drawer
          _refreshUser();
        }
      },
    );
  }
}
