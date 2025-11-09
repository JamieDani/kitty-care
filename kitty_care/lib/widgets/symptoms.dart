import 'package:flutter/material.dart';

class Symptoms extends StatelessWidget {
  final VoidCallback onPressed;
  const Symptoms({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.translucent,
      child: Image.asset(
        'assets/images/Symptom.png',
        height: 90,
        width: 90,
      ),
    );
  }
}
