import 'package:careerclaritycompanion/data/models/course_model.dart';
import 'package:careerclaritycompanion/data/models/internship_model.dart'; // Ensure you have this import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';

class SmartRecommendationSlider extends StatefulWidget {
  const SmartRecommendationSlider({super.key});

  @override
  State<SmartRecommendationSlider> createState() =>
      _SmartRecommendationSliderState();
}

class _SmartRecommendationSliderState extends State<SmartRecommendationSlider> {
  // --- Data Fetching Logic (Unchanged) ---
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
    _fetchUserDomain();
  }

  Future<void> _fetchUserDomain() async {
    // This logic remains the same as in your original code
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance
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
      }
    } catch (e) {
      print("Error fetching domain: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchRecommendations() async {
    if (_mainDomain == null) return;

    try {
      // Fetch data from Firestore
      final coursesSnapshot =
          await FirebaseFirestore.instance
              .collection("domains")
              .doc(_mainDomain)
              .collection("courses")
              .get();

      final internshipsSnapshot =
          await FirebaseFirestore.instance
              .collection("domains")
              .doc(_mainDomain)
              .collection("internships")
              .get();

      final projectsSnapshot =
          await FirebaseFirestore.instance
              .collection("domains")
              .doc(_mainDomain)
              .collection("projects")
              .get();

      final subDomainKeyword = _subDomain?[0].toLowerCase() ?? "";

      // 1️⃣ Courses: filter by subdomain keyword in title or description, sort by rating, top 2
      final keywords = (_subDomain ?? "").toLowerCase().split(' ');

      // Courses: filter by any keyword in title or description
      _courses =
          coursesSnapshot.docs
              .map((doc) => CourseModel.fromMap(doc.data()))
              .where((course) {
                final title = course.title.toLowerCase();
                return keywords.any((kw) => title.contains(kw));
              })
              .toList()
            ..sort((a, b) => b.rating.compareTo(a.rating)); // top rated first

      if (_courses.length > 2) _courses = _courses.sublist(0, 2);

      _internships =
          internshipsSnapshot.docs
              .map((doc) => JobListing.fromMap(doc.data()))
              .where((intern) {
                final title = intern.title.toLowerCase();
                return keywords.any((kw) => title.contains(kw));
              })
              .toList();
      if (_internships.length > 2) _internships = _internships.sublist(0, 2);

      // 3️⃣ Projects: filter by subdomain field, top 2
      _projects =
          projectsSnapshot.docs
              .map((doc) => doc.data())
              .where(
                (proj) =>
                    (proj['subdomain'] as String?)?.toLowerCase() ==
                    subDomainKeyword,
              )
              .toList();
      if (_projects.length > 2) _projects = _projects.sublist(0, 2);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching recommendations: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final recommendations = [
      ..._courses.map((c) => {"type": "course", "data": c}),
      ..._internships.map((i) => {"type": "internship", "data": i}),
      ..._projects.map((p) => {"type": "project", "data": p}),
    ];

    if (recommendations.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(
          child: Text(
            "No recommendations available yet.",
            style: TextStyle(color: Colors.grey),
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
            viewportFraction: 0.85, // Shows a peek of the next card
            enlargeCenterPage: false,
            enableInfiniteScroll: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 10),
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
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
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              recommendations.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => _controller.animateToPage(entry.key),
                  child: Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentIndex == entry.key
                              ? Theme.of(context)
                                  .colorScheme
                                  .secondary  
                              : Colors.grey,  
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  // Helper method to launch URLs safely
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await canLaunchUrl(url)) {
      // Optionally show a snackbar or alert to the user
      print("Could not launch $urlString");
      return;
    }
    await launchUrl(url, mode: LaunchMode.inAppBrowserView);
  }

  // --- New and Improved Card Widgets ---

  /// Builds a visually appealing card for a course recommendation.
  Widget _buildCourseCard(CourseModel course) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior:
          Clip.antiAlias, // Ensures the image respects the border radius
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image with a fallback
          course.imageUrl.isNotEmpty
              ? Image.network(
                course.imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Icon(Icons.school, size: 60, color: Colors.grey),
              )
              : Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.school, size: 60, color: Colors.grey),
                ),
              ),

          // Gradient overlay for text readability
          Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4)),
          ),

          // Content
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      course.platform,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      course.rating.toStringAsFixed(1),
                      style: TextStyle(color: Colors.white),
                    ),
                    Icon(Icons.star, color: Colors.amber),

                    Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _launchUrl(course.url),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),

                      icon: Icon(Icons.open_in_new, color: Colors.black),
                      iconAlignment: IconAlignment.end,
                      label: Text(
                        "View Course",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a professional and informative card for an internship.
  Widget _buildInternshipCard(JobListing intern) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with company logo and info
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    intern.companyLogoUrl.isNotEmpty
                        ? NetworkImage(intern.companyLogoUrl)
                        : null,
                child:
                    intern.companyLogoUrl.isEmpty
                        ? const Icon(Icons.business, color: Colors.grey)
                        : null,
              ),
              title: Text(
                intern.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Company: ${intern.companyName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),

            // Key details with icons
            _InfoChip(
              icon: Icons.location_on_outlined,
              text: intern.companyLocation,
            ),
            const SizedBox(height: 6),
            _InfoChip(icon: Icons.date_range, text: intern.postedAgo),
            const Spacer(),

            // Action Button
            Row(
              children: [
                Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(intern.url),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                  ),
                  icon: Icon(Icons.open_in_new, color: Colors.white),
                  iconAlignment: IconAlignment.end,
                  label: const Text(
                    "Apply Now",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a simple and clean card for a project idea.
  Widget _buildProjectCard(Map<String, dynamic> project) {
    final theme = Theme.of(context);
    final title = project['title'] ?? "Project Idea";
    final description = project['description'] ?? "No description available.";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // You can add navigation to a project details page here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: const Text("View Details"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Helper Widgets for Cleaner Code ---

/// A small widget to display an icon and text, used in the internship card.
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
