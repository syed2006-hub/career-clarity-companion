import 'dart:io';

import 'package:careerclaritycompanion/features/custom_widgets/fllutter_toast.dart';
import 'package:careerclaritycompanion/service/clodinary_service/resume_upload_service.dart';
import 'package:careerclaritycompanion/service/provider/domain_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class EditUserPage extends StatefulWidget {
  const EditUserPage({super.key});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Controllers
  final _skillsController = TextEditingController();
  final _subDomainController = TextEditingController();
  final _resumeFileNameController = TextEditingController();

  String? _photoUrl; // Stores the initial URL from Firestore
  PlatformFile? _resumeFile;
  File? _pickedImage; // MODIFIED: Stores the new image file if user picks one

  bool _isSaving = false;

  Map<String, dynamic>? _userDetails;
  String? _collegeId;

  // Dropdown state
  String? _selectedDegree;
  String? _selectedField;
  String? _selectedYear;
  String? _selectedMainDomain;

  final List<String> _degreeOptions = [
    'Bachelor of Technology (B.Tech)',
    'Bachelor of Engineering (B.E.)',
    'Master of Technology (M.Tech)',
    'Master of Engineering (M.E.)',
    'Diploma in Engineering',
    'Ph.D. in Engineering',
  ];

  final List<String> _fieldOptions = [
    'Computer Science and Engineering',
    'Information Technology',
    'Artificial Intelligence and Data Science',
    'Electronics and Communication Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Electrical and Electronics Engineering',
    'Chemical Engineering',
    'Aerospace Engineering',
    'Biotechnology Engineering',
    'Automobile Engineering',
    'Robotics and Automation',
    'Cyber Security',
  ];

  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  final List<String> _skillsList = [];

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  // MODIFIED: This function now only picks an image and does not upload it.
  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // compress for faster upload
      );
      if (pickedFile == null) return;

      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    } catch (e) {
      showBottomToast("Error picking image!");
    }
  }

  Future<void> _fetchUserDetails() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('personaldetails')
            .doc('details')
            .get();

    if (!userDoc.exists) return;

    _userDetails = userDoc.data();
    // Set initial values from Firestore
    _photoUrl = _userDetails?['photoUrl'];
    _skillsList.addAll(
      (_userDetails?['skills'] as List?)?.cast<String>() ?? [],
    );
    _selectedDegree = _userDetails?['degree'];
    _selectedField = _userDetails?['fieldOfStudy'];
    _selectedYear = _userDetails?['yearOfStudy'];
    _selectedMainDomain = _userDetails?['maindomain'];
    _subDomainController.text = _userDetails?['subdomain'] ?? '';
    _resumeFileNameController.text = _userDetails?['resumeFileName'] ?? '';
    _collegeId = _userDetails?['collegeId'];

    setState(() {});
  }

  Future<void> _pickResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _resumeFile = result.files.single;
        _resumeFileNameController.text = _resumeFile!.name;
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skillsList.remove(skill);
    });
  }

  // MODIFIED: All upload and save logic is now handled here.
  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (_collegeId == null) return;

    setState(() => _isSaving = true);

    try {
      String? finalPhotoUrl = _photoUrl; // Start with the existing URL.

      // ADDED: Check if a new image was picked. If so, upload it.
      if (_pickedImage != null) {
        final platformFile = PlatformFile(
          name: _pickedImage!.path.split('/').last,
          path: _pickedImage!.path,
          size: await _pickedImage!.length(),
        );

        final imageUrl = await uploadFileToCloudinary(platformFile);

        if (imageUrl != null) {
          finalPhotoUrl = imageUrl; // Update the URL to the new one.
          await user.updatePhotoURL(
            finalPhotoUrl,
          ); // Update Firebase Auth profile
          await user.reload();
        } else {
          showBottomToast(
            "Failed to upload new profile image. Please try again.",
          );
          setState(() => _isSaving = false);
          return; // Abort saving if image upload fails
        }
      }

      String? resumeUrl;
      if (_resumeFile != null) {
        resumeUrl = await uploadFileToCloudinary(_resumeFile!);
      }

      final userData = {
        'photoUrl': finalPhotoUrl, // Use the final URL (either old or new)
        'degree': _selectedDegree,
        'fieldOfStudy': _selectedField,
        'yearOfStudy': _selectedYear,
        'skills': _skillsList,
        'maindomain': _selectedMainDomain,
        'subdomain': _subDomainController.text.trim(),
        if (_resumeFileNameController.text.isNotEmpty)
          'resumeFileName': _resumeFileNameController.text.trim(),
        if (resumeUrl != null) 'resumeUrl': resumeUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update user personal details in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('personaldetails')
          .doc('details')
          .set(userData, SetOptions(merge: true));

      // Update leaderboard entry in Firestore
      final leaderboardRef = _firestore
          .collection('colleges')
          .doc(_collegeId)
          .collection('leaderboard')
          .doc(_selectedField)
          .collection('students')
          .doc(user.uid);

      await leaderboardRef.set(userData, SetOptions(merge: true));

      showBottomToast("Profile updated successfully!");
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      showBottomToast("Error saving profile: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userDetails == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child:
                _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    )
                    : const Text(
                      "SAVE",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[800],
                  // MODIFIED: Logic to show picked image preview or existing network image
                  backgroundImage:
                      _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider
                          : (_photoUrl != null && _photoUrl!.isNotEmpty
                              ? NetworkImage(_photoUrl!)
                              : null),
                  child:
                      _photoUrl == null && _pickedImage == null
                          ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          )
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap:
                        _pickProfileImage, // MODIFIED: Calls the picker-only function
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.tealAccent,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Full Name & College Cards
            _buildReadOnlyField(
              "Full Name",
              user?.displayName ?? "",
              Icons.person,
            ),
            _buildReadOnlyField(
              "College/University",
              _userDetails?['university'] ?? '',
              Icons.school,
            ),
            const SizedBox(height: 16),

            // Degree Dropdown Card
            _buildDropdownCard(
              label: "Degree",
              value: _selectedDegree,
              items: _degreeOptions,
              icon: Icons.book,
              onChanged: (val) => setState(() => _selectedDegree = val),
            ),
            const SizedBox(height: 12),

            // Field of Study Dropdown Card
            _buildDropdownCard(
              label: "Field of Study",
              value: _selectedField,
              items: _fieldOptions,
              icon: Icons.science,
              onChanged: (val) => setState(() => _selectedField = val),
            ),
            const SizedBox(height: 12),

            // Year Dropdown Card
            _buildDropdownCard(
              label: "Year of Study",
              value: _selectedYear,
              items: _years,
              icon: Icons.calendar_today,
              onChanged: (val) => setState(() => _selectedYear = val),
            ),
            const SizedBox(height: 12),

            // Main Domain Dropdown Card
            Consumer(
              builder: (context, ref, _) {
                final asyncDomains = ref.watch(domainNamesProvider);
                return asyncDomains.when(
                  data: (domains) {
                    final domainNames = domains.map((d) => d.name).toList();
                    return _buildDropdownCard(
                      label: "Main Domain",
                      value: _selectedMainDomain,
                      items: domainNames,
                      icon: Icons.business_center,
                      onChanged:
                          (val) => setState(() => _selectedMainDomain = val),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text("Error loading domains: $e"),
                );
              },
            ),
            const SizedBox(height: 12),

            // Sub Domain TextField Card
            _buildTextFieldCard(
              controller: _subDomainController,
              label: "Preferred Domain (e.g., AI/ML)",
              icon: Icons.track_changes,
            ),
            const SizedBox(height: 16),

            // Skills Input
            _buildSkillsInput(),
            const SizedBox(height: 16),

            // Resume Upload Card
            ListTile(
              leading: const Icon(Icons.description, color: Colors.tealAccent),
              title: Text(
                _resumeFileNameController.text.isEmpty
                    ? "Upload Resume"
                    : _resumeFileNameController.text,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.upload_file, color: Colors.tealAccent),
                onPressed: _pickResume,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // No changes to helper widgets below this line
  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Card(
      color: const Color(0xFF42382D),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.tealAccent),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildDropdownCard({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          value: value,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white),
            prefixIcon: Icon(icon, color: Colors.tealAccent),
            border: InputBorder.none,
          ),
          items:
              items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
          onChanged: onChanged,
          dropdownColor: Theme.of(context).colorScheme.secondary,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTextFieldCard({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white),
            prefixIcon: Icon(icon, color: Colors.tealAccent),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSkillsInput() {
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _skillsController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Add a skill",
                labelStyle: TextStyle(color: Colors.white),
                prefixIcon: const Icon(
                  Icons.lightbulb,
                  color: Colors.tealAccent,
                ),
                border: InputBorder.none,
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty &&
                    !_skillsList.contains(val.trim())) {
                  setState(() {
                    _skillsList.add(val.trim());
                    _skillsController.clear();
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  _skillsList
                      .map(
                        (skill) => Chip(
                          label: Text(skill),
                          onDeleted: () => _removeSkill(skill),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
