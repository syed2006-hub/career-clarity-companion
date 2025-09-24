import 'dart:convert';
import 'package:careerclaritycompanion/data/models/company_model.dart';
import 'package:careerclaritycompanion/data/models/course_model.dart';
import 'package:careerclaritycompanion/data/models/internship_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

class SeederService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Ensures parent domain doc exists
  Future<void> _ensureDomainExists(String mainDomain) async {
    final domainRef = firestore.collection("domains").doc(mainDomain);
    await domainRef.set({
      "name": mainDomain,
      "createdAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// ============================
  /// UDEMY COURSES SEEDER
  /// ============================

  Future<void> seedUdemyCoursesFromAssets({
    required String mainDomain,
    required int startIndex,
    required int endIndex,
  }) async {
    try {
      await _ensureDomainExists(mainDomain);

      for (int i = startIndex; i <= endIndex; i++) {
        final path = 'assets/clean/courses ($i).json';
        final jsonString = await rootBundle.loadString(path);
        final data = jsonDecode(jsonString);

        // Since your JSON is a list directly
        final List<dynamic> results = data is List ? data : [];

        for (var json in results) {
          final course = CourseModel.fromUdemyJson(json);
          final courseId = course.title.replaceAll(RegExp(r'[./#]'), '-');

          final docRef = firestore
              .collection("domains")
              .doc(mainDomain)
              .collection("courses")
              .doc(courseId);

          await docRef.set(course.toMap());
        }

        print("✅ Seeded ${results.length} courses from '$path'");
      }

      print(
        "🎉 All courses from $startIndex to $endIndex seeded for '$mainDomain'",
      );
    } catch (e) {
      print("❌ [UdemySeeder] Error: $e");
    }
  }

  /// ============================
  /// INTERNSHIPS SEEDER
  /// ============================
  Future<void> seedInternships({
    required String mainDomain,
    required String searchTerm,
  }) async {
    try {
      await _ensureDomainExists(mainDomain);

      final List<JobListing> internships = await _fetchInternships(searchTerm);

      if (internships.isEmpty) {
        print("ℹ️ No internships found for '$searchTerm'");
        return;
      }

      final batch = firestore.batch();

      for (final job in internships) {
        final docId = job.title.replaceAll(RegExp(r'[./#]'), '-');

        // Internship
        final internRef = firestore
            .collection("domains")
            .doc(mainDomain)
            .collection("internships")
            .doc(docId);

        batch.set(internRef, job.toJson());

        // Company
        final company = CompanyInfo(
          name: job.companyName,
          logoUrl: job.companyLogoUrl,
          rating: job.rating,
          reviews: job.reviews,
        );

        final companyRef = firestore
            .collection("companies")
            .doc(company.name.replaceAll(RegExp(r'[./#]'), '-'));

        batch.set(companyRef, company.toJson(), SetOptions(merge: true));
      }

      await batch.commit();
      print(
        "✅ Seeded ${internships.length} internships for '$mainDomain' (and companies)",
      );
    } catch (e) {
      print("❌ [InternshipSeeder] Error: $e");
    }
  }

  /// ============================
  /// HELPER: Fetch internships
  /// ============================
  Future<List<JobListing>> _fetchInternships(String domain) async {
    final apiKey = dotenv.env['INTERN_API_KEY']!;
    const apiHost = 'naukri-jobs-api.p.rapidapi.com';
    final apiUrl = Uri.parse(
      'https://naukri-jobs-api.p.rapidapi.com/api/v1/get-job-listings',
    );

    final headers = {
      'Content-Type': 'application/json',
      'X-Rapidapi-Key': apiKey,
      'X-Rapidapi-Host': apiHost,
    };

    final body = json.encode({
      "search": "$domain Intern",
      "city": "Chennai",
      "experience": 0,
      "page": 1,
    });

    final response = await http.post(apiUrl, headers: headers, body: body);

    if (response.statusCode == 200) {
      final apiResponse = apiResponseFromJson(response.body);
      return apiResponse.status ? apiResponse.jobListings : [];
    } else {
      throw Exception('Failed to load internships: ${response.statusCode}');
    }
  }
}
