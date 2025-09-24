import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class DomainSeeder {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final AiChatSystem aiChatSystem = AiChatSystem();

  /// ===========================
  /// Seed domain with AI projects and internships
  /// ===========================
  Future<void> seedDomainProjects(String domainName) async {
    try {
      // Ensure domain document exists
      await _ensureDomainDoc(domainName);


      // Generate AI projects
      final projects = await aiChatSystem.generateAIProjects(domainName);

      // Save projects under domain -> projects
      final projectsRef = firestore
          .collection('domains')
          .doc(domainName)
          .collection('projects');

      for (final project in projects) {
        await projectsRef.add({
          "themeTitle": project['themeTitle'],
          "problemStatement": project['problemStatement'],
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      print("✅ Seeded ${projects.length} projects for '$domainName'");
    } catch (e) {
      print("❌ Error seeding projects: $e");
    }
  }

  /// Ensure domain document exists
  Future<void> _ensureDomainDoc(String domainName) async {
    final domainRef = firestore.collection("domains").doc(domainName);
    await domainRef.set({
      "name": domainName,
      "createdAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Fetch internships for a domain
  Future<List<Map<String, String>>> _fetchInternships(String domainName) async {
    final snapshot =
        await firestore
            .collection('internships')
            .where('domain', isEqualTo: domainName)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'title': data['title']?.toString() ?? 'Untitled',
        'company': data['company']?.toString() ?? '',
        'link': data['link']?.toString() ?? '',
      };
    }).toList();
  }
}

/// ================================
/// Gemini AI Chat System for Projects
/// ================================
class AiChatSystem {
  /// Generate 4 project themes for a domain
  Future<List<Map<String, String>>> generateAIProjects(String domain) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("Gemini API key not found in .env");
    }

    final prompt = """
Generate 4 innovative project themes for the domain "$domain".
Return the result as a JSON array where each object has:
- themeTitle
- problemStatement
Return only JSON, no extra text.
""";

    final model = GenerativeModel(model: "gemini-2.0-flash", apiKey: apiKey);
    final response = await model.generateContent([Content.text(prompt)]);
    String rawText = response.text ?? "[]";

    // Strip any Markdown-style JSON fences (```json ... ```)
    rawText = rawText.trim();
    if (rawText.startsWith("```")) {
      final firstNewline = rawText.indexOf('\n');
      final lastFence = rawText.lastIndexOf("```");
      if (firstNewline != -1 && lastFence != -1 && lastFence > firstNewline) {
        rawText = rawText.substring(firstNewline + 1, lastFence).trim();
      }
    }

    try {
      final List<dynamic> listDynamic = json.decode(rawText);
      return listDynamic.map<Map<String, String>>((p) {
        final map = p as Map<String, dynamic>;
        return {
          'themeTitle': map['themeTitle']?.toString() ?? 'Untitled Theme',
          'problemStatement': map['problemStatement']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      throw Exception(
        "Failed to parse AI projects JSON: $e\nRaw text:\n$rawText",
      );
    }
  }

  /// Optional: fetch domain content (existing method)
  Future<String?> fetchDomainContent(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("Gemini API key not found in .env");
    }

    final model = GenerativeModel(model: "gemini-2.0-flash", apiKey: apiKey);
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text?.trim();
  }
}
