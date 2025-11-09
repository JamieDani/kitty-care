import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_operations.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  String? _childId;
  bool _isLoading = true;
  final _childCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChildId();
  }

  @override
  void dispose() {
    _childCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadChildId() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get the user document to find their parentId
      final userDoc = await getUserDocument(user.uid);
      final parentId = userDoc?['parentId'] as String?;

      if (parentId != null) {
        // Get the parent document to find their childId
        final parentDoc = await getParentDocument(parentId);
        final childId = parentDoc?['childId'] as String?;

        setState(() {
          _childId = childId;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _submitChildCode() async {
    final childCode = _childCodeController.text.trim();
    
    if (childCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a child code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Get the user's parentId
      final userDoc = await getUserDocument(user.uid);
      final parentId = userDoc?['parentId'] as String?;

      if (parentId == null) {
        throw Exception('Parent ID not found in user document');
      }

      // Verify the child exists
      final childExists = await verifyChildExists(childCode);
      if (!childExists) {
        throw Exception('Invalid child code');
      }

      // Update the parent document with the childId
      await updateParentChildId(parentId, childCode);

      setState(() {
        _childId = childCode;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Child linked successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Home'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_childId != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _childId = null;
                  _childCodeController.clear();
                });
              },
              tooltip: 'Change child',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _childId == null
              ? _buildChildCodeInput()
              : _buildChildLogs(),
    );
  }

  Widget _buildChildCodeInput() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom,
              size: 80,
              color: Colors.purple.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'Connect to Your Child',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter your child\'s code to view their health logs',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _childCodeController,
              decoration: InputDecoration(
                labelText: 'Child Code',
                hintText: 'Enter child code',
                prefixIcon: const Icon(Icons.vpn_key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitChildCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Connect',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildLogs() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchWeeklyRawLogs(_childId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'No logs found for the past 7 days.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
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
    final hoursSleep = (log['hoursSleep'] ?? 0.0) as double;

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
                      widthFactor: (hoursSleep / 12).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getSleepColor(hoursSleep),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${hoursSleep.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getSleepColor(hoursSleep),
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