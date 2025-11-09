import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _selectRole(BuildContext context, String role) async {
    final user = FirebaseAuth.instance.currentUser!;
    final db = FirebaseFirestore.instance;

    // Create either a parent or child document
    final roleCollection = role == 'parent' ? 'parents' : 'children';

    final roleData = {
      'linkedUserId': user.uid,
      'email': user.email,
      'name': user.displayName,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Add periodLength if child
    if (role == 'child') {
      roleData['periodLength'] = 5;
    }

    final roleDoc = await db.collection(roleCollection).add(roleData);

    // Create user document linking back
    await db.collection('users').doc(user.uid).set({
      'role': role,
      if (role == 'parent') 'parentId': roleDoc.id,
      if (role == 'child') 'childId': roleDoc.id,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Optionally navigate to correct home screen
    if (role == 'parent') {
      Navigator.pushReplacementNamed(context, '/parentHome');
    } else {
      Navigator.pushReplacementNamed(context, '/childHome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Who are you?')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Are you a parent or a child?', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _selectRole(context, 'parent'),
              child: const Text('I am a Parent'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectRole(context, 'child'),
              child: const Text('I am a Child'),
            ),
          ],
        ),
      ),
    );
  }
}
