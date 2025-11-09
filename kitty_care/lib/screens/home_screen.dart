import 'package:flutter/material.dart';
import '../models/seasons.dart';
import '../widgets/calendar.dart';
import '../widgets/mailbox.dart';
import '../widgets/emotions.dart';
import '../widgets/sleep.dart';
import '../widgets/bandage.dart';
import '../widgets/symptoms.dart';
import '../widgets/date_display.dart';
import '../widgets/sleep_display.dart';
import '../widgets/emotions_display.dart';
import '../widgets/mailbox_display.dart';
import '../widgets/bandage_display.dart';
import '../widgets/symptoms_display.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_operations.dart';
import '../util.dart';
import 'package:intl/intl.dart';
import '../widgets/image_analyzer.dart';
import '../gemini_service.dart';

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

  late final GeminiService _geminiService;

  @override
  void initState() {
    super.initState();
    _initSeason();
  }

  Future<void> _initSeason() async {
    final String today = getCurrentLocalDate();
    final String? phase = await getCurrentPhase(today);
    print("📅 Today's date: $today");
    print("🔍 Your current phase: $phase");
    if (phase != null && phaseToSeason.containsKey(phase)) {
      setState(() {
        currentSeason = phaseToSeason[phase]!;
        print("🌸 Season set to: $currentSeason");
      });
    } else {
      print("⚠️ Phase not found or invalid, defaulting to winter");
    }
  }

  String get seasonalImagePath {
    final path = switch (currentSeason) {
      Season.winter => 'assets/images/New_Winter.png',
      Season.spring => 'assets/images/New_Spring.png',
      Season.summer => 'assets/images/New_Summer.png',
      Season.fall => 'assets/images/New_Fall.png',
    };
    print("🖼️ Loading seasonal image: $path for season: $currentSeason");
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background layer
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/MediumBackdrop.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Seasonal layer
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(
                seasonalImagePath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Window overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/NewWindow.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Cat overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/Berrie_Cat_Eyes_Openhappy.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Interactive buttons
          SafeArea(
            child: Stack(
              children: [
                // Calendar Button
                Positioned(
                  right: 260,
                  top: 0,
                  child: Calendar(
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
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: DateDisplay(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Mailbox Button
                Positioned(
                  left: 110,
                  bottom: 0,
                  child: Mailbox(
                    onPressed: () {
                      final GlobalKey<MailboxDisplayState> mailboxKey =
                          GlobalKey<MailboxDisplayState>();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Mailbox'),
                          content: SizedBox(
                            width: 350,
                            height: 480,
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
                ),

                // Emotions Button
                Positioned(
                  right: 300,
                  bottom: 0,
                  child: Emotions(
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
                ),

                // Sleep Button
                Positioned(
                  bottom: 250,
                  left: 320,
                  child: Sleep(
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
                ),

                // Bandage Button
                Positioned(
                  left: 210,
                  top: 635,
                  child: Bandage(
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
                ),

                // Symptoms Button
                Positioned(
                  bottom: 0,
                  left: 300,
                  child: Symptoms(
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
                ),

                // Pad Analyzer
                Positioned(
                  bottom: 100,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('📸 Analyze Pad'),
                          content: SizedBox(
                            width: 350,
                            height: 450,
                            child: ImageAnalyzer(
                              analysisType: 'pad',
                              geminiService: _geminiService,
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
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.pink.shade100,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 32, color: Colors.pink.shade700),
                          const SizedBox(height: 4),
                          Text(
                            'Pad',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.pink.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Food Analyzer
                Positioned(
                  bottom: 200,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('🍎 Analyze Food'),
                          content: SizedBox(
                            width: 350,
                            height: 450,
                            child: ImageAnalyzer(
                              analysisType: 'food',
                              geminiService: _geminiService,
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
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant, size: 32, color: Colors.green.shade700),
                          const SizedBox(height: 4),
                          Text(
                            'Food',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
