  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:careerclaritycompanion/data/models/internship_model.dart';

  final internshipStreamProvider = StreamProvider.family<List<JobListing>, String>((ref, mainDomain) {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection("domains")
        .doc(mainDomain)
        .collection("internships")
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JobListing.fromJson(doc.data()))
              .toList();
        });
  });
