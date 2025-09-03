import 'package:careerclaritycompanion/features/screens/chat_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GuidanceCard extends StatelessWidget {
  const GuidanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final String prompt = 'Give me personalized career guidance';
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Image.network(
            'https://res.cloudinary.com/dui67nlwb/image/upload/v1756750571/guidance_image_xuczfm.png',
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => ChatScreen(initialPrompt: prompt),
                    ),
                  ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  color: Colors.black38,
                ),
                child: Row(
                  children: [
                    Text(
                      'Ask Rufi',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 25),
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
