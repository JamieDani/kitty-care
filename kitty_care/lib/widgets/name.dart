import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NameWidget extends StatelessWidget {
  const NameWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Reference to your Firestore document
    final childRef =
        FirebaseFirestore.instance.collection('children').doc('TkzT27YKNhsb8k7ZOKFD');

    return FutureBuilder<DocumentSnapshot>(
      future: childRef.get(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error state
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        // If document exists, display data
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final firstName = data['firstName'] ?? '';
          final lastName = data['lastName'] ?? '';
          return Text(
            '$firstName $lastName',
            style: const TextStyle(fontSize: 24),
          );
        }

        // If no document found
        return const Text('User not found');
      },
    );
  }
}
