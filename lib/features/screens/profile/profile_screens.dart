import 'dart:io';
import 'dart:ui'; // Required for lerpDouble
import 'package:careerclaritycompanion/features/custom_widgets/custom_drawer.dart';
import 'package:careerclaritycompanion/features/custom_widgets/fllutter_toast.dart';
import 'package:careerclaritycompanion/service/clodinary_service/cloudinary_service.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  // ✨ 1. ADDED OPTIONAL UID TO CONSTRUCTOR
  final String? uid;
  const ProfileScreen({super.key, this.uid});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  File? _pickedImage;
  bool _isUploading = false;
  String? _photoUrl;
  String? _displayName;
  Map<String, dynamic>? _userDetails;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✨ 2. NEW STATE VARIABLES TO MANAGE WHICH PROFILE TO SHOW
  String? _targetUid;
  bool _isCurrentUserProfile = false;

  @override
  void initState() {
    super.initState();
    // Determine which user's profile to load
    _targetUid = widget.uid ?? _auth.currentUser?.uid;
    _isCurrentUserProfile = (_targetUid == _auth.currentUser?.uid);

    if (_targetUid != null) {
      _fetchProfileData();
    }
  }

  // ✨ 3. COMBINED DATA FETCHING LOGIC
  Future<void> _fetchProfileData() async {
    if (_targetUid == null) return;

    // Fetch main user document from 'users' collection for photo and name
    final userDoc = await _firestore.collection('users').doc(_targetUid).get();
    if (mounted && userDoc.exists) {
      final data = userDoc.data()!;
      setState(() {
        _photoUrl = data['photoUrl'] as String?;
        // Assuming 'displayName' is stored in your user document
        _displayName = data['fullName'] as String?;
      });
    }

    // Fetch detailed info from subcollection
    final detailsDoc =
        await _firestore
            .collection('users')
            .doc(_targetUid)
            .collection('personaldetails')
            .doc('details')
            .get();
    if (mounted && detailsDoc.exists) {
      setState(() {
        _userDetails = detailsDoc.data();
      });
    }
  }

  Future<void> _pickAndUploadProfileUrl() async {
    // This function only runs for the current user, so it doesn't need changes
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile == null) return;
      setState(() {
        _pickedImage = File(pickedFile.path);
        _isUploading = true;
      });
      final imageUrl = await _cloudinaryService.uploadImage(_pickedImage!);
      if (imageUrl == null) {
        showBottomToast("Failed to upload image!");
        return;
      }
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'photoUrl': imageUrl,
      }, SetOptions(merge: true));

      await user.updatePhotoURL(imageUrl);
      await user.reload();

      if (mounted) setState(() => _photoUrl = imageUrl);
      showBottomToast("Profile image updated!");
    } catch (e) {
      showBottomToast("Error updating image!");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        // ✨ 4. CONDITIONAL DRAWER
        drawer: _isCurrentUserProfile ? CustomDrawer() : null,
        key: _scaffoldKey,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 260.0,
                floating: false,
                pinned: true,
                // ✨ 5. SHOW BACK BUTTON IF NOT THE CURRENT USER'S PROFILE
                automaticallyImplyLeading: !_isCurrentUserProfile,
                // ✨ 6. PASS UPDATED AND NEW PARAMETERS TO THE HEADER
                flexibleSpace: _CollapsingHeader(
                  displayName: _displayName ?? "User Name",
                  userDetails: _userDetails,
                  photoUrl: _photoUrl,
                  scaffoldkey: _scaffoldKey,
                  isUploading: _isUploading,
                  // Only allow avatar tap if it's the current user
                  onAvatarTap:
                      _isCurrentUserProfile ? _pickAndUploadProfileUrl : () {},
                  isCurrentUserProfile: _isCurrentUserProfile,
                ),
                bottom: const TabBar(
                  indicatorColor: Colors.tealAccent,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelColor: Colors.grey,
                  labelColor: Colors.white,
                  tabs: [
                    Tab(text: 'Personal Info'),
                    Tab(text: 'Achievements'),
                    Tab(text: 'Projects'),
                  ],
                ),
              ),
            ];
          },
          // ✨ 7. HANDLE CASE WHERE NO UID IS AVAILABLE
          body:
              _targetUid == null
                  ? const Center(child: Text("User not found."))
                  : TabBarView(
                    children: [
                      _PersonalInfoTab(userDetails: _userDetails),
                      // Pass the target UID to the tabs
                      _AchievementsTab(uid: _targetUid!),
                      _ProjectTab(uid: _targetUid!),
                    ],
                  ),
        ),
      ),
    );
  }
}

