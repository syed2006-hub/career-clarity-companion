import 'dart:math'; // Required for blob animation
import 'dart:ui'; // Required for ImageFilter.blur
import 'package:careerclaritycompanion/features/custom_widgets/confirmation_dialog.dart';
import 'package:careerclaritycompanion/features/custom_widgets/fllutter_toast.dart';
import 'package:careerclaritycompanion/service/provider/domain_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

// A simple data class to hold the properties of a single blob.
class Blob {
  final double initialRadius;
  final double initialX;
  final double initialY;
  final double speed;
  final Color color;
  Offset position;
  double radius;

  Blob({
    required this.initialRadius,
    required this.initialX,
    required this.initialY,
    required this.speed,
    required this.color,
  }) : position = Offset(initialX, initialY),
       radius = initialRadius;

  void move(double animationValue, Size screenSize) {
    // Use sine and cosine to create smooth, circular-style movement
    final double newX =
        initialX + sin(animationValue * speed) * (screenSize.width * 0.2);
    final double newY =
        initialY + cos(animationValue * speed) * (screenSize.height * 0.2);
    position = Offset(newX, newY);

    // Also animate the radius for a "breathing" effect
    radius = initialRadius + sin(animationValue * speed * 0.8) * 15;
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  // Animation controller and blobs for the background
  late AnimationController _animationController;
  late List<Blob> _blobs;

  // Your existing controllers and state variables
  final _locationController = TextEditingController();
  final _skillsController = TextEditingController();
  final List<String> _skillsList = [];
  final _universityController = TextEditingController();
  final _degreeController = TextEditingController();
  final _fieldOfStudyController = TextEditingController();
  final _yearOfStudyController = TextEditingController();
  final _subdomainController = TextEditingController();
  final _mainDomainController = TextEditingController();

  String? _selectedField;
  String? _selectedYear;
  String? _selectedDegree;
  String? _selectedCity;
  String? _selectedMainDomain;

  bool _isLoading = false;
  String? _resumeFileName;
  String? _resumeUrl;
  String collegeId = '';

  // --- Data lists ---
  final List<String> _cities = [
    "Chennai",
    "Bengaluru",
    "Hyderabad",
    "Mumbai",
    "Delhi",
    "Kolkata",
    "Pune",
    "Ahmedabad",
  ];
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
  final List<String> _popularSkills = [
    "Flutter",
    "Firebase",
    "Python",
    "React",
    "Problem Solver",
    "Creative Thinker",
    "Team Player",
    "Leadership",
    "Time Management",
    "Communication",
  ];

  @override
  void initState() {
    super.initState();
    _loadCollegeName();

    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    // Define the blobs that will be animated
    _blobs = [
      Blob(
        initialRadius: 200,
        initialX: 0,
        initialY: 0.2,
        speed: 1.2,
        color: const Color(0xFFD2691E).withOpacity(0.15),
      ),
      Blob(
        initialRadius: 250,
        initialX: 1,
        initialY: 0.7,
        speed: 0.8,
        color: const Color(0xFFD2691E).withOpacity(0.1),
      ),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _locationController.dispose();
    _skillsController.dispose();
    _universityController.dispose();
    _degreeController.dispose();
    _fieldOfStudyController.dispose();
    _yearOfStudyController.dispose();
    _subdomainController.dispose();
    _mainDomainController.dispose();
    super.dispose();
  }

  // --- All your existing backend logic methods are preserved ---

  Future<void> _fetchCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          showBottomToast("Location permission denied.");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        showBottomToast("Location permissions are permanently denied.");
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
        final city = place.locality;
        if (city != null && _cities.contains(city)) {
          setState(() {
            _selectedCity = city;
            _locationController.text = city;
          });
        } else {
          showBottomToast(
            "Could not auto-detect your city from the available options.",
          );
        }
      }
    } catch (e) {
      print("Error fetching location: $e");
      showBottomToast("Error fetching location.");
    }
  }

  Future<void> _loadCollegeName() async {
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
    return result?.files.single;
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 1:
        if (_degreeController.text.trim().isEmpty) {
          showBottomToast("Please select your degree.");
          return false;
        }
        if (_fieldOfStudyController.text.trim().isEmpty) {
          showBottomToast("Please select your field of study.");
          return false;
        }
        if (_yearOfStudyController.text.trim().isEmpty) {
          showBottomToast("Please select your year of study.");
          return false;
        }
        break;
      case 2:
        if (_mainDomainController.text.trim().isEmpty) {
          showBottomToast("Please select your main domain.");
          return false;
        }
        if (_subdomainController.text.trim().isEmpty) {
          showBottomToast("Please enter your preferred domain.");
          return false;
        }
        break;
    }
    return true;
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_validateCurrentPage()) return;

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

        final userData = {
          "displayName": user.displayName ?? "",
          "location": _locationController.text.trim(),
          "skills": _skillsList,
          "university": _universityController.text.trim(),
          "collegeId": collegeId,
          "degree": _degreeController.text.trim(),
          'yearOfStudy': _yearOfStudyController.text.trim(),
          "fieldOfStudy": _fieldOfStudyController.text.trim(),
          "maindomain": _mainDomainController.text.trim(),
          "subdomain": _subdomainController.text.trim(),
          "resumeFileName": _resumeFileName,
          "resumeUrl": _resumeUrl,
          "completedOnboarding": true,
          "updatedAt": FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("personaldetails")
            .doc("details")
            .set(userData, SetOptions(merge: true));
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "fieldOfStudy": _fieldOfStudyController.text.trim(),
          "collegeId": collegeId,
        }, SetOptions(merge: true));

        final leaderboardData = {
          "name": user.displayName ?? "",
          "university": _universityController.text.trim(),
          "degree": _degreeController.text.trim(),
          "fieldOfStudy": _fieldOfStudyController.text.trim(),
          "points": 100,
          "photoUrl": user.photoURL ?? "",
          'yearOfStudy': _yearOfStudyController.text.trim(),
          "maindomain": _mainDomainController.text.trim(),
          "subdomain": _subdomainController.text.trim(),
          "createdAt": FieldValue.serverTimestamp(),
        };

        final collegeDocId = collegeQuery.docs.first.id;
        final fieldOfStudy = _fieldOfStudyController.text.trim();
        final leaderboardRef = FirebaseFirestore.instance
            .collection("colleges")
            .doc(collegeDocId)
            .collection("leaderboard")
            .doc(fieldOfStudy);

        await leaderboardRef.set({
          "createdAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await leaderboardRef
            .collection("students")
            .doc(user.uid)
            .set(leaderboardData, SetOptions(merge: true));

        showBottomToast("Onboarding completed successfully!", bg: Colors.green);
        if (mounted) Navigator.pushReplacementNamed(context, "/home");
      } catch (e) {
        showBottomToast("Error: $e", bg: Colors.red);
      }
    }
    setState(() => _isLoading = false);
  }

  // --- Build Method and UI Widgets ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          JellyBackground(controller: _animationController, blobs: _blobs),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        "Step ${_currentPage + 1} of $_totalPages",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (_currentPage + 1) / _totalPages,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.green,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged:
                        (page) => setState(() => _currentPage = page),
                    children: [
                      _buildPersonalDetailsPage(),
                      _buildEducationDetailsPage(),
                      _buildGoalsPage(),
                    ],
                  ),
                ),
                _buildBottomNavBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _glassmorphismInputDecoration(
    String labelText,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.black.withOpacity(0.25),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildPageWrapper({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  /// Helper widget to apply a consistent glassmorphic theme to dropdown menus.
  Widget _buildThemedDropdown({required Widget child}) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.black.withOpacity(
          0.75,
        ), // Semi-transparent background
      ),
      child: child,
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

    return _buildPageWrapper(
      title: "Welcome!",
      subtitle: "Let's start with the basics.",
      children: [
        _buildTextField(
          TextEditingController(text: user?.displayName ?? "Anonymous"),
          "Full Name",
          Icons.person_outline,
          enabled: false,
        ),
        const SizedBox(height: 16),
        _buildThemedDropdown(
          child: DropdownButtonFormField<String>(
            value: _selectedCity,
            decoration: _glassmorphismInputDecoration(
              "Location (Optional)",
              Icons.location_on_outlined,
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.my_location_outlined,
                  color: Colors.white.withOpacity(0.7),
                ),
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => const ConfirmationDialog(
                          title: 'Fetch Current Location?',
                          content:
                              'Do you want to automatically fetch your current city?',
                          confirmText: 'Fetch',
                          cancelText: 'cancel',
                          icon: Icons.pin_drop,
                        ),
                  );
                  if (result == true) await _fetchCurrentLocation();
                },
              ),
            ),
            style: const TextStyle(color: Colors.white),
            items:
                _cities
                    .map(
                      (city) =>
                          DropdownMenuItem(value: city, child: Text(city)),
                    )
                    .toList(),
            onChanged: (val) {
              setState(() {
                _selectedCity = val;
                _locationController.text = val ?? "";
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty)
              return const Iterable<String>.empty();
            return allowedSkills.where(
              (s) =>
                  s.toLowerCase().contains(textEditingValue.text.toLowerCase()),
            );
          },
          onSelected: (skill) {
            if (!_skillsList.contains(skill))
              setState(() => _skillsList.add(skill));
            _skillsController.clear();
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(color: Colors.white),
              decoration: _glassmorphismInputDecoration(
                "Add a Skill (Optional)",
                Icons.lightbulb_outline,
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty &&
                    !_skillsList.contains(value.trim())) {
                  setState(() => _skillsList.add(value.trim()));
                }
                controller.clear();
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.transparent, // Important for blur to be visible
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      width: MediaQuery.of(context).size.width - 48,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: options.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 8.0,
                              ),
                              child: Text(
                                option,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _skillsList
                  .map(
                    (skill) => Chip(
                      label: Text(skill),
                      labelStyle: const TextStyle(color: Colors.white),
                      backgroundColor: Colors.black.withOpacity(0.3),
                      onDeleted:
                          () => setState(() => _skillsList.remove(skill)),
                      deleteIconColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          "Popular Skills",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children:
              _popularSkills
                  .map(
                    (skill) => Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (!_skillsList.contains(skill))
                            setState(() => _skillsList.add(skill));
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
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
          "University/College",
          Icons.school_outlined,
          enabled: false,
        ),
        const SizedBox(height: 16),
        _buildThemedDropdown(
          child: DropdownButtonFormField<String>(
            value: _selectedDegree,
            decoration: _glassmorphismInputDecoration(
              "Degree*",
              Icons.workspace_premium_outlined,
            ),
            style: const TextStyle(color: Colors.white),
            isExpanded: true,
            items:
                _engineeringDegrees
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
            onChanged:
                (val) => setState(() {
                  _selectedDegree = val;
                  _degreeController.text = val ?? "";
                }),
          ),
        ),
        const SizedBox(height: 16),
        _buildThemedDropdown(
          child: DropdownButtonFormField<String>(
            value: _selectedField,
            decoration: _glassmorphismInputDecoration(
              "Field of Study*",
              Icons.science_outlined,
            ),
            style: const TextStyle(color: Colors.white),
            isExpanded: true,
            items:
                _engineeringFields
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(f, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
            onChanged:
                (val) => setState(() {
                  _selectedField = val;
                  _fieldOfStudyController.text = val ?? "";
                }),
          ),
        ),
        const SizedBox(height: 16),
        _buildThemedDropdown(
          child: DropdownButtonFormField<String>(
            value: _selectedYear,
            decoration: _glassmorphismInputDecoration(
              "Year of Study*",
              Icons.calendar_today_outlined,
            ),
            style: const TextStyle(color: Colors.white),
            isExpanded: true,
            items:
                _years
                    .map(
                      (y) => DropdownMenuItem(
                        value: y,
                        child: Text(y, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
            onChanged:
                (val) => setState(() {
                  _selectedYear = val;
                  _yearOfStudyController.text = val ?? "";
                }),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsPage() {
    return _buildPageWrapper(
      title: "Career Goals",
      subtitle: "What are you looking for?",
      children: [
        Consumer(
          builder: (context, ref, _) {
            final asyncDomains = ref.watch(domainNamesProvider);
            return asyncDomains.when(
              data: (domains) {
                final domainNames = domains.map((d) => d.name).toList();
                return _buildThemedDropdown(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMainDomain,
                    decoration: _glassmorphismInputDecoration(
                      "Main Domain*",
                      Icons.business_center_outlined,
                    ),
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    items:
                        domainNames
                            .map(
                              (name) => DropdownMenuItem(
                                value: name,
                                child: Text(name),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (value) => setState(() {
                          _selectedMainDomain = value;
                          _mainDomainController.text = value ?? '';
                        }),
                  ),
                );
              },
              loading:
                  () => Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              error:
                  (e, _) => Text(
                    "Error loading domains: $e",
                    style: const TextStyle(color: Colors.red),
                  ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _subdomainController,
          "Preferred Domain*",
          Icons.track_changes_outlined,
        ),
        const SizedBox(height: 24),
       
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(color: enabled ? Colors.white : Colors.grey[400]),
      decoration: _glassmorphismInputDecoration(label, icon),
    );
  }

  Widget _buildBottomNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed:
                  () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  ),
              child: const Text(
                "Previous",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          else
            const SizedBox(), // Spacer

          _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  if (_validateCurrentPage()) {
                    if (_currentPage < _totalPages - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _submit();
                    }
                  }
                },
                child: Text(_currentPage < _totalPages - 1 ? "NEXT" : "FINISH"),
              ),
        ],
      ),
    );
  }
}

// This widget contains the background animation logic
class JellyBackground extends StatefulWidget {
  final AnimationController controller;
  final List<Blob> blobs;

  const JellyBackground({
    super.key,
    required this.controller,
    required this.blobs,
  });

  @override
  State<JellyBackground> createState() => _JellyBackgroundState();
}

class _JellyBackgroundState extends State<JellyBackground> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF212121), Color(0xFF111111)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) {
          final screenSize = MediaQuery.of(context).size;
          for (var blob in widget.blobs) {
            blob.move(widget.controller.value * 2 * pi, screenSize);
          }
          return CustomPaint(
            painter: BackgroundPainter(blobs: widget.blobs),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

// This painter is responsible for drawing the blobs on the canvas
class BackgroundPainter extends CustomPainter {
  final List<Blob> blobs;

  BackgroundPainter({required this.blobs});

  @override
  void paint(Canvas canvas, Size size) {
    for (var blob in blobs) {
      final paint = Paint()..color = blob.color;
      final correctedInitialX = blob.initialX * size.width;
      final correctedInitialY = blob.initialY * size.height;

      // The position calculation has been simplified to rely on the AnimationController's value
      // This ensures smooth animation tied to the controller's lifecycle.
      final animationValue =
          (DateTime.now().millisecondsSinceEpoch / (1000 * 40)) * 2 * pi;
      final newX =
          correctedInitialX +
          sin(blob.speed * animationValue) * (size.width * 0.2);
      final newY =
          correctedInitialY +
          cos(blob.speed * animationValue) * (size.height * 0.2);

      final breathingValue = sin(blob.speed * 0.8 * animationValue);
      final newRadius = blob.initialRadius + breathingValue * 15;

      canvas.drawCircle(Offset(newX, newY), newRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for continuous animation
  }
}
