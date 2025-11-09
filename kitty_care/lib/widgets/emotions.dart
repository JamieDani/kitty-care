import 'package:flutter/material.dart';

class Emotions extends StatelessWidget {
  final VoidCallback onPressed;
  const Emotions({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-200, 360), // moves the image left and down
      child: GestureDetector(
        onTap: onPressed,
        child: Image.asset(
          'assets/images/Emotion.png',
          height: 90,
          width: 90,
        ),
      ),
    );
  }
}
