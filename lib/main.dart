
import 'package:careerclaritycompanion/college_side/college_screen.dart';
import 'package:careerclaritycompanion/features/screens/chat_screen.dart';
import 'package:careerclaritycompanion/features/screens/login_page.dart';
import 'package:careerclaritycompanion/features/screens/shimmer/homepage_shimmer.dart';
import 'package:careerclaritycompanion/main_screen.dart';
import 'package:careerclaritycompanion/spalsh_screen.dart';
import 'package:careerclaritycompanion/theme.dart';
import 'package:careerclaritycompanion/features/screens/student_login_screen.dart';
import 'package:careerclaritycompanion/features/screens/onboarding_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: VideoSplashScreen(), // this decides the start screen
      routes: {
        '/home': (context) => const MainScreen(),
        '/chat': (context) => const ChatScreen(),
      },
    );
  }
}
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // 🔍 Check if user exists in students collection
  Future<bool> _checkStudent(User user) async {
    final docSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return docSnapshot.exists;
  }

  // 🔍 Check if user exists in staff collection
  Future<bool> _checkStaff(User user) async {
    final docSnapshot =
        await FirebaseFirestore.instance.collection('staffs').doc(user.uid).get();
    return docSnapshot.exists;
  }

  // 🔍 For students, check if onboarding completed
  Future<bool> _checkOnboardingCompleted(User user) async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('personaldetails')
        .doc('details')
        .get();

    if (!docSnapshot.exists) return false;
    final data = docSnapshot.data();
    return data?['completedOnboarding'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;

          return FutureBuilder(
            future: Future.wait([
              _checkStudent(user),
              _checkStaff(user),
            ]),
            builder: (context, snap) {
              if (!snap.hasData) {
                return CareerShimmerPageNoIcons(); // ⏳ loading shimmer
              }

              final isStudent = snap.data![0];
              final isStaff = snap.data![1];

              if (isStudent) {
                // 🔹 If student → check onboarding
                return FutureBuilder<bool>(
                  future: _checkOnboardingCompleted(user),
                  builder: (context, onboardingSnap) {
                    if (!onboardingSnap.hasData) {
                      return CareerShimmerPageNoIcons();
                    }
                    return onboardingSnap.data!
                        ? const MainScreen()
                        : const OnboardingScreen();
                  },
                );
              } else if (isStaff) {
                // 🔹 If staff → take them to Staff Dashboard
                return const CollegeScreen();
              } else {
                // ❌ If not found in either → logout
                FirebaseAuth.instance.signOut();
                return const SwipeLoginPage();
              }
            },
          );
        }

        return const SwipeLoginPage(); // not logged in
      },
    );
  }
}
