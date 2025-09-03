import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class DomainSeeder {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final AiChatSystem aiChatSystem = AiChatSystem();

  /// ===========================
  /// Batch seed multiple domains dynamically
  /// ===========================
  Future<void> seedDomains(String domainName) async {
    await _seedSingleDomain(domainName);

    print("✅ Finished seeding all domains.");
  }

  /// Seed a single domain
  Future<void> _seedSingleDomain(String domainName) async {
    try {
      await _ensureDomainDoc(domainName);

      final prompt = _buildDomainPrompt(domainName);
      final aiContent = await aiChatSystem.fetchDomainContent(prompt);

      Map<String, dynamic> domainDetails = {};

      if (aiContent != null && aiContent.isNotEmpty) {
        domainDetails = _parseAIResponse(aiContent);
      }

      // Use fallback if AI fails
      if (domainDetails.isEmpty) {
        print("⚠️ AI response invalid for '$domainName'. Using fallback.");
        domainDetails = _fallbackDomainData(domainName);
      }

      // Save to Firestore
      final domainRef = firestore.collection("domains").doc(domainName);
      await domainRef.set({
        "name": domainName,
        "domainImgUrl": domainDetails["domainImgUrl"] ?? "",
        "intro": domainDetails["intro"] ?? "",
        "domainDetails": domainDetails,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ Seeded domain: $domainName");
    } catch (e) {
      print("❌ Error seeding '$domainName': $e");
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

  /// Strict AI prompt for structured JSON
  String _buildDomainPrompt(String domainName) {
    return """
Generate a JSON object for the domain '$domainName'. 
**Return valid JSON ONLY**, no extra text or explanations.
The JSON must include:
- intro (brief 10-15 line description)
- branches (list with name, focus, technologies, goals)
- expectedSalary (range by role)
- types (different types of domain work)
- futureScope
- marketRate
- usefulness
- roadmap (step-by-step learning path)
- domainImgUrl (optional)
""";
  }

  /// Parse AI response safely
  Map<String, dynamic> _parseAIResponse(String aiText) {
    try {
      return jsonDecode(aiText);
    } catch (_) {
      // Extract JSON substring if AI added extra text
      final jsonStart = aiText.indexOf('{');
      final jsonEnd = aiText.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        final jsonString = aiText.substring(jsonStart, jsonEnd + 1);
        try {
          return jsonDecode(jsonString);
        } catch (_) {}
      }
    }
    return {};
  }

  /// Fallback domain data if AI fails
  Map<String, dynamic> _fallbackDomainData(String domainName) {
    return {
      "intro": "Learn about $domainName in detail.",
      "branches": [],
      "expectedSalary": {},
      "types": [],
      "futureScope": "",
      "marketRate": "",
      "usefulness": "",
      "roadmap": [],
      "domainImgUrl": "",
    };
  }
}

/// ================================
/// AI Chat System for Domain Content
/// ================================
class AiChatSystem {
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
