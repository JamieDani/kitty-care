import 'package:flutter/material.dart';

class Calendar extends StatelessWidget {
  final VoidCallback onPressed;
  const Calendar({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Transform.translate(
        offset: const Offset(45, -280), // ← X = left, Y = up
        child: Image.asset(
          'assets/images/strawberry_calendar.png',
          height: 100,
          width: 100,
        ),
      ),
    );
  }
}