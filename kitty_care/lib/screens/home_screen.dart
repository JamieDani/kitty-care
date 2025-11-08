import 'package:flutter/material.dart';
import '../models/seasons.dart';
import '../widgets/calendar.dart';
import '../widgets/mailbox.dart';
import '../widgets/emotions.dart';
import '../widgets/sleep.dart';
import '../widgets/bandage.dart';
import '../widgets/window.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/name.dart'; // wherever you saved it


final db = FirebaseFirestore.instance;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      appBar: AppBar(title: const Text('Wellness App Prototype')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NameWidget(),
            WindowDisplay(currentSeason: currentSeason),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                Calendar(onPressed: () {}),
                Mailbox(onPressed: () {}),
                Emotions(onPressed: () {}),
                Sleep(onPressed: () {}),
                Bandage(onPressed: cycleSeason),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
