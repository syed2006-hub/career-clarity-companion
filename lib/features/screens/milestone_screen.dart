import 'package:careerclaritycompanion/features/screens/drawer_pages/add_achivements_page.dart';
import 'package:careerclaritycompanion/features/screens/drawer_pages/project_add_page.dart';
import 'package:careerclaritycompanion/features/screens/milestone/learn_basics_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MilestonePage extends StatelessWidget {
  const MilestonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Milestone"),
        centerTitle: true,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMilestoneCard(
            context,
            title: "Learn Basics",
            icon: Icons.lightbulb_outline,
            color: Colors.orange,
            page: LearnBasicsPage(),
          ),
          _buildMilestoneCard(
            context,
            title: "Certifications",
            icon: Icons.card_membership,
            color: Colors.teal,
                        page: AddAchievementPage(),

          ),
          _buildMilestoneCard(
            context,
            title: "Mini Projects",
            icon: Icons.construction,
            color: Colors.purple,
                       page: AddProjectPage(),

          ),
          _buildMilestoneCard(
            context,
            title: "Internships",
            icon: Icons.work_outline,
            color: Colors.redAccent,
                       page: AddAchievementPage(constructorFlag: 'intern',),

          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (context) => page),
          ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
