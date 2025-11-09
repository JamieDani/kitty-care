import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../gemini_service.dart'; // make sure this exists with your sendMail function
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MailboxDisplay extends StatefulWidget {
  const MailboxDisplay({super.key});

  @override
  State<MailboxDisplay> createState() => MailboxDisplayState();
}

class MailboxDisplayState extends State<MailboxDisplay> {
  List<String> messages = [];
  DateTime? selectedDate;

  final gemini = GeminiService(apiKey: "fake");

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

  //late final GeminiService gemini;

  @override
  void initState() {
    super.initState();
    _loadSelectedDate();
    //final geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    //gemini = GeminiService(apiKey: geminiApiKey);
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

  Future<void> _generateDailyMail(DateTime date, SharedPreferences prefs, String key) async {
    final weekday = DateFormat('EEEE').format(date);
    final randomReminder = (_reminders..shuffle()).first;
    final positivityMessage = await _generatePositivityMessage();
    final sleepMessage = await _generateSleepMessage();

    final generated = [
      "📅 Happy $weekday!",
      randomReminder,
      positivityMessage,
      sleepMessage,
    ];

    await prefs.setStringList(key, generated);
    setState(() => messages = generated);
  }

  Future<void> refreshMail() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'mail_${DateFormat('yyyy-MM-dd').format(selectedDate!)}';
    await prefs.remove(key);
    _loadMailForDate(selectedDate!);
  }

  /// ---------- NEW: Send Mail Flow ----------

  void _openSendMailDialog() {
    final TextEditingController mailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Send Mail"),
        content: TextField(
          controller: mailController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: "Write your message here...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final message = mailController.text.trim();
              if (message.isEmpty) return;
              Navigator.pop(context);
              _sendUserMail(message);
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendUserMail(String message) async {
    // Add placeholder message
    setState(() {
      messages.add("📨 Sending your mail...");
    });

    try {
      var response = await gemini.sendMail(message);
      final reply = response["response"];
      final personaName = response["persona"];

      setState(() {
        messages.removeWhere((m) => m == "📨 Sending your mail...");
        messages.add("✉️ From $personaName: $reply");
      });

      final prefs = await SharedPreferences.getInstance();
      final key = 'mail_${DateFormat('yyyy-MM-dd').format(selectedDate!)}';
      await prefs.setStringList(key, messages);

    } catch (e) {
      setState(() {
        messages.removeWhere((m) => m == "📨 Sending your mail...");
        messages.add("⚠️ Error sending mail: $e");
      });
    }
  }

  /// ---------- BUILD METHOD ----------
  @override
  @override
Widget build(BuildContext context) {
  if (selectedDate == null) {
    return const Center(child: CircularProgressIndicator());
  }

  final formattedDate = DateFormat('MMM d, yyyy').format(selectedDate!);

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '📬 Mail for $formattedDate',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.pinkAccent,
          ),
        ),
        const SizedBox(height: 12),

        // Send Mail Button
        ElevatedButton(
          onPressed: _openSendMailDialog,
          child: const Text("✉️ Send Mail"),
        ),
        const SizedBox(height: 12),

        // Expanded scrollable messages list
        Expanded(
          child: ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final m = messages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Card(
                  color: Colors.pink.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      m,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
}