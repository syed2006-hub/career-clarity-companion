import 'dart:io';
import 'package:careerclaritycompanion/features/custom_widgets/fllutter_toast.dart';
import 'package:careerclaritycompanion/service/clodinary_service/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

/// ====================
/// Gemini AI Service
/// ====================
class GeminiService {
  final String _apiKey =
      "AIzaSyAllpEr4MOwc4onaHo0IiZhHkjbg3-1-kA"; // ⚠️ Replace with your actual key

  Future<bool> isImageACertificate({
    required File imageFile,
    required String prompt,
  }) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

    try {
      final imageBytes = await imageFile.readAsBytes();

      final promptPart = TextPart(prompt);
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([promptPart, imagePart]),
      ]);

      final textResponse = response.text?.toLowerCase().trim() ?? 'false';
      print('Gemini Response: "$textResponse"');

      return textResponse == 'true';
    } catch (e) {
      print("Error validating image with Gemini: $e");
      showBottomToast(
        "Could not verify the certificate. Please try again.",
        bg: Colors.red,
      );
      return false;
    }
  }
}

/// ====================
/// AddAchievementPage
/// ====================
class AddAchievementPage extends StatefulWidget {
  final String? constructorFlag; // e.g., "intern"

  const AddAchievementPage({super.key, this.constructorFlag});

  @override
  State<AddAchievementPage> createState() => _AddAchievementPageState();
}

class _AddAchievementPageState extends State<AddAchievementPage> {
  File? _certificateFile;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isUploading = false;

  final picker = ImagePicker();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _cloudinary = CloudinaryService();
  final _geminiService = GeminiService();

  /// Pick certificate image from gallery
  Future<void> _pickCertificate() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _certificateFile = File(picked.path));
  }

  /// Upload & verify achievement
  Future<void> _uploadAchievement() async {
    if (_certificateFile == null || _descriptionController.text.isEmpty) {
      showBottomToast("Please add a certificate & description");
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        showBottomToast("User not found. Please log in again.", bg: Colors.red);
        return;
      }

      /// -----------------------------
      /// Build the AI prompt based on flag
      /// -----------------------------
      final String prompt;
      if (widget.constructorFlag == "intern") {
        prompt =
            "Is this image a valid internship certificate? "
            "If it is a course certificate or any other type, answer only 'false'. "
            "Answer only 'true' or 'false'.";
      } else {
        prompt =
            "Is this image a certificate of achievement, completion, or participation? "
            "Answer only 'true' or 'false'.";
      }

      showBottomToast("Verifying document...", bg: Colors.blue);

      final bool isCertificate = await _geminiService.isImageACertificate(
        imageFile: _certificateFile!,
        prompt: prompt,
      );

      if (!isCertificate) {
        showBottomToast(
          widget.constructorFlag == "intern"
              ? "This is not a valid internship certificate."
              : "This does not appear to be a valid certificate.",
          bg: Colors.red,
        );
        return;
      }

      showBottomToast(
        "Verification successful! Uploading...",
        bg: Colors.green,
      );

      final imageUrl = await _cloudinary.uploadImage(_certificateFile!);

      // Add achievement to user's collection
      await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("achievements")
          .add({
            "certificateUrl": imageUrl,
            "description": _descriptionController.text,
            "type":
                widget.constructorFlag == "intern" ? "internship" : "general",
            "timestamp": FieldValue.serverTimestamp(),
          });

      // -----------------------------
      // Add +50 points to leaderboard
      // -----------------------------
      // Fetch the user's collegeId and fieldOfStudy
      final userDoc = await _firestore.collection("users").doc(user.uid).get();
      final collegeId = userDoc.get("collegeId");
      final fieldOfStudy = userDoc.get("fieldOfStudy");

      final leaderboardRef = _firestore
          .collection("colleges")
          .doc(collegeId)
          .collection("leaderboard")
          .doc(fieldOfStudy)
          .collection("students")
          .doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(leaderboardRef);
        final currentPoints =
            snapshot.exists && snapshot.data()!.containsKey("points")
                ? snapshot.get("points") as int
                : 0;
        transaction.set(leaderboardRef, {
          "points": currentPoints + 50,
        }, SetOptions(merge: true));
      });

      if (mounted) Navigator.pop(context);
      showBottomToast(
        "Achievement added! +50 points awarded.",
        bg: Colors.green,
      );
    } catch (e) {
      showBottomToast("An error occurred: ${e.toString()}", bg: Colors.red);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Achievement")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickCertificate,
              child:
                  _certificateFile != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _certificateFile!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                      : Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade200,
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_file,
                                color: Colors.grey,
                                size: 50,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Tap to select a certificate",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: "Add a description (e.g., 'Google Cloud Certified')",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadAchievement,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child:
                  _isUploading
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                      : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload),
                          SizedBox(width: 8),
                          Text("Verify & Upload"),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
