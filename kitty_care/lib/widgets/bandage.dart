import 'package:flutter/material.dart';

class Bandage extends StatelessWidget {
  final VoidCallback onPressed;
  const Bandage({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.translucent,
      child: Image.asset(
        'assets/images/Bandage.png',
        height: 90,
        width: 90,
      ),
    );
  }
}
