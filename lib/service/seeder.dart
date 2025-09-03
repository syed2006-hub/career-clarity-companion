import 'dart:convert';
import 'package:careerclaritycompanion/data/models/company_model.dart';
import 'package:careerclaritycompanion/data/models/course_model.dart';
import 'package:careerclaritycompanion/data/models/internship_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class SeederService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Ensures parent domain doc exists
  Future<void> _ensureDomainExists(String mainDomain) async {
    final domainRef = firestore.collection("domains").doc(mainDomain);
    await domainRef.set(
      {
        "name": mainDomain,
        "createdAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// ============================
  /// UDEMY COURSES SEEDER
  /// ============================
  Future<void> seedUdemyCourses({required String mainDomain}) async {
    try {
      await _ensureDomainExists(mainDomain);

      final url =
          "https://udemy-api2.p.rapidapi.com/v1/udemy/category/$mainDomain";
      final apiKey = dotenv.env['UDEMY_API_KEY']!;

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "X-RapidAPI-Key": apiKey,
          "X-RapidAPI-Host": "udemy-api2.p.rapidapi.com",
        },
        body: jsonEncode({
          "page": 1,
          "page_size": 50,
          "sort": "popularity",
          "extract_pricing": true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data["data"]?["courses"] ?? [];

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

        print("✅ Seeded ${results.length} courses under '$mainDomain'");
      } else {
        throw Exception("Failed to load courses: ${response.body}");
      }
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
    final apiUrl =
        Uri.parse('https://naukri-jobs-api.p.rapidapi.com/api/v1/get-job-listings');

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
