import 'package:flutter/material.dart';

class Bandage extends StatelessWidget {
  final VoidCallback onPressed;
  const Bandage({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('Bandage'),
    );
  }
}
