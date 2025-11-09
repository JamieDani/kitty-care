import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../firebase_operations.dart';

class MailboxDisplay extends StatefulWidget {
  const MailboxDisplay({super.key});

  @override
  State<MailboxDisplay> createState() => MailboxDisplayState();
}

class MailboxDisplayState extends State<MailboxDisplay> {
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
      return "💗 Haven't logged emotions today — check in with yourself when you can.";
    } else if (positivity >= 90) {
      return "🌞 You're glowing with positivity — your energy is contagious!";
    } else if (positivity >= 70) {
      return "🌼 You're radiating positivity — keep spreading that good energy!";
    } else if (positivity >= 50) {
      return "🌈 You're doing alright — a little self-care can brighten your day.";
    } else {
      return "💖 You seem a bit down — take a moment to rest, journal, or reach out to someone you trust.";
    }
  }

  /// Creates a period reminder if period is approaching soon
  Future<String?> _generatePeriodReminder() async {
    try {
      final days = await _calculateDaysToPeriod(selectedDate!);
      if (days == null) return null; // No period data available

      if (days < 5 && days > 0) {
        return "🩸 Your period is expected in $days day${days == 1 ? '' : 's'} — make sure you're prepared!";
      } else if (days == 0) {
        return "🩸 Your period is expected today — take care of yourself!";
      }
      return null; // No reminder needed
    } catch (e) {
      print('Error getting days to period: $e');
      return null;
    }
  }

  /// Calculate days until next period based on local calendar data
  Future<int?> _calculateDaysToPeriod(DateTime referenceDate) async {
    final prefs = await SharedPreferences.getInstance();
    final periodDates = prefs.getStringList('period_dates') ?? [];

    if (periodDates.isEmpty) return null; // No period data

    final DateFormat format = DateFormat('yyyy-MM-dd');
    final DateTime today = referenceDate;

    // Parse all period dates and sort them
    final List<DateTime> periodDatesParsed = periodDates
        .map((dateStr) => format.parse(dateStr))
        .toList()
      ..sort();

    // Find distinct periods (gaps of more than 2 days indicate separate periods)
    List<List<DateTime>> periods = [];
    List<DateTime> currentPeriod = [periodDatesParsed[0]];

    for (int i = 1; i < periodDatesParsed.length; i++) {
      final gap = periodDatesParsed[i].difference(periodDatesParsed[i - 1]).inDays;
      if (gap > 2) {
        // New period started
        periods.add(List.from(currentPeriod));
        currentPeriod = [periodDatesParsed[i]];
      } else {
        currentPeriod.add(periodDatesParsed[i]);
      }
    }
    periods.add(currentPeriod); // Add the last period

    print('📅 Found ${periods.length} distinct period(s)');

    // Find the most recent COMPLETE period (not currently ongoing)
    List<DateTime>? lastCompletePeriod;
    for (int i = periods.length - 1; i >= 0; i--) {
      final periodEnd = periods[i].last;
      // A period is complete if its last day is at least 3 days ago
      if (today.difference(periodEnd).inDays >= 3) {
        lastCompletePeriod = periods[i];
        break;
      }
    }

    // If no complete period, check if we're currently in a period
    if (lastCompletePeriod == null) {
      // Check if today or yesterday is marked as a period day
      final String todayStr = format.format(today);
      final String yesterdayStr = format.format(today.subtract(const Duration(days: 1)));

      if (periodDates.contains(todayStr) || periodDates.contains(yesterdayStr)) {
        // Currently in period
        return 0;
      }

      // Use the most recent period even if not complete
      if (periods.isNotEmpty) {
        lastCompletePeriod = periods.last;
      } else {
        return null;
      }
    }

    final DateTime lastPeriodStart = lastCompletePeriod.first;
    final int periodLength = lastCompletePeriod.length;

    // Calculate average cycle length if we have at least 2 complete periods
    int cycleLength = 28; // Default
    if (periods.length >= 2) {
      int totalDays = 0;
      int cycleCount = 0;

      for (int i = 1; i < periods.length; i++) {
        // Only count if both periods are complete
        final prevPeriodEnd = periods[i - 1].last;
        final currentPeriodStart = periods[i].first;

        if (today.difference(prevPeriodEnd).inDays >= 3 || i < periods.length - 1) {
          totalDays += currentPeriodStart.difference(periods[i - 1].first).inDays;
          cycleCount++;
        }
      }

      if (cycleCount > 0) {
        cycleLength = (totalDays / cycleCount).round();
      }
    }

    // Calculate next period start
    DateTime nextPeriodStart = lastPeriodStart.add(Duration(days: cycleLength));
    int daysUntilPeriod = nextPeriodStart.difference(today).inDays;

    // If the predicted period has passed, keep adding cycles until we find the next one
    while (daysUntilPeriod < 0) {
      nextPeriodStart = nextPeriodStart.add(Duration(days: cycleLength));
      daysUntilPeriod = nextPeriodStart.difference(today).inDays;
    }

    print('📅 Last period start: ${format.format(lastPeriodStart)}');
    print('📅 Last period end: ${format.format(lastCompletePeriod.last)}');
    print('📅 Period length: $periodLength days');
    print('📅 Average cycle length: $cycleLength days');
    print('📅 Next period expected: ${format.format(nextPeriodStart)}');
    print('📅 Days until next period: $daysUntilPeriod');

    return daysUntilPeriod;
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
    final periodReminder = await _generatePeriodReminder();

    // Start with base messages
    final generated = [
      "📅 Happy $weekday!",
      randomReminder,
      positivityMessage,
      sleepMessage,
    ];

    // Add period reminder if approaching (< 5 days)
    if (periodReminder != null) {
      generated.insert(1, periodReminder); // Insert after "Happy [day]"
    }

    await prefs.setStringList(key, generated);
    setState(() => messages = generated);
  }

  Future<void> refreshMail() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'mail_${DateFormat('yyyy-MM-dd').format(selectedDate!)}';
    await prefs.remove(key);
    _loadMailForDate(selectedDate!);
  }

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
        mainAxisSize: MainAxisSize.min,
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

          // Display messages with proper spacing
          ...messages.map((m) => Padding(
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
              )),
        ],
      ),
    );
  }
}
