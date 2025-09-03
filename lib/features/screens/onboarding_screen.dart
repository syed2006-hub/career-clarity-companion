import 'package:careerclaritycompanion/features/custom_widgets/confirmation_dialog.dart';
import 'package:careerclaritycompanion/features/custom_widgets/fllutter_toast.dart';
import 'package:careerclaritycompanion/service/clodinary_service/resume_upload_service.dart';
import 'package:careerclaritycompanion/service/provider/domain_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  // Personal Details
  final _locationController = TextEditingController();

  // Professional Details
  final _skillsController = TextEditingController();
  final List<String> _skillsList = [];

  // Education Details
  final _universityController = TextEditingController();
  final _degreeController = TextEditingController();
  final _fieldOfStudyController = TextEditingController();
  final _yearOfStudy = TextEditingController();

  // Goals
  final _subdomainController = TextEditingController();
  final _mainDomainController = TextEditingController();

  // General State
  bool _isLoading = false;
  String? _resumeFileName;
  String? _resumeUrl;
  String collegeId = '';

  // --- Data for Searchable Dropdowns ---
  final List<String> _engineeringDegrees = [
    'Bachelor of Technology (B.Tech)',
    'Bachelor of Engineering (B.E.)',
    'Master of Technology (M.Tech)',
    'Master of Engineering (M.E.)',
    'Diploma in Engineering',
    'Doctor of Philosophy (Ph.D.) in Engineering',
  ];

  final List<String> _engineeringFields = [
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

  Future<void> _fetchCurrentLocation() async {
    // ... (Your existing _fetchCurrentLocation method - no changes needed)
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final address =
            '${place.subLocality}, ${place.locality}, ${place.administrativeArea}';
        setState(() {
          _locationController.text = address;
        });
      }
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  Future<void> _loadCollegeName() async {
    // ... (Your existing _loadCollegeName method - no changes needed)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final email = user.email ?? "";
    final emailDomain = email.split("@").last;
    final collegeQuery =
        await FirebaseFirestore.instance
            .collection("colleges")
            .where("domain", isEqualTo: emailDomain)
            .limit(1)
            .get();
    if (collegeQuery.docs.isNotEmpty) {
      final collegeDoc = collegeQuery.docs.first;
      final collegeName = collegeDoc.data()['name'] as String;
      collegeId = collegeDoc.data()['collegeId'] as String;
      setState(() {
        _universityController.text = collegeName;
      });
    }
  }

  Future<PlatformFile?> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      return result.files.single;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadCollegeName();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _locationController.dispose();
    _skillsController.dispose();
    _universityController.dispose();
    _degreeController.dispose();
    _fieldOfStudyController.dispose();
    _subdomainController.dispose();
    _mainDomainController.dispose();
    super.dispose();
  }

  // ✨ VALIDATION LOGIC
  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 1: // Education Page
        if (_degreeController.text.trim().isEmpty) {
          showBottomToast("Please select your degree.");
          return false;
        }
        if (_fieldOfStudyController.text.trim().isEmpty) {
          showBottomToast("Please select your field of study.");
          return false;
        }
        break;
      case 2: // Goals Page
        if (_subdomainController.text.trim().isEmpty) {
          showBottomToast("Please enter your preferred domain.");
          return false;
        }
        break;
    }
    return true; // Page is valid
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    // ✨ Final validation before submitting
    if (!_validateCurrentPage()) {
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final email = user.email ?? "";
        final emailDomain = email.split("@").last;
        final collegeQuery =
            await FirebaseFirestore.instance
                .collection("colleges")
                .where("domain", isEqualTo: emailDomain)
                .limit(1)
                .get();

        if (collegeQuery.docs.isEmpty) {
          showBottomToast(
            "Your college/university is not registered.",
            bg: Colors.red,
          );
          setState(() => _isLoading = false);
          return;
        }

        // ✨ User data for personal details
        final userData = {
          "displayName": user.displayName ?? "",
          "location": _locationController.text.trim(),
          "skills": _skillsList,
          "university": _universityController.text.trim(),
          "collegeId": collegeId,
          "degree": _degreeController.text.trim(),
          'yearOfStudy': _yearOfStudy.text.trim(),
          "fieldOfStudy": _fieldOfStudyController.text.trim(),
          "maindomain": _mainDomainController.text.trim(),
          "subdomain": _subdomainController.text.trim(),
          "resumeFileName": _resumeFileName,
          "resumeUrl": _resumeUrl,
          "completedOnboarding": true,
          "updatedAt": FieldValue.serverTimestamp(),
        };

        // Save personal details under user
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("personaldetails")
            .doc("details")
            .set(userData, SetOptions(merge: true));

        // Save minimal fieldOfStudy at root level
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "fieldOfStudy": _fieldOfStudyController.text.trim(),
          "collegeId": collegeId,
        }, SetOptions(merge: true));

        // 🚀 Add to leaderboard
        final leaderboardData = {
          "name": user.displayName ?? "",
          "university": _universityController.text.trim(),
          "degree": _degreeController.text.trim(),
          "fieldOfStudy": _fieldOfStudyController.text.trim(),
          "points": 100, // reward for completing onboarding
          "photoUrl": user.photoURL ?? "", // if available, else ""
          'yearOfStudy': _yearOfStudy.text.trim(),
          "maindomain": _mainDomainController.text.trim(),
          "subdomain": _subdomainController.text.trim(),
          "createdAt": FieldValue.serverTimestamp(),
        };

        // ✅ get college docId from earlier query
        final collegeDocId = collegeQuery.docs.first.id;

        // ✅ use field of study as subcollection
        final fieldOfStudy = _fieldOfStudyController.text.trim();

        final leaderboardRef = FirebaseFirestore.instance
            .collection("colleges")
            .doc(collegeDocId)
            .collection("leaderboard")
            .doc(fieldOfStudy);

        // Ensure the document exists
        await leaderboardRef.set({
          "createdAt":
              FieldValue.serverTimestamp(), // optional, just to make it non-empty
        }, SetOptions(merge: true));

        // Then add the student
        await leaderboardRef
            .collection("students")
            .doc(user.uid)
            .set(leaderboardData, SetOptions(merge: true));

        // ✅ Success
        showBottomToast("Onboarding completed successfully!", bg: Colors.green);

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, "/home");
      } catch (e) {
        showBottomToast("Error: $e", bg: Colors.red);
      }
    }

    setState(() => _isLoading = false);
  }

  void _removeSkill(String skill) {
    setState(() {
      _skillsList.remove(skill);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Step ${_currentPage + 1} of $_totalPages",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: Theme.of(context).colorScheme.primary,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (page) => setState(() => _currentPage = page),
        children: [
          _buildPersonalDetailsPage(),
          _buildEducationDetailsPage(),
          _buildGoalsPage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildPageWrapper({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsPage() {
    final user = FirebaseAuth.instance.currentUser;
    final List<String> allowedSkills = [
      "Flutter",
      "Dart",
      "Firebase",
      "JavaScript",
      "React",
      "Node.js",
      "Python",
      "Machine Learning",
      "UI/UX Design",
      "SQL",
      "Java",
      "C++",
    ];
    final List<String> popularSkills = [
      "Flutter",
      "Firebase",
      "Python",
      "React",
    ];

    return _buildPageWrapper(
      title: "Welcome!",
      subtitle: "Let's start with the basics.",
      children: [
        _buildTextField(
          TextEditingController(text: user?.displayName ?? ""),
          "Full Name",
          Icons.person_outline,
          isOptional: false,
          enabled: false,
        ),

        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _locationController,
                "Location",
                Icons.location_on_outlined,
                isOptional: true,
              ),
            ),

            IconButton(
              icon: const Icon(Icons.my_location_outlined),
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => const ConfirmationDialog(
                        title: 'Fetch Current Location?',
                        content:
                            'Do you want to automatically fetch your current location?',
                        confirmText: 'Fetch',
                        cancelText: 'cancel',
                        icon: Icons.pin_drop,
                      ),
                );
                if (result == true) {
                  await _fetchCurrentLocation();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return allowedSkills.where(
              (skill) => skill.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ),
            );
          },
          onSelected: (String selectedSkill) {
            if (!_skillsList.contains(selectedSkill)) {
              setState(() => _skillsList.add(selectedSkill));
            }
            _skillsController.clear();
          },
          fieldViewBuilder: (
            context,
            textEditingController,
            focusNode,
            onFieldSubmitted,
          ) {
            // Bind the external controller
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (textEditingController.text != _skillsController.text) {
                textEditingController.value = _skillsController.value;
              }
            });
            return TextField(
              controller: _skillsController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: "Add a skill (Optional)",
                labelStyle: TextStyle(color: Colors.black),

                prefixIcon: const Icon(Icons.lightbulb_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 2,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children:
              _skillsList
                  .map(
                    (skill) => Chip(
                      label: Text(skill),
                      onDeleted: () => _removeSkill(skill),
                      deleteIconColor: Colors.red.shade400,
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 20),
        if (popularSkills.isNotEmpty) ...[
          Text(
            "Popular Skills",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children:
                popularSkills
                    .map(
                      (skill) => ActionChip(
                        label: Text(skill),
                        onPressed: () {
                          if (!_skillsList.contains(skill)) {
                            setState(() => _skillsList.add(skill));
                          }
                        },
                      ),
                    )
                    .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildEducationDetailsPage() {
    return _buildPageWrapper(
      title: "Education",
      subtitle: "Tell us about your academic background.",
      children: [
        _buildTextField(
          _universityController,
          "University / College",
          Icons.school_outlined,
          enabled: false,
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Degree Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<String>(
                isExpanded: true, // critical
                value:
                    _degreeController.text.isNotEmpty
                        ? _degreeController.text
                        : null,
                decoration: InputDecoration(
                  labelText: "Degree",
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(
                    Icons.book_outlined,
                    color: Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items:
                    _engineeringDegrees
                        .map(
                          (degree) => DropdownMenuItem<String>(
                            value: degree,
                            child: Text(
                              degree,
                              overflow:
                                  TextOverflow
                                      .ellipsis, // prevent overflow text
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (String? selectedDegree) {
                  if (selectedDegree != null) {
                    setState(() {
                      _degreeController.text = selectedDegree;
                    });
                  }
                },
              ),
            ),

            // Field of Study Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<String>(
                isExpanded: true, // critical
                value:
                    _fieldOfStudyController.text.isNotEmpty
                        ? _fieldOfStudyController.text
                        : null,
                decoration: InputDecoration(
                  labelText: "Field of Study",
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(
                    Icons.science_outlined,
                    color: Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items:
                    _engineeringFields
                        .map(
                          (field) => DropdownMenuItem<String>(
                            value: field,
                            child: Text(
                              field,
                              overflow:
                                  TextOverflow
                                      .ellipsis, // prevent overflow text
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (String? selectedField) {
                  if (selectedField != null) {
                    setState(() {
                      _fieldOfStudyController.text = selectedField;
                    });
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<String>(
                isExpanded: true, // critical
                value:
                    _fieldOfStudyController.text.isNotEmpty
                        ? _fieldOfStudyController.text
                        : null,
                decoration: InputDecoration(
                  labelText: "Field of Study",
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(
                    Icons.science_outlined,
                    color: Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items:
                    _years
                        .map(
                          (year) => DropdownMenuItem<String>(
                            value: year,
                            child: Text(
                              year,
                              overflow:
                                  TextOverflow
                                      .ellipsis, // prevent overflow text
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (String? selectedyear) {
                  if (selectedyear != null) {
                    setState(() {
                      _yearOfStudy.text = selectedyear;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalsPage() {
    return _buildPageWrapper(
      title: "Career Goals",
      subtitle: "What are you looking for?",
      children: [
        // 🔹 Main Domain Dropdown
        Consumer(
          builder: (context, ref, _) {
            final asyncDomains = ref.watch(domainNamesProvider);

            return asyncDomains.when(
              data: (domains) {
                final domainNames = domains.map((d) => d.name).toList();

                return DropdownButtonFormField<String>(
                  value:
                      _mainDomainController.text.isNotEmpty
                          ? _mainDomainController.text
                          : null,
                  decoration: InputDecoration(
                    labelText: "Main Domain",
                    labelStyle: TextStyle(color: Colors.black),
                    prefixIcon: Icon(
                      Icons.business_center,
                      color: Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items:
                      domainNames.map((name) {
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _mainDomainController.text = value ?? '';
                    });
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text("Error loading domains: $e"),
            );
          },
        ),

        const SizedBox(height: 20),

        // Existing Preferred Domain TextField
        _buildTextField(
          _subdomainController,
          "Preferred Domain (e.g., 'AI/ML')",
          Icons.track_changes_outlined,
          isOptional: true,
        ),

        const SizedBox(height: 30),

        // Resume Upload Button
        Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              final file = await pickFile();
              if (file != null) {
                final url = await uploadFileToCloudinary(file);
                if (url != null) {
                  setState(() {
                    _resumeFileName = file.name;
                    _resumeUrl = url;
                  });
                  print('File uploaded: $url');
                }
              }
            },
            icon: Icon(
              _resumeFileName != null ? Icons.check_circle : Icons.upload_file,
            ),
            label: Text(_resumeFileName ?? "Upload Resume (Optional)"),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool enabled = true,
    bool isOptional = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    // ✨ Updated to show asterisk for required fields
    final String labelText = isOptional ? label : '$label*';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.black),

          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton.icon(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              label: const Text(
                "Previous",
                style: TextStyle(color: Colors.black),
              ),
            )
          else
            const SizedBox(width: 100), // Placeholder to keep alignment
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  // ✨ VALIDATION ADDED HERE
                  if (_validateCurrentPage()) {
                    if (_currentPage < _totalPages - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _submit();
                    }
                  }
                },
                child: Text(
                  _currentPage < _totalPages - 1 ? "NEXT" : "FINISH",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
