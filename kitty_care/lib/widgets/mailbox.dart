import 'package:flutter/material.dart';

class Mailbox extends StatelessWidget {
  final VoidCallback onPressed;
  const Mailbox({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.translucent,
      child: Image.asset(
        'assets/images/Mail.png',
        height: 90,
        width: 90,
      ),
    );
  }
}
