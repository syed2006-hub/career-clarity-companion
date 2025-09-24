import 'dart:math'; // ✨ Required for sin/cos in animation
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

// ✨ Add 'SingleTickerProviderStateMixin' to host the animation controller
class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;

  // ✨ 1. Animation controller and blobs for the background
  late AnimationController _animationController;
  late List<Blob> _blobs;

  @override
  void initState() {
    super.initState();
    // ✨ 2. Initialize the animation controller and blobs (same as home screen)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _blobs = [
      Blob(
        initialRadius: 220,
        initialX: 0.1,
        initialY: 0.1,
        speed: 1.2,
        color: const Color(0xFF42382D).withOpacity(0.7),
      ),
      Blob(
        initialRadius: 280,
        initialX: 0.9,
        initialY: 0.8,
        speed: 0.8,
        color: const Color(0xFF42382D).withOpacity(0.5),
      ),
      Blob(
        initialRadius: 150,
        initialX: 0.2,
        initialY: 0.7,
        speed: 1.0,
        color: const Color(0xFF42382D).withOpacity(0.6),
      ),
    ];
  }

  @override
  void dispose() {
    // ✨ 3. Dispose the controller to prevent memory leaks
    _animationController.dispose();
    super.dispose();
  }

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
      final emailPrefix = email.split('@').first;
      final emailDomain = email.split('@').last;

      // ✅ Check that prefix is fully numeric for students
      final isFullyNumeric = RegExp(r'^\d+$').hasMatch(emailPrefix);
      if (!isFullyNumeric) {
        showBottomToast(
          "Student email must be numeric before '@'.",
          bg: Colors.red,
        );
        await _googleSignIn.signOut();
        setState(() => _isLoading = false);
        return;
      }

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
      body: Stack(
        children: [
          // ✨ 4. The new Jelly background
          JellyBackground(controller: _animationController, blobs: _blobs),

          // ✨ 5. Your existing UI content, now placed on top of the background
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      size: 90,
                      color: Colors.cyanAccent,
                    ),
                    const SizedBox(height: 30),
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
                    ElevatedButton(
                      onPressed: _isLoading ? () {} : signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        // A nice purple
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

// ✨ --- JELLY BACKGROUND WIDGETS --- ✨
// (Copied from the home page file)

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
    final double newX =
        initialX + sin(animationValue * speed) * (screenSize.width * 0.2);
    final double newY =
        initialY + cos(animationValue * speed) * (screenSize.height * 0.2);
    position = Offset(newX, newY);
    radius = initialRadius + sin(animationValue * speed * 0.8) * 15;
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
        color: Color(0xFF1E1E1E), // Dark background color
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
