import 'dart:math'; // Required for sin/cos in animation
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ✨ Keep your existing imports
import 'package:careerclaritycompanion/data/models/company_model.dart';
import 'package:careerclaritycompanion/features/custom_widgets/custom_drawer.dart';
import 'package:careerclaritycompanion/features/screens/home/ai_coachslider_screen.dart';
import 'package:careerclaritycompanion/data_seeder/all_domain_screen.dart';
import 'package:careerclaritycompanion/features/screens/home/company_list_screen.dart';
import 'package:careerclaritycompanion/features/screens/home/domain/domain_list.dart';
import 'package:careerclaritycompanion/features/screens/home/smart_recomendation_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// ✨ Add 'SingleTickerProviderStateMixin' to host the animation controller
class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final userdata = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ✨ 1. Animation controller and blobs for the background
  late AnimationController _animationController;
  late List<Blob> _blobs;

  @override
  void initState() {
    super.initState();
    // ✨ 2. Initialize the animation controller and blobs
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _blobs = [
      Blob(
        initialRadius: 220, initialX: 0.1, initialY: 0.1, speed: 1.2,
        color: const Color(0xFF42382D).withOpacity(0.7),
      ),
      Blob(
        initialRadius: 280, initialX: 0.9, initialY: 0.8, speed: 0.8,
        color: const Color(0xFF42382D).withOpacity(0.5),
      ),
      Blob(
        initialRadius: 150, initialX: 0.2, initialY: 0.7, speed: 1.0,
        color: const Color(0xFF42382D).withOpacity(0.6),
      ),
    ];
  }

  @override
  void dispose() {
    // ✨ 3. Dispose the controller to prevent memory leaks
    _animationController.dispose();
    super.dispose();
  }

  String getFirstTwoWords(String? name) {
    if (name == null || name.trim().isEmpty) return 'User';
    List<String> words = name.trim().split(' ');
    return words.length >= 2 ? '${words[0]} ${words[1]}' : words[0];
  }

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: const [FadeEffect(duration: Duration(milliseconds: 500))],
      child: Scaffold(
        key: _scaffoldKey,
        extendBodyBehindAppBar: true,
        drawer: const CustomDrawer(),
        body: Stack(
          children: [
            // ✨ 4. The new Jelly background
            JellyBackground(controller: _animationController, blobs: _blobs),

            // Your existing UI content
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [_buildSliverAppBar()];
              },
              body: _buildContentBody(),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      backgroundColor: const Color(0xFF42382D),
      elevation: 0,
      pinned: true,
      floating: true,
      snap: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hi, ${getFirstTwoWords(userdata?.displayName)} 👋",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          Text(
            "Let's find your dream career",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.userChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
                return CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(user.photoURL!),
                  ),
                );
              }
              return const Icon(Icons.account_circle, size: 40, color: Colors.white);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContentBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const GuidanceCard(),
            const SizedBox(height: 30),
            const _SectionHeader(title: "Smart Recommendations"),
            SmartRecommendationSlider().animate().fadeIn(delay: 400.ms).slideX(),
            const SizedBox(height: 30),
            const _SectionHeader(title: "Top Companies"),
            CompanyTickerWrapper().animate().fadeIn(delay: 500.ms).slideX(),
            const SizedBox(height: 30),
            _SectionHeader(
              title: "Popular Domains",
              onViewAll: () => Navigator.of(context).push(
                CupertinoPageRoute(builder: (context) => AllDomainScreen()),
              ),
            ),
            DomainListScreen().animate().fadeIn(delay: 600.ms).slideX(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// Reusable Section Header Widget (remains the same)
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: Text(
                'View all',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }
}

// CompanyTickerWrapper (remains the same)
class CompanyTickerWrapper extends StatelessWidget {
  const CompanyTickerWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('companies').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading companies", style: TextStyle(color: Colors.white70)));
        }
        final companies = snapshot.data!.docs
            .map((doc) => CompanyInfo.fromSnapshot(doc))
            .toList();
        return CompanyTicker(companies: companies);
      },
    );
  }
}

// ✨ --- JELLY BACKGROUND WIDGETS --- ✨
// (Copied from the previous example)

// A simple data class to hold the properties of a single blob.
class Blob {
  final double initialRadius;
  final double initialX;
  final double initialY;
  final double speed;
  final Color color;
  Offset position;
  double radius;

  Blob({
    required this.initialRadius,
    required this.initialX,
    required this.initialY,
    required this.speed,
    required this.color,
  })  : position = Offset(initialX, initialY),
        radius = initialRadius;

  void move(double animationValue, Size screenSize) {
    final double newX =
        initialX + sin(animationValue * speed) * (screenSize.width * 0.2);
    final double newY =
        initialY + cos(animationValue * speed) * (screenSize.height * 0.2);
    position = Offset(newX, newY);
    radius = initialRadius + sin(animationValue * speed * 0.8) * 15;
  }
}

// This widget contains the background animation logic
class JellyBackground extends StatefulWidget {
  final AnimationController controller;
  final List<Blob> blobs;

  const JellyBackground({super.key, required this.controller, required this.blobs});

  @override
  State<JellyBackground> createState() => _JellyBackgroundState();
}

class _JellyBackgroundState extends State<JellyBackground> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), // Dark background color
      ),
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) {
          final screenSize = MediaQuery.of(context).size;
          for (var blob in widget.blobs) {
            blob.move(widget.controller.value * 2 * pi, screenSize);
          }
          return CustomPaint(
              painter: BackgroundPainter(blobs: widget.blobs),
              size: Size.infinite);
        },
      ),
    );
  }
}

// This painter is responsible for drawing the blobs on the canvas
class BackgroundPainter extends CustomPainter {
  final List<Blob> blobs;

  BackgroundPainter({required this.blobs});

  @override
  void paint(Canvas canvas, Size size) {
    for (var blob in blobs) {
      final paint = Paint()..color = blob.color;
      final correctedInitialX = blob.initialX * size.width;
      final correctedInitialY = blob.initialY * size.height;

      final animationValue =
          (DateTime.now().millisecondsSinceEpoch / (1000 * 40)) * 2 * pi;
      final newX =
          correctedInitialX + sin(blob.speed * animationValue) * (size.width * 0.2);
      final newY = correctedInitialY +
          cos(blob.speed * animationValue) * (size.height * 0.2);

      final breathingValue = sin(blob.speed * 0.8 * animationValue);
      final newRadius = blob.initialRadius + breathingValue * 15;

      canvas.drawCircle(Offset(newX, newY), newRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for continuous animation
  }
}