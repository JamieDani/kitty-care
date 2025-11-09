import 'package:flutter/material.dart';

class Emotions extends StatelessWidget {
  final VoidCallback onPressed;
  const Emotions({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.translucent,
      child: Image.asset(
        'assets/images/Emotion.png',
        height: 90,
        width: 90,
      ),
    );
  }
}