// ✨ NEW WIDGET FOR THE ANIMATED HEADER
class _CollapsingHeader extends StatefulWidget {
  // final User? user; // Replaced with displayName
  final String displayName;
  final String? photoUrl;
  final bool isUploading;
  final GlobalKey<ScaffoldState> scaffoldkey;
  final VoidCallback onAvatarTap;
  final Map<String, dynamic>? userDetails;
  // New parameter to control UI elements
  final bool isCurrentUserProfile;

  const _CollapsingHeader({
    required this.displayName,
    this.photoUrl,
    required this.isUploading,
    required this.scaffoldkey,
    required this.onAvatarTap,
    this.userDetails,
    required this.isCurrentUserProfile,
  });

  @override
  State<_CollapsingHeader> createState() => _CollapsingHeaderState();
}

class _CollapsingHeaderState extends State<_CollapsingHeader> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final settings =
            context
                .dependOnInheritedWidgetOfExactType<
                  FlexibleSpaceBarSettings
                >()!;
        final delta = settings.maxExtent - settings.minExtent;
        final t = (1.0 - (settings.currentExtent - settings.minExtent) / delta)
            .clamp(0.0, 1.0);

        final maxAvatarSize = 80.0;
        final minAvatarSize = 40.0;

        // Avatar size based on scroll position
        final avatarSize = lerpDouble(minAvatarSize, maxAvatarSize, 1 - t);

        // Avatar horizontal position
        final avatarX = lerpDouble(
          // Adjusted left padding for when back button is visible
          widget.isCurrentUserProfile ? 16.0 : 56.0,
          (constraints.maxWidth / 2) - (maxAvatarSize / 2),
          1 - t,
        );

        // Avatar vertical position
        final avatarY = lerpDouble(8.0, 60.0, 1 - t);

        return SafeArea(
          child: Stack(
            children: [
              // --- Collapsed State Content (Fades IN) ---
              Positioned(
                top: 8,
                // Adjusted left position for when back button is visible
                left: widget.isCurrentUserProfile ? 64 : 104,
                child: Opacity(
                  opacity: t,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // Use displayName from parameters
                        widget.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.userDetails?['fieldOfStudy'] != null)
                        Text(
                          widget.userDetails!['fieldOfStudy'],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.0,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // --- Expanded State Content (Fades OUT) ---
              Positioned(
                left: 0,
                right: 0,
                top: 150,
                child: Opacity(
                  opacity: 1 - t,
                  child: Column(
                    children: [
                      Text(
                        // Use displayName from parameters
                        widget.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.userDetails?['fieldOfStudy'] ?? "Student",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- The Animating Avatar ---
              Positioned(
                top: avatarY,
                left: avatarX,
                width: avatarSize,
                height: avatarSize,
                child:
                    widget.isUploading
                        ? Shimmer.fromColors(
                          baseColor: Colors.white24,
                          highlightColor: Colors.white,
                          child: CircleAvatar(radius: avatarSize! / 2),
                        )
                        : GestureDetector(
                          // onTap is now conditional
                          onTap:
                              widget.isCurrentUserProfile
                                  ? widget.onAvatarTap
                                  : null,
                          child: CircleAvatar(
                            radius: avatarSize! / 2,
                            backgroundImage:
                                widget.photoUrl != null
                                    ? NetworkImage(widget.photoUrl!)
                                    : null,
                            child:
                                widget.photoUrl == null
                                    ? Text(
                                      // Use displayName from parameters
                                      widget.displayName.isNotEmpty
                                          ? widget.displayName
                                              .substring(0, 1)
                                              .toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: avatarSize / 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : null,
                          ),
                        ),
              ),

              // --- 📌 MENU BUTTON ON TOP RIGHT ---
              // ✨ 8. ONLY SHOW MENU BUTTON FOR THE CURRENT USER
              if (widget.isCurrentUserProfile)
                Positioned(
                  top: 8,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      widget.scaffoldkey.currentState?.openDrawer();
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// =========================================================================
// The Tab Widgets (_PersonalInfoTab, etc.) remain unchanged.
// =========================================================================
class _PersonalInfoTab extends StatelessWidget {
  // ... (Your existing _PersonalInfoTab code)
  final Map<String, dynamic>? userDetails;
  const _PersonalInfoTab({this.userDetails});

  String _getListString(dynamic value) {
    if (value == null) return 'Not provided';
    if (value is List && value.isEmpty) return 'Not provided';
    if (value is List) return value.join(', ');
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (userDetails == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          "Full Name",
          userDetails!['displayName'] ?? "",
          context,
          Icons.person,
        ),
        _buildInfoCard(
          "University",
          userDetails!['university'] ?? "",
          context,
          Icons.school,
        ),
        _buildInfoCard(
          "Degree",
          userDetails!['degree'] ?? "",
          context,
          Icons.book,
        ),
        _buildInfoCard(
          "Field of Study",
          userDetails!['fieldOfStudy'] ?? "",
          context,
          Icons.science,
        ),
        _buildInfoCard(
          "Main Domain",
          userDetails!['maindomain'] ?? "",
          context,
          Icons.science,
        ),
        _buildInfoCard(
          "Technology",
          userDetails!['subdomain'] ?? "",
          context,
          Icons.science,
        ),
        _buildInfoCard(
          "Skills",
          _getListString(userDetails!['skills']),
          context,
          Icons.lightbulb,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    BuildContext context,
    IconData icon, {
    bool isLink = false,
  }) {
    return Card(
      color: Theme.of(context).colorScheme.secondary,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.tealAccent),
        title: Text(title, style: const TextStyle(color: Colors.white70)),
        subtitle:
            isLink
                ? GestureDetector(
                  onTap: () {
                    // Implement resume view/download
                  },
                  child: Text(
                    "View Resume",
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                : Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }
}

// ✨ 9. UPDATED _ProjectTab TO ACCEPT A UID
class _ProjectTab extends StatefulWidget {
  final String uid;
  const _ProjectTab({required this.uid});

  @override
  State<_ProjectTab> createState() => _ProjectTabState();
}

class _ProjectTabState extends State<_ProjectTab> {
  final Map<int, ChewieController> _controllers = {};

  @override
  void dispose() {
    _controllers.forEach((key, controller) {
      controller.videoPlayerController.dispose();
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Use the uid passed via the widget constructor
      stream:
          FirebaseFirestore.instance
              .collection("users")
              .doc(widget.uid)
              .collection("projects")
              .orderBy("timestamp", descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No projects yet",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        final projects = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final data = projects[index].data() as Map<String, dynamic>;
            final videoUrl = data["videoUrl"] as String?;

            if (videoUrl != null && !_controllers.containsKey(index)) {
              final videoController = VideoPlayerController.networkUrl(
                Uri.parse(videoUrl),
              );
              _controllers[index] = ChewieController(
                videoPlayerController: videoController,
                autoPlay: false,
                looping: false,
              );
            }

            return Card(
              color: const Color(0xff1e1e3f),
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (videoUrl != null && _controllers.containsKey(index))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Chewie(controller: _controllers[index]!),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      data["description"] ?? "",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    if (data["githubLink"] != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          launchUrl(Uri.parse(data["githubLink"]));
                        },
                        child: Text(
                          data["githubLink"],
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ✨ 10. UPDATED _AchievementsTab TO ACCEPT A UID
class _AchievementsTab extends StatelessWidget {
  final String uid;
  const _AchievementsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Use the uid passed via the widget constructor
      stream:
          FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection("achievements")
              .orderBy("timestamp", descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No achievements yet",
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        final achievements = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final data = achievements[index].data() as Map<String, dynamic>;
            return Card(
              color: const Color(0xff1e1e3f),
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data["certificateUrl"] != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        data["certificateUrl"],
                        fit: BoxFit.cover,
                        height: 200,
                        width: double.infinity,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      data["description"] ?? "",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
