import 'dart:ui';

import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final IconData icon;
  final VoidCallback? confirmOnPressed;
  final VoidCallback? cancelOnPressed;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmText,
    required this.cancelText,
    required this.icon,
    this.confirmOnPressed,
    this.cancelOnPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Center(
        child: Stack(
          children: [
            // 🟢 Dialog content
            AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: EdgeInsets.all(16),
              content: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400, minWidth: 350),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 65,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    SizedBox(height: 10),

                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 10),
                    Text(
                      content,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black45,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed:
                              cancelOnPressed ??
                              () => Navigator.of(context).pop(false),

                          child: Text(
                            cancelText,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          onPressed:
                              confirmOnPressed ??
                              () => Navigator.of(context).pop(true),
                          child: Text(
                            confirmText,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
