import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../firebase_operations.dart';

class BandageDisplay extends StatefulWidget {
  const BandageDisplay({super.key});

  @override
  State<BandageDisplay> createState() => _BandageDisplayState();
}

class _BandageDisplayState extends State<BandageDisplay> {
  DateTime? lastPadChange;
  Timer? timer;
  String timeSinceChange = "";

  @override
  void initState() {
    super.initState();
    _loadLastChange();
    timer = Timer.periodic(const Duration(minutes: 1), (_) => _updateElapsed());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLastChange() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('lastPadChange');
    if (saved != null) {
      setState(() {
        lastPadChange = DateTime.parse(saved);
      });
      _updateElapsed();
    }
  }

  Future<void> _saveNewChange() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('lastPadChange', now.toIso8601String());

    // Track history (optional)
    final history = prefs.getStringList('padChangeHistory') ?? [];
    history.add(now.toIso8601String());
    await prefs.setStringList('padChangeHistory', history);

    setState(() {
      lastPadChange = now;
      timeSinceChange = "Just now 🩷";
    });

    // Log to Firebase
    await _logPadChangeToFirebase(now);
  }

  Future<void> _logPadChangeToFirebase(DateTime timestamp) async {
    try {
      // Call Firebase function with the timestamp
      await logPadChange(timestamp.toIso8601String());

      print('✅ Pad change logged to Firebase: ${timestamp.toIso8601String()}');
    } catch (e) {
      print('❌ Error logging pad change to Firebase: $e');
    }
  }

  void _updateElapsed() {
    if (lastPadChange == null) return;
    final diff = DateTime.now().difference(lastPadChange!);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    String msg;
    if (hours == 0 && minutes < 5) {
      msg = "Just now 🩷";
    } else if (hours < 1) {
      msg = "$minutes min ago";
    } else {
      msg = "${hours}h ${minutes}m ago";
    }

    setState(() {
      timeSinceChange = msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatted = lastPadChange != null
        ? DateFormat('h:mm a').format(lastPadChange!)
        : "No record yet";

    final needsReminder = lastPadChange != null &&
        DateTime.now().difference(lastPadChange!).inHours >= 5;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        const Text(
          '🩹 Pad Change Tracker',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Last changed: $formatted',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          'Time since change: $timeSinceChange',
          style: TextStyle(
            fontSize: 16,
            color: needsReminder ? Colors.redAccent : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.healing),
          label: const Text("I changed my pad!"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: _saveNewChange,
        ),
        if (needsReminder)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              "⏰ It’s been a while — consider changing your pad soon!",
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}