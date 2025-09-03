// lib/features/common_widgets/loading_display.dart
import 'package:flutter/material.dart';

class LoadingDisplay extends StatelessWidget {
  final String message;
  const LoadingDisplay({super.key, this.message = "Loading..."});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}