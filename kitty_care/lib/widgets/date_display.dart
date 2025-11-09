import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DateDisplay extends StatefulWidget {
  const DateDisplay({super.key});

  @override
  State<DateDisplay> createState() => _DateDisplayState();
}

class _DateDisplayState extends State<DateDisplay> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _focusedMonth;
  Set<String> _periodDates = {}; // Store period dates as 'yyyy-MM-dd' strings

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _loadSavedDate();
    _loadPeriodDates();
  }

  Future<void> _loadSavedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_date');
    if (saved != null) {
      final parsed = DateTime.parse(saved);
      setState(() {
        _selectedDate = parsed;
        _focusedMonth = DateTime(parsed.year, parsed.month);
      });
    }
  }

  Future<void> _saveDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_date', _selectedDate.toIso8601String());
  }

  Future<void> _loadPeriodDates() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPeriods = prefs.getStringList('period_dates') ?? [];
    setState(() {
      _periodDates = savedPeriods.toSet();
    });
  }

  Future<void> _savePeriodDates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('period_dates', _periodDates.toList());
  }

  void _togglePeriodDate(DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    setState(() {
      if (_periodDates.contains(dateString)) {
        _periodDates.remove(dateString);
      } else {
        _periodDates.add(dateString);
      }
    });
    _savePeriodDates();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  List<Widget> _buildCalendarDays() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday; // Monday=1 ... Sunday=7

    final List<Widget> dayWidgets = [];

    // Add empty boxes for days before the first day
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(Container());
    }

    // Add actual day boxes
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final isSelected = dateString == DateFormat('yyyy-MM-dd').format(_selectedDate);
      final isToday = dateString == DateFormat('yyyy-MM-dd').format(DateTime.now());
      final isPeriodDay = _periodDates.contains(dateString);

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            _togglePeriodDate(date);
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPeriodDay
                  ? Colors.red.shade300
                  : isSelected
                      ? Colors.pinkAccent
                      : isToday
                          ? Colors.pink.shade100
                          : Colors.transparent,
              border: isPeriodDay && isSelected
                  ? Border.all(color: Colors.pinkAccent, width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isPeriodDay
                    ? Colors.white
                    : isSelected
                        ? Colors.white
                        : isToday
                            ? Colors.pinkAccent
                            : Colors.black87,
              ),
            ),
          ),
        ),
      );
    }

    return dayWidgets;
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(_focusedMonth);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousMonth,
            ),
            Text(
              monthLabel,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _nextMonth,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Weekday labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Text('Mon', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Tue', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Wed', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Thu', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Fri', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Sat', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Sun', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),

        // Month grid
        SizedBox(
          height: 280, // ✅ gives the GridView real height
          child: GridView.count(
            crossAxisCount: 7,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            physics: const NeverScrollableScrollPhysics(),
            children: _buildCalendarDays(),
          ),
        ),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_downward, size: 20),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                });
                _saveDate();
              },
              tooltip: 'Previous day',
            ),
            Text(
              "Selected: ${DateFormat('MMM d, yyyy').format(_selectedDate)}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_upward, size: 20),
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                });
                _saveDate();
              },
              tooltip: 'Next day',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Click a day to mark/unmark period",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
