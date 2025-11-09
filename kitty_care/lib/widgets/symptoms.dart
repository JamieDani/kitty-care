import 'package:flutter/material.dart';

class Symptoms extends StatelessWidget {
  final VoidCallback onPressed;
  const Symptoms({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(95, 250), // moves right and down
      child: GestureDetector(
        onTap: onPressed,
        child: Image.asset(
          'assets/images/Symptom.png',
          height: 90,
          width: 90,
        ),
      ),
    );
  }
}
