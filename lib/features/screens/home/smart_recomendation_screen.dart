import 'dart:ui';
import 'package:careerclaritycompanion/data/models/course_model.dart';
import 'package:careerclaritycompanion/data/models/internship_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SmartRecommendationSlider extends StatefulWidget {
  const SmartRecommendationSlider({super.key});

  @override
  State<SmartRecommendationSlider> createState() =>
      _SmartRecommendationSliderState();
}

class _SmartRecommendationSliderState extends State<SmartRecommendationSlider> {
  String? _mainDomain;
  String? _subDomain;
  bool _isLoading = true;
  List<CourseModel> _courses = [];
  List<JobListing> _internships = [];
  List<Map<String, dynamic>> _projects = [];
  final CarouselSliderController _controller = CarouselSliderController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), _fetchUserDomain);
  }

  Future<void> _fetchUserDomain() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("personaldetails")
          .doc("details")
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _mainDomain = data['maindomain'] as String?;
        _subDomain = data['subdomain'] as String?;
        await _fetchRecommendations();
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error fetching domain: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRecommendations() async {
    if (_mainDomain == null || _mainDomain!.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final coursesSnapshot = await FirebaseFirestore.instance.collection("domains").doc(_mainDomain).collection("courses").get();
      final internshipsSnapshot = await FirebaseFirestore.instance.collection("domains").doc(_mainDomain).collection("internships").get();
      final projectsSnapshot = await FirebaseFirestore.instance.collection("domains").doc(_mainDomain).collection("projects").get();

      final keywords = (_subDomain ?? "").toLowerCase().split(' ').where((s) => s.isNotEmpty).toList();

      if (keywords.isNotEmpty) {
        _courses = coursesSnapshot.docs
            .map((doc) => CourseModel.fromMap(doc.data()))
            .where((course) {
          final title = course.title.toLowerCase();
          return keywords.any((kw) => title.contains(kw));
        })
            .toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
        if (_courses.length > 2) _courses = _courses.sublist(0, 2);

        _internships = internshipsSnapshot.docs
            .map((doc) => JobListing.fromMap(doc.data()))
            .where((intern) {
          final title = intern.title.toLowerCase();
          return keywords.any((kw) => title.contains(kw));
        })
            .toList();
        if (_internships.length > 2) _internships = _internships.sublist(0, 2);

        _projects = projectsSnapshot.docs
            .map((doc) => doc.data())
            .where((proj) => keywords.any((kw) => (proj['title'] as String?)?.toLowerCase().contains(kw) ?? false))
            .toList();
        if (_projects.length > 2) _projects = _projects.sublist(0, 2);
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print("Error fetching recommendations: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final recommendations = [
      ..._courses.map((c) => {"type": "course", "data": c}),
      ..._internships.map((i) => {"type": "internship", "data": i}),
      ..._projects.map((p) => {"type": "project", "data": p}),
    ];

    if (recommendations.isEmpty) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Center(
          child: Text(
            "No specific recommendations found.\nExplore domains to see more!",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: recommendations.length,
          carouselController: _controller,
          options: CarouselOptions(
            height: 260,
            viewportFraction: 0.85,
            enlargeCenterPage: true,
            enlargeFactor: 0.2,
            enableInfiniteScroll: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 8),
            onPageChanged: (index, reason) =>
                setState(() => _currentIndex = index),
          ),
          itemBuilder: (context, index, realIndex) {
            final item = recommendations[index];
            switch (item['type']) {
              case "course":
                return _buildCourseCard(item['data'] as CourseModel);
              case "internship":
                return _buildInternshipCard(item['data'] as JobListing);
              case "project":
                return _buildProjectCard(item['data'] as Map<String, dynamic>);
              default:
                return const SizedBox.shrink();
            }
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: recommendations.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _controller.animateToPage(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _currentIndex == entry.key ? 24.0 : 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentIndex == entry.key
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await canLaunchUrl(url)) {
      print("Could not launch $urlString");
      return;
    }
    await launchUrl(url, mode: LaunchMode.inAppBrowserView);
  }

  Widget _buildGlassmorphicBase({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: child,
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return _buildGlassmorphicBase(
      child: Stack(
        fit: StackFit.expand,
        children: [
          course.imageUrl.isNotEmpty
              ? Image.network(course.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.school, size: 60, color: Colors.white30))
              : const Center(
              child: Icon(Icons.school, size: 60, color: Colors.white30)),
          Container(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5))),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(course.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: _InfoChip(icon: Icons.school_outlined, text: course.platform, color: Colors.white70),
                    ),
                    const SizedBox(width: 8), 
                    Row(
                      children: [
                        Text(course.rating.toStringAsFixed(1), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _launchUrl(course.url),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), foregroundColor: Colors.white),
                    child: const Text("View Course"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternshipCard(JobListing intern) {
    return _buildGlassmorphicBase(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.1),
                backgroundImage: intern.companyLogoUrl.isNotEmpty
                    ? NetworkImage(intern.companyLogoUrl)
                    : null,
                child: intern.companyLogoUrl.isEmpty
                    ? const Icon(Icons.business, color: Colors.white70)
                    : null,
              ),
              title: Text(intern.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
              subtitle: Text('at ${intern.companyName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white70)),
            ),
            const Spacer(),
            _InfoChip(icon: Icons.location_on_outlined, text: intern.companyLocation),
            const SizedBox(height: 6),
            _InfoChip(icon: Icons.access_time_rounded, text: intern.postedAgo),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _launchUrl(intern.url),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), foregroundColor: Colors.white),
                child: const Text("Apply Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final title = project['title'] ?? "Project Idea";
    final description = project['description'] ?? "No description available.";
    return _buildGlassmorphicBase(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.lightbulb_outline, color: Colors.white),
              ),
              title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(color: Colors.white70, height: 1.5),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), foregroundColor: Colors.white),
                child: const Text("View Details"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.text, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    // ✨ FIX: This robust version uses Flexible around the Text.
    // This allows the text to fill the available space within its parent
    // without causing an overflow, enabling ellipsis to work correctly.
    return Row(
      children: [
        Icon(icon, color: color.withOpacity(0.8), size: 16),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: GoogleFonts.poppins(color: color, fontSize: 13),
          ),
        ),
      ],
    );
  }
}