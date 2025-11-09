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
import '../firebase_operations.dart';
import '../util.dart';
import 'package:intl/intl.dart';


final db = FirebaseFirestore.instance;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
    Season currentSeason = Season.winter;
  
  final Map<String, Season> phaseToSeason = {
    'period': Season.winter,
    'follicular': Season.spring,
    'ovulation': Season.summer,
    'luteal': Season.fall,
  };

  @override
  void initState() {
    super.initState();
    _initSeason();
  }

  Future<void> _initSeason() async {
    final String today = getCurrentLocalDate();
    final String? phase = await getCurrentPhase(today);
    print("Your current phase: $phase");
    if (phase != null && phaseToSeason.containsKey(phase)) {
      setState(() {
        currentSeason = phaseToSeason[phase]!;
      });
    }
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
