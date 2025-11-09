import 'package:flutter/material.dart';

class Sleep extends StatelessWidget {
  final VoidCallback onPressed;
  const Sleep({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.translucent,
      child: Image.asset(
        'assets/images/Bed.png',
        height: 90,
        width: 90,
      ),
    );
  }
}
