import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ResumeGeneratorPage extends StatefulWidget {
  const ResumeGeneratorPage({super.key});

  @override
  State<ResumeGeneratorPage> createState() => _ResumeGeneratorPageState();
}

class _ResumeGeneratorPageState extends State<ResumeGeneratorPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = false;

  // Fetch user personal details
  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('personaldetails')
        .doc('details')
        .get();

    return doc.exists ? doc.data() : null;
  }

  // Fetch projects
  Future<List<Map<String, dynamic>>> _fetchProjects(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('projects')
        .orderBy('timestamp', descending: true)
        .get();

    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Fetch achievements
  Future<List<Map<String, dynamic>>> _fetchAchievements(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('achievements')
        .orderBy('timestamp', descending: true)
        .get();

    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Generate PDF with user info, projects, and achievements
  Future<Uint8List> _generatePdf(Map<String, dynamic> userDetails,
      List<Map<String, dynamic>> projects,
      List<Map<String, dynamic>> achievements) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Text(
                  userDetails['displayName'] ?? 'Unnamed User',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  userDetails['fieldOfStudy'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.Divider(thickness: 1.5),

                // Personal Info
                pw.SizedBox(height: 12),
                pw.Text(
                  "Personal Information",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildKeyValue("Name", userDetails['displayName']),
                _buildKeyValue("College", userDetails['university']),
                _buildKeyValue("Branch", userDetails['fieldOfStudy']),
                _buildKeyValue("Degree", userDetails['degree']),
                _buildKeyValue("Domain", userDetails['maindomain']),
                _buildKeyValue("Technology", userDetails['subdomain']),

                // Skills
                pw.SizedBox(height: 16),
                pw.Text(
                  "Skills",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  (userDetails['skills'] != null &&
                          userDetails['skills'] is List)
                      ? (userDetails['skills'] as List).join(", ")
                      : 'No skills added',
                  style: const pw.TextStyle(fontSize: 14),
                ),

                // Projects
                pw.SizedBox(height: 16),
                pw.Text(
                  "Projects",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                pw.SizedBox(height: 6),
                projects.isEmpty
                    ? pw.Text("No projects yet", style: const pw.TextStyle(fontSize: 14))
                    : pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: projects.map((proj) {
                          return pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildKeyValue("Description", proj['description'] ?? '-'),
                              if (proj['githubLink'] != null)
                                _buildKeyValue("GitHub", proj['githubLink']),
                              pw.SizedBox(height: 8),
                            ],
                          );
                        }).toList(),
                      ),

                // Achievements
                pw.SizedBox(height: 16),
                pw.Text(
                  "Achievements",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                pw.SizedBox(height: 6),
                achievements.isEmpty
                    ? pw.Text("No achievements yet", style: const pw.TextStyle(fontSize: 14))
                    : pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: achievements.map((ach) {
                          return pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildKeyValue("Description", ach['description'] ?? '-'),
                              if (ach['certificateUrl'] != null)
                                _buildKeyValue("Certificate", ach['certificateUrl']),
                              pw.SizedBox(height: 8),
                            ],
                          );
                        }).toList(),
                      ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // Helper for key-value in PDF
  pw.Widget _buildKeyValue(String key, String? value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "$key: ",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.Expanded(
          child: pw.Text(
            value ?? '-',
            style: const pw.TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  // Generate Resume button logic
  Future<void> _onGenerateResume() async {
    setState(() => _loading = true);
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final userDetails = await _fetchUserProfile();
    if (userDetails == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No profile details found.")),
      );
      return;
    }

    final projects = await _fetchProjects(user.uid);
    final achievements = await _fetchAchievements(user.uid);

    final pdfBytes = await _generatePdf(userDetails, projects, achievements);

    setState(() => _loading = false);

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Resume Generator")),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _onGenerateResume,
                child: const Text(
                  "Generate Resume",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }
}
