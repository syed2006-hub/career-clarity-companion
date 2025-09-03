// Add this provider to fetch departments dynamically
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final departmentsProvider = FutureProvider.family<List<String>, String>((ref, collegeId) async {
  if (collegeId.isEmpty) return ['All Departments'];

  final snapshot = await FirebaseFirestore.instance
      .collection("colleges")
      .doc(collegeId)
      .collection("leaderboard")
      .get();

  final departments = snapshot.docs.map((doc) => doc.id).toList();
  return ['All Departments', ...departments];
});
