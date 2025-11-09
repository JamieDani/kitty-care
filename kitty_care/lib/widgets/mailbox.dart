import 'package:flutter/material.dart';

class Mailbox extends StatelessWidget {
  final VoidCallback onPressed;
  const Mailbox({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 360), // moves slightly left and down
      child: GestureDetector(
        onTap: onPressed, // ensures your dialog still opens
        child: Image.asset(
          'assets/images/Mail.png',
          height: 90,
          width: 90,
        ),
      ),
    );
  }
}
