import 'package:careerclaritycompanion/features/screens/chat_screen.dart';
import 'package:careerclaritycompanion/main_screen.dart';
import 'package:careerclaritycompanion/theme.dart';
import 'package:careerclaritycompanion/features/screens/login_screen.dart';
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
      home: const AuthGate(), // this decides the start screen
      routes: {
        '/home': (context) => const MainScreen(),
        '/chat': (context) => const ChatScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _checkOnboardingCompleted(User user) async {
    final docSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('personaldetails')
            .doc('details') // fixed doc
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
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<bool>(
            future: _checkOnboardingCompleted(user),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return snap.data! ? const MainScreen() : const OnboardingScreen();
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}
