import 'dart:async';
import 'package:careerclaritycompanion/data/models/course_model.dart';
import 'package:careerclaritycompanion/data/models/internship_model.dart';
import 'package:careerclaritycompanion/features/custom_widgets/fllutter_toast.dart';
import 'package:careerclaritycompanion/features/screens/home/domain/domain_description_tab.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class DomainDetailScreen extends StatefulWidget {
  final String domainId;

  const DomainDetailScreen({super.key, required this.domainId});

  @override
  State<DomainDetailScreen> createState() => _DomainDetailScreenState();
}

class _DomainDetailScreenState extends State<DomainDetailScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = "";
  Timer? _debounce;

  // Animation Controller for search bar
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      // Animate search bar when tab changes
      if (_tabController.index == 1 || _tabController.index == 2) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      setState(() {});
    });

    _searchController.addListener(_onSearchChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _widthAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    // Initially hide search bar
    if (_tabController.index == 1 || _tabController.index == 2) {
      _animationController.forward();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesRef = FirebaseFirestore.instance
        .collection("domains")
        .doc(widget.domainId)
        .collection("courses");

    final internshipsRef = FirebaseFirestore.instance
        .collection("domains")
        .doc(widget.domainId)
        .collection("internships");

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.domainId.toUpperCase()),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            // If the search bar is visible, 120; else just 48 for TabBar
            (_tabController.index == 1 || _tabController.index == 2) ? 120 : 48,
          ),
          child: Column(
            children: [
              // ✅ Only show search bar if tab 1 or 2 is selected
              if (_tabController.index == 1 || _tabController.index == 2)
                AnimatedBuilder(
                  animation: _widthAnimation,
                  builder: (context, child) {
                    return Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width:
                            _widthAnimation.value *
                            MediaQuery.of(context).size.width,
                        child:
                            _widthAnimation.value > 0
                                ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText:
                                          "Search courses or internships...",
                                      prefixIcon: const Icon(Icons.search),
                                      filled: true,
                                      fillColor: Colors.white54,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                )
                                : const SizedBox.shrink(),
                      ),
                    );
                  },
                ),

              // TabBar
              TabBar(
                controller: _tabController,
                isScrollable: false,
                tabAlignment: TabAlignment.center,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: "Description"),
                  Tab(text: "Courses"),
                  Tab(text: "Internships"),
                  Tab(text: "Projects"),
                ],
              ),
            ],
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          DomainDescriptionTab(domainName: widget.domainId),
          _buildCoursesTab(coursesRef),
          _buildInternshipsTab(internshipsRef),
          _buildProjectsTab(),
        ],
      ),
    );
  }

  Widget _buildProjectsTab() {
    final projectsRef = FirebaseFirestore.instance
        .collection("domains")
        .doc(widget.domainId)
        .collection("projects");

    return StreamBuilder<QuerySnapshot>(
      stream: projectsRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allProjects =
            snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                "themeTitle": data["themeTitle"] ?? "Untitled Project",
                "problemStatement": data["problemStatement"] ?? "",
              };
            }).toList();

        if (allProjects.isEmpty) {
          return const Center(child: Text("No projects found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: allProjects.length,
          itemBuilder: (context, index) {
            final project = allProjects[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project["themeTitle"],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      project["problemStatement"],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCoursesTab(CollectionReference coursesRef) {
    return StreamBuilder<QuerySnapshot>(
      stream: coursesRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allCourses =
            snapshot.data!.docs.map((doc) {
              return CourseModel.fromMap(doc.data() as Map<String, dynamic>);
            }).toList();

        final filteredCourses =
            allCourses.where((course) {
              return course.title.toLowerCase().contains(_searchQuery);
            }).toList();

        if (filteredCourses.isEmpty) {
          return const Center(child: Text("No courses found"));
        }

        return ListView.builder(
          itemCount: filteredCourses.length,
          itemBuilder: (context, index) {
            final course = filteredCourses[index];
            return Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    course.imageUrl.isNotEmpty
                        ? Image.network(
                          course.imageUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                        : Container(
                          height: 220,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.school,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black45,
                            Colors.black,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: StreamBuilder<DocumentSnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .collection('bookmarks')
                                .doc(course.title)
                                .snapshots(),
                        builder: (context, snapshot) {
                          bool isBookmarked =
                              snapshot.hasData && snapshot.data!.exists;
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black38,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isBookmarked
                                    ? Icons.bookmark_added
                                    : Icons.bookmark_add_outlined,
                                color: Colors.white,
                                size: 26,
                              ),
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;

                                final bookmarksRef = FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('bookmarks')
                                    .doc(course.title);

                                if (isBookmarked) {
                                  await bookmarksRef.delete();
                                  showBottomToast("Bookmark removed!");
                                } else {
                                  await bookmarksRef.set(course.toMap());
                                  showBottomToast("Course bookmarked!");
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black38,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.open_in_new,
                            color: Colors.white,
                            size: 26,
                          ),
                          onPressed: () async {
                            final Uri url = Uri.parse(course.url);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.inAppBrowserView,
                              );
                            } else {
                              showBottomToast("Could not launch link");
                            }
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${course.platform} • ${course.price}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ...List.generate(5, (starIndex) {
                                if (course.rating >= starIndex + 1) {
                                  return const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 18,
                                  );
                                }
                                if (course.rating > starIndex &&
                                    course.rating < starIndex + 1) {
                                  return const Icon(
                                    Icons.star_half,
                                    color: Colors.amber,
                                    size: 18,
                                  );
                                }
                                return const Icon(
                                  Icons.star_border,
                                  color: Colors.amber,
                                  size: 18,
                                );
                              }),
                              const SizedBox(width: 6),
                              Text(
                                course.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInternshipsTab(CollectionReference internshipsRef) {
    return StreamBuilder<QuerySnapshot>(
      stream: internshipsRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allInternships =
            snapshot.data!.docs.map((doc) {
              return JobListing.fromMap(doc.data() as Map<String, dynamic>);
            }).toList();

        final filteredInternships =
            allInternships.where((job) {
              final titleLower = job.title.toLowerCase();
              final companyLower = job.companyName.toLowerCase();
              return titleLower.contains(_searchQuery) ||
                  companyLower.contains(_searchQuery);
            }).toList();

        if (filteredInternships.isEmpty) {
          return const Center(child: Text("No internships found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filteredInternships.length,
          itemBuilder: (context, index) {
            final intern = filteredInternships[index];
            return _buildInternshipCard(context, intern); // ⬅️ Updated UI
          },
        );
      },
    );
  }

  /// Builds a professional and informative card for an internship.
  Widget _buildInternshipCard(BuildContext context, JobListing intern) {
    // Helper method to launch URLs safely
    Future<void> _launchUrl(String urlString) async {
      final Uri url = Uri.parse(urlString);
      if (!await canLaunchUrl(url)) {
        // Optionally show a snackbar or alert to the user
        print("Could not launch $urlString");
        return;
      }
      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    }

    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with company logo and info
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    intern.companyLogoUrl.isNotEmpty
                        ? NetworkImage(intern.companyLogoUrl)
                        : null,
                child:
                    intern.companyLogoUrl.isEmpty
                        ? const Icon(Icons.business, color: Colors.grey)
                        : null,
              ),
              title: Text(
                intern.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Company: ${intern.companyName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),

            // Key details with icons
            _InfoChip(
              icon: Icons.location_on_outlined,
              text: intern.companyLocation,
            ),
            const SizedBox(height: 6),
            _InfoChip(icon: Icons.date_range, text: intern.postedAgo),
            const SizedBox(height: 12),

            // Action Button
            Row(
              children: [
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(intern.url),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                  ),
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  label: const Text(
                    "Apply Now",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A small widget to display an icon and text, used in the internship card.
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
