import 'package:flutter/material.dart';

class Emotions extends StatelessWidget {
  final VoidCallback onPressed;
  const Emotions({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('Emotions'),
    );
  }
}
