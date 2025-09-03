import 'package:careerclaritycompanion/features/screens/domain_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SkillUpScreen extends StatefulWidget {
  const SkillUpScreen({super.key});

  @override
  State<SkillUpScreen> createState() => _SkillUpScreenState();
}

class _SkillUpScreenState extends State<SkillUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _mainDomain; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDomains();
  }

  Future<void> _fetchDomains() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc =
          await _firestore
              .collection("users")
              .doc(user.uid)
              .collection("personaldetails")
              .doc("details")
              .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _mainDomain = data['maindomain'] as String?; 
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching domains: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : DomainDetailScreen(domainId: _mainDomain!);
  }
}
