import 'package:careerclaritycompanion/data/models/course_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class LearnBasicsPage extends StatefulWidget {
  const LearnBasicsPage({super.key});

  @override
  State<LearnBasicsPage> createState() => _LearnBasicsPageState();
}

class _LearnBasicsPageState extends State<LearnBasicsPage> {
  String? _mainDomain;
  String? _subDomain;
  bool _loading = true;
  List<CourseModel> _courses = [];

  @override
  void initState() {
    super.initState();
    _fetchUserDomain();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await canLaunchUrl(url)) {
      print("Could not launch $urlString");
      return;
    }
    await launchUrl(url, mode: LaunchMode.inAppBrowserView);
  }

  Future<void> _fetchUserDomain() async {
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
        _mainDomain = data["maindomain"];
        _subDomain = data["subdomain"];
        await _fetchCourses();
      }
    } catch (e) {
      debugPrint("Error fetching domain: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchCourses() async {
    if (_mainDomain == null) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection("domains")
              .doc(_mainDomain)
              .collection("courses")
              .get();

      final keywords =
          (_subDomain ?? "")
              .toLowerCase()
              .split(" ")
              .where((s) => s.isNotEmpty)
              .toList();

      _courses =
          snapshot.docs.map((doc) => CourseModel.fromMap(doc.data())).where((
            course,
          ) {
            final title = course.title.toLowerCase();
            return keywords.isEmpty || keywords.any((kw) => title.contains(kw));
          }).toList();

      _courses.sort((a, b) => b.rating.compareTo(a.rating));
    } catch (e) {
      debugPrint("Error fetching courses: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Learn Basics"),
        centerTitle: true,
        elevation: 1,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _courses.isEmpty
              ? const Center(child: Text("No courses found for this domain."))
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  return _buildCourseCard(course);
                },
              ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading:
            course.imageUrl.isNotEmpty
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    course.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                )
                : const Icon(Icons.school, size: 40, color: Colors.blueAccent),
        title: Text(
          course.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.platform,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  course.rating.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 16, color: Colors.amber),
              ],
            ),
           
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new, color: Colors.blueAccent),
          onPressed: () => _launchUrl(course.url),
        ),
      ),
    );
  }
}
