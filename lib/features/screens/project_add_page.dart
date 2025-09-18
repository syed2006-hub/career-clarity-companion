import 'dart:io';
import 'package:careerclaritycompanion/features/custom_widgets/fllutter_toast.dart';
import 'package:careerclaritycompanion/service/clodinary_service/vedio_upload_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 

class AddProjectPage extends StatefulWidget {
  const AddProjectPage({super.key});

  @override
  State<AddProjectPage> createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _githubController = TextEditingController();
  File? _videoFile;
  bool _isUploading = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
 

  /// Pick video from gallery
  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _videoFile = File(picked.path);
      });
    }
  }

 
  /// Upload project data
  Future<void> _uploadProject() async {
    if (_descriptionController.text.isEmpty ||
        _githubController.text.isEmpty ||
        _videoFile == null) {
      showBottomToast("Please fill all fields and select a video");
      return;
    }

    try {
      setState(() => _isUploading = true);
      final user = _auth.currentUser;
      if (user == null) return;

      // 1. Upload video to Cloudinary
      final videoUrl = await uploadVideoToCloudinary(_videoFile!);
      if (videoUrl == null) {
        showBottomToast("Failed to upload video");
        return;
      }

      // 2. Save project in Firestore
      await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("projects")
          .add({
        "description": _descriptionController.text,
        "githubLink": _githubController.text,
        "videoUrl": videoUrl, // ✅ Cloudinary URL
        "timestamp": FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      showBottomToast("Project added!");
    } catch (e) {
      showBottomToast("Error: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Project")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: "Project description...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _githubController,
              decoration: const InputDecoration(
                hintText: "GitHub link",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Video Picker Preview
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black12,
                ),
                child: Center(
                  child: _videoFile == null
                      ? const Text("Tap to select a video")
                      : const Icon(Icons.play_circle_fill,
                          size: 50, color: Colors.teal),
                ),
              ),
            ),
            const Spacer(),

            // Upload button
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadProject,
              icon: const Icon(Icons.cloud_upload),
              label: Text(_isUploading ? "Uploading..." : "Upload"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
