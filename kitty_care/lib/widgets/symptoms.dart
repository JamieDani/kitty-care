import 'package:flutter/material.dart';

class Symptoms extends StatelessWidget {
  final VoidCallback onPressed;
  const Symptoms({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('Symptoms'),
    );
  }
}
