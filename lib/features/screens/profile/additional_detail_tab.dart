import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdditionalDetailsScreen extends StatefulWidget {
  const AdditionalDetailsScreen({super.key});

  @override
  State<AdditionalDetailsScreen> createState() =>
      _AdditionalDetailsScreenState();
}

class _AdditionalDetailsScreenState extends State<AdditionalDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc =
            await _firestore
                .collection("users")
                .doc(user.uid)
                .collection("personaldetails")
                .doc("details")
                .get();

        if (doc.exists && doc.data() != null) {
          setState(() {
            _userDetails = doc.data();
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user details: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          value,
          style: TextStyle(color: Colors.grey[700], fontSize: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Additional Details"), 
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _userDetails == null || _userDetails!.isEmpty
              ? const Center(
                child: Text(
                  "No details found.",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
              : ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  // Profile header
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            backgroundImage:
                                user?.photoURL != null
                                    ? NetworkImage(user!.photoURL!)
                                    : null,
                            child:
                                user?.photoURL == null
                                    ? Text(
                                      _userDetails?['displayName']
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          'U',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                      ),
                                    )
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _userDetails?['displayName'] ?? 'Username',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Display selected fields
                  if (_userDetails?['degree'] != null)
                    _buildDetailCard(
                      "Degree",
                      _userDetails!['degree'],
                      Icons.school_outlined,
                    ),
                  if (_userDetails?['university'] != null)
                    _buildDetailCard(
                      "University",
                      _userDetails!['university'],
                      Icons.location_city_outlined,
                    ),
                  if (_userDetails?['fieldOfStudy'] != null)
                    _buildDetailCard(
                      "Field of Study",
                      _userDetails!['fieldOfStudy'],
                      Icons.menu_book_outlined,
                    ),
                  if (_userDetails?['preferredDomain'] != null)
                    _buildDetailCard(
                      "Preferred Domain",
                      (_userDetails!['preferredDomain'] as String) ,
                      Icons.domain_rounded,
                    ),
                  if (_userDetails?['skills'] != null)
                    _buildDetailCard(
                      "Skills",
                      (_userDetails!['skills'] as List).join(", "),
                      Icons.lightbulb_outline,
                    ),
                  if (_userDetails?['resumeUrl'] != null)
                    Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.file_present_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text("Resume"),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            final url = _userDetails!['resumeUrl'];
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Cannot open resume URL"),
                                ),
                              );
                            }
                          },
                          child: const Text("View Resume"),
                        ),
                      ),
                    ),
                ],
              ),
    );
  }
}
