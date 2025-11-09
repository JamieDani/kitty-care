import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../firebase_operations.dart';

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Home'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchWeeklyRawLogs("TkzT27YKNhsb8k7ZOKFD"),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No logs found for the past 7 days.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final logs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return DailyLogCard(log: log);
            },
          );
        },
      ),
    );
  }
}

class DailyLogCard extends StatelessWidget {
  final Map<String, dynamic> log;

  const DailyLogCard({super.key, required this.log});

  String _formatDate(String dateStr) {
    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
      return DateFormat('EEEE, MMM d').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getSleepColor(double hours) {
    if (hours >= 7 && hours <= 9) {
      return Colors.green;
    } else if (hours >= 6 && hours < 7 || hours > 9 && hours <= 10) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = log['date'] ?? 'Unknown date';
    final phase = log['phase'] ?? 'Unknown phase';
    final hoursSlept = (log['hoursSlept'] ?? 0.0) as double;

    final physical = log['physicalSymptoms'] as Map<String, dynamic>;
    final emotional = log['emotionalSymptoms'] as Map<String, dynamic>;
    final padChanges = log['padChanges'] as List;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    phase,
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sleep Section
            const Text(
              'Sleep',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (hoursSlept / 12).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getSleepColor(hoursSlept),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${hoursSlept.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getSleepColor(hoursSlept),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Physical Symptoms
            const Text(
              'Physical Symptoms',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            SymptomBarChart(
              symptoms: physical,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 20),

            // Emotional Symptoms
            const Text(
              'Emotional State',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            SymptomBarChart(
              symptoms: emotional,
              color: Colors.blue.shade400,
            ),
            const SizedBox(height: 20),

            // Pad Changes
            const Text(
              'Pad Changes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            if (padChanges.isEmpty)
              Text(
                'None logged',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ...padChanges.map((change) {
                String formattedTime = change.toString();
                try {
                  final time = DateFormat('HH:mm:ss').parse(change.toString());
                  formattedTime = DateFormat('h:mm a').format(time);
                } catch (e) {
                  // Keep original if parsing fails
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        formattedTime,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

class SymptomBarChart extends StatelessWidget {
  final Map<String, dynamic> symptoms;
  final Color color;

  const SymptomBarChart({
    super.key,
    required this.symptoms,
    required this.color,
  });

  String _formatLabel(String key) {
    // Convert camelCase to Title Case
    final result = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    return result[0].toUpperCase() + result.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final sortedEntries = symptoms.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    final nonZeroEntries = sortedEntries.where((entry) => (entry.value as num).toDouble() > 0).toList();

    if (nonZeroEntries.isEmpty) {
      return Text(
        'None reported',
        style: TextStyle(color: Colors.grey.shade600),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: nonZeroEntries.map((entry) {
        final value = (entry.value as num).toDouble();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatLabel(entry.key),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (value / 10).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}