import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';
import '../models/seasons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


final db = FirebaseFirestore.instance;

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((event) {
      setState(() {
        _user = event;
      });
    });
  }

  Season currentSeason = Season.winter;

  void cycleSeason() {
    setState(() {
      currentSeason = Season.values[
        (currentSeason.index + 1) % Season.values.length
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kitty Care - Sign In')),
      body: _user != null ? _userInfo() : _googleSignInButton(),
    );
  }

  Widget _googleSignInButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: SignInButton(
            Buttons.google,
            text: "Sign up with Google",
            onPressed: _handleGoogleSignIn,
          ),
        ),
      ),
    );
  }

  Widget _userInfo() {
    return const Center(
      child: Text('Signed in! 🎉'),
    );
  }

  void _handleGoogleSignIn() {
    try {
      GoogleAuthProvider googleAuthProvider = GoogleAuthProvider();
      _auth.signInWithProvider(googleAuthProvider);
    } catch(error) {
      //error
    }
  }
}