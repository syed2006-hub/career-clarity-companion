import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardFilter {
  final String collegeId;
  final String fieldOfStudy;
  final String year; // year filter
  final String domain; // 👈 new domain filter
  final int selectedTabIndex; // 0=College, 1=Department

  LeaderboardFilter({
    required this.collegeId,
    required this.fieldOfStudy,
    required this.year,
    this.domain = 'All Domains', // default value
    required this.selectedTabIndex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardFilter &&
          runtimeType == other.runtimeType &&
          collegeId == other.collegeId &&
          fieldOfStudy == other.fieldOfStudy &&
          year == other.year &&
          domain == other.domain && // 👈 compare domain
          selectedTabIndex == other.selectedTabIndex;

  @override
  int get hashCode =>
      collegeId.hashCode ^
      fieldOfStudy.hashCode ^
      year.hashCode ^
      domain.hashCode ^ // 👈 include domain
      selectedTabIndex.hashCode;
}

final leaderboardProvider = StreamProvider.family<
    List<LeaderboardEntry>,
    LeaderboardFilter>((ref, filter) {
  if (filter.collegeId.isEmpty) return Stream.value([]);

  final leaderboardRef = FirebaseFirestore.instance
      .collection("colleges")
      .doc(filter.collegeId)
      .collection("leaderboard");

  final controller = StreamController<List<LeaderboardEntry>>();

  Future<void> fetchLeaderboard() async {
    List<LeaderboardEntry> allStudents = [];

    List<String> departmentsToFetch = [];
    if (filter.selectedTabIndex == 0) {
      // College-wide: fetch all departments
      final snapshot = await leaderboardRef.get();
      departmentsToFetch.addAll(snapshot.docs.map((d) => d.id));
    } else {
      // Department-specific
      departmentsToFetch.add(filter.fieldOfStudy);
    }

    for (var deptId in departmentsToFetch) {
      Query studentsQuery = leaderboardRef.doc(deptId).collection("students");

      // Filter by year
      if (filter.year != 'All Years') {
        studentsQuery = studentsQuery.where(
          'yearOfStudy',
          isEqualTo: filter.year,
        );
      }

      // Filter by domain
      if (filter.domain != 'All Domains') {
        studentsQuery = studentsQuery.where(
          'maindomain', // make sure this matches your Firestore field
          isEqualTo: filter.domain,
        );
      }

      final snap = await studentsQuery.get();

      allStudents.addAll(
        snap.docs
            .map(
              (d) => LeaderboardEntry.fromMap(
                d.id,
                d.data() as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
    }

    // Sort by points descending
    allStudents.sort((a, b) => b.points.compareTo(a.points));

    controller.add(allStudents);
  }

  // Initial fetch
  fetchLeaderboard();

  // Listen to department changes
  final listener = leaderboardRef.snapshots().listen((_) => fetchLeaderboard());

  ref.onDispose(() {
    listener.cancel();
    controller.close();
  });

  return controller.stream;
});


final userDetailsProvider = FutureProvider<Map<String, String>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("User not logged in.");
  }

  final userDetailsDoc =
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("personaldetails")
          .doc("details")
          .get();

  if (!userDetailsDoc.exists || userDetailsDoc.data() == null) {
    throw Exception("User details not found. Please complete onboarding.");
  }

  final data = userDetailsDoc.data()!;
  print(
    "Fetched user details: collegeId=${data['collegeId']}, fieldOfStudy=${data['fieldOfStudy']}",
  );
  return {
    'collegeId': data['collegeId'] as String? ?? '',
    'fieldOfStudy': data['fieldOfStudy'] as String? ?? '',
  };
});

class LeaderboardEntry {
  final String id;
  final String name;
  final String university;
  final String degree;
  final String fieldOfStudy;
  final int points;
  final String photoUrl;

  LeaderboardEntry({
    required this.id,
    required this.name,
    required this.university,
    required this.degree,
    required this.fieldOfStudy,
    required this.points,
    required this.photoUrl,
  });

  factory LeaderboardEntry.fromMap(String id, Map<String, dynamic> data) {
    return LeaderboardEntry(
      id: id,
      name: data['name'] ?? 'No Name',
      university: data['university'] ?? '',
      degree: data['degree'] ?? '',
      fieldOfStudy: data['fieldOfStudy'] ?? '',
      points: (data['points'] as int?) ?? 0,
      photoUrl: data['photoUrl'] as String? ?? '',
    );
  }
}
