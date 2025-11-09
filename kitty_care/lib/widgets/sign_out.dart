import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignOutButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool showIcon;

  const SignOutButton({
    super.key,
    this.text = 'Sign Out',
    this.icon = Icons.logout,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _handleSignOut(context),
      child: showIcon
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(text),
              ],
            )
          : Text(text),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      // Sign out from Google Sign-In first
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      
      // Then sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out successfully')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $error')),
        );
      }
    }
  }
}