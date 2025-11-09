import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MailboxDisplay extends StatefulWidget {
  const MailboxDisplay({super.key});

  @override
  State<MailboxDisplay> createState() => _MailboxDisplayState();
}

class _MailboxDisplayState extends State<MailboxDisplay> {
  List<String> messages = [];
  DateTime? selectedDate;

  final List<String> _motivationalQuotes = [
    "🌞 Remember: small steps count too.",
    "🌸 You’re doing better than you think.",
    "💪 Take care of your body — it carries you everywhere.",
    "🫶 Be gentle with yourself today.",
    "☀️ Every day is a chance to start fresh.",
    "🌼 Rest is productive, too.",
    "💖 Your feelings are valid, always.",
  ];

  final List<String> _reminders = [
    "💧 Stay hydrated and take a few deep breaths.",
    "🕯 Remember to stretch or rest your eyes today.",
    "🍎 Eat something nourishing — your body deserves it.",
    "🌻 Take a moment to look outside or go for a short walk.",
    "🧸 Tell someone you appreciate them today.",
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedDate();
  }

  Future<void> _loadSelectedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_date');
    DateTime date;

    if (saved != null) {
      date = DateTime.parse(saved);
    } else {
      date = DateTime.now();
      await prefs.setString('saved_date', date.toIso8601String());
    }

    setState(() => selectedDate = date);
    _loadMailForDate(date);
  }

  Future<void> _loadMailForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'mail_${DateFormat('yyyy-MM-dd').format(date)}';
    final existing = prefs.getStringList(key);

    if (existing != null) {
      setState(() => messages = existing);
    } else {
      _generateDailyMail(date, prefs, key);
    }
  }

  /// Creates the sleep summary (for the final message)
  Future<String> _generateSleepMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final bedtime = prefs.getString('bedtime');
    final waketime = prefs.getString('waketime');

    if (bedtime == null || waketime == null || bedtime.isEmpty || waketime.isEmpty) {
      return "💤 No sleep data yet — try logging your sleep tonight!";
    }

    final bedtimeParsed = _parseTime(bedtime);
    final waketimeParsed = _parseTime(waketime);
    Duration sleepDuration = _calculateSleepDuration(bedtimeParsed, waketimeParsed);
    final hours = sleepDuration.inHours;
    final minutes = sleepDuration.inMinutes % 60;

    if (hours < 3 || hours > 12) {
      return "💤 Sleep data seems off — try logging again tonight!";
    } else if (hours < 6) {
      return "😴 You slept ${hours}h ${minutes}m — try to get more rest tonight!";
    } else if (hours < 8) {
      return "🌙 You got ${hours}h ${minutes}m — decent, but aim for 8 hours!";
    } else {
      return "🌟 You slept ${hours}h ${minutes}m — awesome job staying well-rested!";
    }
  }

  /// Creates a positivity reminder (replaces one random message)
  Future<String> _generatePositivityMessage() async {
    final prefs = await SharedPreferences.getInstance();
    double? positivity = prefs.getDouble('positivityScore');

    if (positivity == null) {
      return "💗 Haven’t logged emotions today — check in with yourself when you can.";
    } else if (positivity >= 90) {
      return "🌞 You’re glowing with positivity — your energy is contagious!";
    } else if (positivity >= 70) {
      return "🌼 You’re radiating positivity — keep spreading that good energy!";
    } else if (positivity >= 50) {
      return "🌈 You’re doing alright — a little self-care can brighten your day.";
    } else {
      return "💖 You seem a bit down — take a moment to rest, journal, or reach out to someone you trust.";
    }
  }

  DateTime _parseTime(String timeString) => DateFormat('h:mm a').parse(timeString);

  Duration _calculateSleepDuration(DateTime bedtime, DateTime waketime) {
    if (waketime.isBefore(bedtime)) {
      waketime = waketime.add(const Duration(days: 1));
    }
    return waketime.difference(bedtime);
  }

  Future<void> _generateDailyMail(
      DateTime date, SharedPreferences prefs, String key) async {
    final weekday = DateFormat('EEEE').format(date);
    final randomReminder = (_reminders..shuffle()).first;
    final positivityMessage = await _generatePositivityMessage();
    final sleepMessage = await _generateSleepMessage();

    // 4 daily messages: happy day, reminder, positivity, and sleep insight
    final generated = [
      "📅 Happy $weekday!",
      randomReminder,
      positivityMessage,
      sleepMessage,
    ];

    await prefs.setStringList(key, generated);
    setState(() => messages = generated);
  }

  @override
  Widget build(BuildContext context) {
    if (selectedDate == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final formattedDate = DateFormat('MMM d, yyyy').format(selectedDate!);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '📬 Mail for $formattedDate',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(height: 12),
            ...messages.map((m) => Card(
                  color: Colors.pink.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      m,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final key =
                    'mail_${DateFormat('yyyy-MM-dd').format(selectedDate!)}';
                await prefs.remove(key);
                _loadMailForDate(selectedDate!);
              },
              label: const Text('Refresh Mail'),
            ),
          ],
        ),
      ),
    );
  }
}
