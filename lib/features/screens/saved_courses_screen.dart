import 'package:careerclaritycompanion/data/models/course_model.dart';
import 'package:careerclaritycompanion/features/custom_widgets/fllutter_toast.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class SavedCoursesPage extends StatelessWidget {
  const SavedCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Saved Courses"), centerTitle: true),
        body: const Center(child: Text("Please log in to see saved courses")),
      );
    }

    final bookmarksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Saved Courses",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            SizedBox(width: 10),
            Icon(Icons.bookmark_added_outlined, color: Colors.white),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: bookmarksRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No saved courses", style: TextStyle(fontSize: 16)),
            );
          }

          final courses =
              snapshot.data!.docs
                  .map(
                    (doc) =>
                        CourseModel.fromMap(doc.data() as Map<String, dynamic>),
                  )
                  .toList();

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];

              return Padding(
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Background
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

                      // Overlay
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

                      // Bookmark icon (filled)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black38,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.bookmark_added,
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: () async {
                              try {
                                await bookmarksRef.doc(course.title).delete();
                                showBottomToast("Bookmark removed");
                              } catch (e) {
                                showBottomToast("Failed to remove bookmark");
                              }
                            },
                          ),
                        ),
                      ),

                      // Link icon
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

                      // Course Info
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
                                  } else if (course.rating > starIndex &&
                                      course.rating < starIndex + 1) {
                                    return const Icon(
                                      Icons.star_half,
                                      color: Colors.amber,
                                      size: 18,
                                    );
                                  } else {
                                    return const Icon(
                                      Icons.star_border,
                                      color: Colors.amber,
                                      size: 18,
                                    );
                                  }
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
      ),
    );
  }
}
