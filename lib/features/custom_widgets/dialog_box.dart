import 'dart:ui';

import 'package:flutter/material.dart';

class DialogBox extends StatelessWidget {
  final Widget child;
  final String confirmText;
  final String cancelText;
  final VoidCallback? confirmOnPressed;
  final VoidCallback? cancelOnPressed;

  const DialogBox({
    super.key,
    required this.child,
    required this.confirmText,
    required this.cancelText,
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
                    child,
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
