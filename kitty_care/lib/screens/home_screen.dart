import 'package:flutter/material.dart';
import '../models/seasons.dart';
import '../widgets/calendar.dart';
import '../widgets/mailbox.dart';
import '../widgets/emotions.dart';
import '../widgets/sleep.dart';
import '../widgets/bandage.dart';
import '../widgets/window.dart';
import '../widgets/symptoms.dart';
import '../widgets/date_display.dart';
import '../widgets/sleep_display.dart';
import '../widgets/emotions_display.dart';
import '../widgets/mailbox_display.dart';
import '../widgets/bandage_display.dart';
import '../widgets/symptoms_display.dart';
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
                Calendar(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        insetPadding: const EdgeInsets.all(20),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 340,
                            maxHeight: 500,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: const DateDisplay(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Mailbox(
                  onPressed: () {
                    final GlobalKey<MailboxDisplayState> mailboxKey = GlobalKey<MailboxDisplayState>();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Mailbox'),
                        content: SizedBox(
                          width: 350,
                          height: 420,
                          child: MailboxDisplay(key: mailboxKey),
                        ),
                        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                                onPressed: () {
                                  mailboxKey.currentState?.refreshMail();
                                },
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Emotions(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Emotions Tracker'),
                        content: SizedBox(
                          width: 350,
                          height: 580,
                          child: const EmotionsDisplay(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Sleep(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sleep Tracker'),
                        content: SizedBox(
                          width: 350,
                          height: 400,
                          child: SingleChildScrollView(
                            child: const SleepDisplay(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Bandage(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Bandage Tracker'),
                        content: SizedBox(
                          width: 350,
                          height: 400,
                          child: SingleChildScrollView(
                            child: const BandageDisplay(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Symptoms(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Symptom Tracker'),
                        content: SizedBox(
                          width: 350,
                          height: 520,
                          child: const SymptomsDisplay(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}