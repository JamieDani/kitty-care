import 'package:flutter/material.dart';

class Mailbox extends StatelessWidget {
  final VoidCallback onPressed;
  const Mailbox({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('Mailbox'),
    );
  }
}
