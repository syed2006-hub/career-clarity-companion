import 'dart:io';

import 'package:careerclaritycompanion/features/custom_widgets/fllutter_toast.dart';
import 'package:careerclaritycompanion/service/clodinary_service/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddAchievementPage extends StatefulWidget {
  const AddAchievementPage({super.key});

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

  Future<void> _pickCertificate() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _certificateFile = File(picked.path));
    }
  }

  Future<void> _uploadAchievement() async {
    if (_certificateFile == null || _descriptionController.text.isEmpty) {
      showBottomToast("Please add a certificate & description");
      return;
    }

    try {
      setState(() => _isUploading = true);
      final user = _auth.currentUser;
      if (user == null) return;

      final imageUrl = await _cloudinary.uploadImage(_certificateFile!);

      await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("achievements")
          .add({
            "certificateUrl": imageUrl,
            "description": _descriptionController.text,
            "timestamp": FieldValue.serverTimestamp(),
          });

      Navigator.pop(context);
      showBottomToast("Achievement added!");
    } finally {
      setState(() => _isUploading = false);
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
                          fit: BoxFit.cover,
                        ),
                      )
                      : Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.upload_file,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                      ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: "Add a description...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadAchievement,
              icon: const Icon(Icons.cloud_upload),
              label: const Text("Upload"),
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
