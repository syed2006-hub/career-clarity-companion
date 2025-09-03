import 'package:careerclaritycompanion/data/models/user_model.dart';
import 'package:careerclaritycompanion/features/custom_widgets/fllutter_toast.dart';
import 'package:careerclaritycompanion/features/screens/registration_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;

  // This entire function is perfect and does not need changes.
  Future<void> signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // Force account picker
      await _googleSignIn.signOut();
      try {
        await _googleSignIn.disconnect();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final email = googleUser.email;
      final emailDomain = email.split('@').last;

      final collegeQuery =
          await _firestore
              .collection("colleges")
              .where("domain", isEqualTo: emailDomain)
              .limit(1)
              .get();

      if (collegeQuery.docs.isEmpty) {
        showBottomToast(
          "Your college/university is not registered.\nPlease register first.",
          bg: Colors.red,
        );
        await _googleSignIn.signOut();
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      final collegeDoc = collegeQuery.docs.first;
      final collegeName = collegeDoc.data()['name'] as String;

      if (user != null) {
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? "",
          fullName: user.displayName ?? "",
          collegeName: collegeName,
        );
        await _firestore
            .collection("users")
            .doc(user.uid)
            .set(userModel.toMap(), SetOptions(merge: true));

        showBottomToast("Login successful!", bg: Colors.green);
      }
    } catch (e) {
      showBottomToast("Error: ${e.toString()}", bg: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // The UI is built here
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF1E212A,
      ), // Dark background from leaderboard
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Replaced Icon with a more engaging visual (e.g., your app logo or mascot)
                // Make sure to add an image to your assets folder and pubspec.yaml
                // Image.asset('assets/images/app_logo.png', height: 100),
                const Icon(
                  Icons.school_rounded,
                  size: 90,
                  color: Colors.cyanAccent,
                ),
                const SizedBox(height: 30),

                // Styled Text Widgets with GoogleFonts
                Text(
                  'Welcome to Career Navigator',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your personal GPS for your professional journey.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 60),

                // Styled ElevatedButton
                ElevatedButton(
                  onPressed: _isLoading ? () {} : signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A47A3), // A nice purple
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // You can replace this with a Google icon image if you prefer
                              const Icon(Icons.login, color: Colors.white),
                              const SizedBox(width: 12),
                              Text(
                                'Sign in with College Email',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                ),
                const SizedBox(height: 40),

                // Register button moved to the bottom
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Your college not listed?",
                      style: GoogleFonts.poppins(color: Colors.white54),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterCollegePage(),
                          ),
                        );
                      },
                      child: Text(
                        "Register",
                        style: GoogleFonts.poppins(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
