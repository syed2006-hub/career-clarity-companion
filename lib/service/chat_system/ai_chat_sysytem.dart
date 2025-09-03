import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiChatSysytem {
  Future<String?> fetchCollegeFromDomain(String emailDomain) async {
    final apiKey = dotenv.env['GEMINI_API_KEY']; // 🔑 pulled from .env
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("Gemini API key not found in .env");
    }
 
    final model = GenerativeModel(model: "gemini-2.0-flash", apiKey: apiKey);

    final prompt =
        "example email domain=aalimec.ac.in"
        "Given an email domain '$emailDomain', return only the full official college or university name it belongs to. dont say anything rather thatn this  "
        "If unknown, return 'Unknown'.";

    final response = await model.generateContent([Content.text(prompt)]);
    print(response.text?.trim());
    return response.text?.trim();
  }
}
