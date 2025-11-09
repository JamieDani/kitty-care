import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/parent_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/role_selection.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitty Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
      home: const AuthGate(),
      routes: {
        '/parentHome': (_) => const ParentHomeScreen(),
        '/childHome': (_) => const HomeScreen(),
      },
    );
  }
}


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userDocSnap) {
              if (userDocSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (!userDocSnap.hasData || !userDocSnap.data!.exists) {
                // No document → first-time user → show role selection
                return const RoleSelectionScreen();
              }

              final data = userDocSnap.data!.data() as Map<String, dynamic>;
              if (data['parentId'] != null) {
                return const ParentHomeScreen();
              } else if (data['childId'] != null) {
                return const HomeScreen();
              } else {
                return const RoleSelectionScreen();
              }
            },
          );
        }

        return const SignIn();
      },
    );
  }
}
