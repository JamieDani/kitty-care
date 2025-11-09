import 'package:flutter/material.dart';

class Calendar extends StatelessWidget {
  final VoidCallback onPressed;
  const Calendar({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('Calendar'),
    );
  }
}