import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

Future<List<String>> generateMilestones({
  required String mainDomain,
  required String subDomain,
  required List<String> skills,
}) async {
  final model = GenerativeModel(
    model: 'gemini-1.5-flash', // or whichever Gemini version you’re using
    apiKey: 'AIzaSyAllpEr4MOwc4onaHo0IiZhHkjbg3-1-kA',
  );

  final prompt = '''
  The student has chosen:
  - Main Domain: $mainDomain
  - Preferred Subdomain: $subDomain
  - Current Skills: ${skills.join(", ")}

  Based on this, generate exactly 5 progressive career milestones.
  Each milestone should be short, actionable, and related to their chosen domain.
  Return only as a JSON list of strings.
  ''';

  final response = await model.generateContent([Content.text(prompt)]);
  final text = response.text ?? "[]";

  // Parse milestones (basic fallback parser)
  final milestones = RegExp(r'"(.*?)"')
      .allMatches(text)
      .map((m) => m.group(1)!)
      .toList();

  return milestones.isNotEmpty ? milestones : ["Step 1", "Step 2", "Step 3", "Step 4", "Step 5"];
}


Future<void> saveMilestones(String uid, List<String> milestones) async {
  final milestoneRef = FirebaseFirestore.instance
      .collection("users")
      .doc(uid)
      .collection("milestones");

  for (int i = 0; i < milestones.length; i++) {
    await milestoneRef.doc("milestone_${i + 1}").set({
      "title": milestones[i],
      "isCompleted": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
}
