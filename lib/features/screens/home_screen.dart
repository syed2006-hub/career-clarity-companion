import 'package:careerclaritycompanion/data/models/company_model.dart';
import 'package:careerclaritycompanion/features/custom_widgets/custom_drawer.dart';
import 'package:careerclaritycompanion/features/screens/ai_coachslider_screen.dart';
import 'package:careerclaritycompanion/data_seeder/all_domain_screen.dart';
import 'package:careerclaritycompanion/features/screens/company_list_screen.dart';
import 'package:careerclaritycompanion/features/screens/domain_list.dart';
import 'package:careerclaritycompanion/features/screens/smart_recomendation_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final userdata = FirebaseAuth.instance.currentUser;

  String getFirstTwoWords(String? name) {
    if (name == null || name.trim().isEmpty) return '';

    List<String> words = name.trim().split(' ');
    return words.length >= 2 ? '${words[0]} ' : words[0];
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // attach the key here
      drawer: CustomDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // 👈 this opens drawer
          },
        ),
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hi, ${getFirstTwoWords(userdata?.displayName)}👋",
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  Row(
                    children: [
                      Text(
                        "Reach your dream destination ",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      Icon(Icons.trending_up, size: 16),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.userChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user != null &&
                      user.photoURL != null &&
                      user.photoURL!.isNotEmpty) {
                    return CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(user.photoURL!),
                    );
                  } else {
                    return Icon(Icons.account_circle_rounded);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      // Use NestedScrollView or CustomScrollView
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                     
                    GuidanceCard(),
                    SizedBox(height: 20),
                    Text(
                      "Smart Recomandation",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    SmartRecommendationSlider(),
                    SizedBox(height: 20),

                    Text(
                      "Top Companies",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    CompanyTickerWrapper(),
                    SizedBox(height: 20),

                    // Job Categories
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Popular Domains",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed:
                              () => Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) => AllDomainScreen(),
                                ),
                              ),
                          child: Text(
                            'View all',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DomainListScreen(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompanyTickerWrapper extends StatelessWidget {
  const CompanyTickerWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('companies').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading companies"));
        }

        final companies =
            snapshot.data!.docs
                .map((doc) => CompanyInfo.fromSnapshot(doc))
                .toList();

        return CompanyTicker(companies: companies);
      },
    );
  }
}
