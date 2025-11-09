import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../firebase_operations.dart';

class SleepDisplay extends StatefulWidget {
  const SleepDisplay({super.key});

  @override
  State<SleepDisplay> createState() => _SleepDisplayState();
}

class _SleepDisplayState extends State<SleepDisplay> {
  String? _bedtime;
  String? _wakeTime;
  Duration? _sleepDuration;

  final List<String> _times = [
    '7:30 PM', '8:00 PM', '8:30 PM', '9:00 PM', '9:30 PM', '10:00 PM',
    '10:30 PM', '11:00 PM', '11:30 PM', '12:00 AM', '12:30 AM', '1:00 AM',
    '1:30 AM', '2:00 AM', '2:30 AM', '3:00 AM', '3:30 AM', '4:00 AM',
    '4:30 AM', '5:00 AM', '5:30 AM', '6:00 AM', '6:30 AM', '7:00 AM',
    '7:30 AM', '8:00 AM', '8:30 AM', '9:00 AM', '9:30 AM', '10:00 AM',
    '10:30 AM', '11:00 AM', '11:30 AM', '12:00 PM'
  ];

  @override
  void initState() {
    super.initState();
    _loadSleepTimes();
  }

  Future<void> _loadSleepTimes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bedtime = prefs.getString('bedtime');
      _wakeTime = prefs.getString('waketime');
    });
    _calculateSleepDuration();
  }

  Future<void> _saveSleepTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bedtime', _bedtime ?? '');
    await prefs.setString('waketime', _wakeTime ?? '');

    // Log to Firebase
    await _logSleepToFirebase();
  }

  Future<void> _logSleepToFirebase() async {
    try {
      // Only log if we have both times and a valid duration
      if (_sleepDuration == null || _bedtime == null || _wakeTime == null) {
        return;
      }

      // Convert duration to hours (with decimals)
      final double hours = _sleepDuration!.inMinutes / 60.0;

      // Get the selected date from SharedPreferences (same as calendar)
      final prefs = await SharedPreferences.getInstance();
      final savedDateStr = prefs.getString('saved_date');
      final DateTime selectedDate = savedDateStr != null
          ? DateTime.parse(savedDateStr)
          : DateTime.now();
      final String dateString = DateFormat('yyyy-MM-dd').format(selectedDate);

      // Call Firebase function
      await logSleep(hours, dateString);

      print('✅ Sleep logged to Firebase for $dateString: ${hours.toStringAsFixed(1)} hours');
    } catch (e) {
      print('❌ Error logging sleep to Firebase: $e');
    }
  }

  void _calculateSleepDuration() {
    if (_bedtime == null || _wakeTime == null) return;

    final format = DateFormat('h:mm a');
    DateTime bed = format.parse(_bedtime!);
    DateTime wake = format.parse(_wakeTime!);

    // Handle overnight (wake up next day)
    if (wake.isBefore(bed)) {
      wake = wake.add(const Duration(days: 1));
    }

    final diff = wake.difference(bed);
    setState(() {
      _sleepDuration = diff;
    });
  }

  void _updateBedtime(String? value) {
    setState(() => _bedtime = value);
    _calculateSleepDuration();
    _saveSleepTimes();
  }

  void _updateWakeTime(String? value) {
    setState(() => _wakeTime = value);
    _calculateSleepDuration();
    _saveSleepTimes();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours} hr${hours == 1 ? '' : 's'} ${minutes > 0 ? '$minutes min' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        const Text(
          'Record Your Sleep',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text('Went to Bed'),
                DropdownButton<String>(
                  value: _bedtime,
                  hint: const Text('Select'),
                  items: _times.map((time) {
                    return DropdownMenuItem(value: time, child: Text(time));
                  }).toList(),
                  onChanged: _updateBedtime,
                ),
              ],
            ),
            Column(
              children: [
                const Text('Woke Up'),
                DropdownButton<String>(
                  value: _wakeTime,
                  hint: const Text('Select'),
                  items: _times.map((time) {
                    return DropdownMenuItem(value: time, child: Text(time));
                  }).toList(),
                  onChanged: _updateWakeTime,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_bedtime != null && _wakeTime != null)
          Column(
            children: [
              Text(
                'You slept from $_bedtime to $_wakeTime',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              if (_sleepDuration != null)
                Text(
                  'Total sleep: ${_formatDuration(_sleepDuration!)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}