import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:careerclaritycompanion/data/models/course_model.dart';

// Stream provider -> listens to Firestore in real-time
final courseStreamProvider = StreamProvider.family<List<CourseModel>, String>((ref, mainDomain) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection("domains")
      .doc(mainDomain)
      .collection("courses")
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => CourseModel.fromMap(doc.data()))
            .toList();
      });
});
