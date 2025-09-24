import 'package:careerclaritycompanion/main.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;
  bool _navigated = false; // Prevent multiple pushes

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset("assets/sample.mp4")
      ..initialize().then((_) {
        setState(() {}); // Refresh UI after initialization
        _controller.play();

        // Add listener only after initialization
        _controller.addListener(() {
          // Check if video has finished playing
          if (_controller.value.isInitialized &&
              !_navigated &&
              _controller.value.position >= _controller.value.duration) {
            _navigated = true;
            _goToNextPage();
          }
        });
      });
  }

  // ✨ THIS IS THE MODIFIED NAVIGATION METHOD
  void _goToNextPage() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        // The page we are navigating to
        pageBuilder:
            (context, animation, secondaryAnimation) => const AuthGate(),

        // Define the duration of the transition
        transitionDuration: const Duration(milliseconds: 800),

        // Build the custom transition
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Animate from top to bottom (Y-axis from -1.0 to 0.0)
          const begin = Offset(0.0, -1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          final slideAnimation = animation.drive(tween);

          // Combine the slide with a fade transition
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white, // A black background looks better during init
      body:
          _controller.value.isInitialized
              ? Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
              : const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
    );
  }
}
