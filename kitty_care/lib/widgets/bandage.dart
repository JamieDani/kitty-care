import 'package:flutter/material.dart';

class Bandage extends StatelessWidget {
  final VoidCallback onPressed;
  const Bandage({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Transform.translate(
        offset: const Offset(105, 250), // ← moves it right and up
        child: Image.asset(
          'assets/images/Bandage.png',
          height: 90,
          width: 90,
        ),
      ),
    );
  }
}