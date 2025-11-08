import 'package:flutter/material.dart';

class Sleep extends StatelessWidget {
  final VoidCallback onPressed;
  const Sleep({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('Sleep'),
    );
  }
}
