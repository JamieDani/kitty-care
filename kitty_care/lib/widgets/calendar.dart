import 'package:flutter/material.dart';

class Calendar extends StatelessWidget {
  final VoidCallback onPressed;
  const Calendar({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.translucent, // ensures taps register
      child: Image.asset(
        'assets/images/strawberry_calendar.png',
        height: 100,
        width: 100,
      ),
    );
  }
}