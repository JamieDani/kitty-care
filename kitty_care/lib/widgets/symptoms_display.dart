import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SymptomsDisplay extends StatefulWidget {
  const SymptomsDisplay({super.key});

  @override
  State<SymptomsDisplay> createState() => _SymptomsDisplayState();
}

class _SymptomsDisplayState extends State<SymptomsDisplay> {
  // Symptom severity scores (1-5)
  double frontCramps = 1;
  double backCramps = 1;
  double headache = 1;
  double nausea = 1;
  double fatigue = 1;

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  Future<void> _loadSymptoms() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      frontCramps = prefs.getDouble('frontCramps') ?? 1;
      backCramps = prefs.getDouble('backCramps') ?? 1;
      headache = prefs.getDouble('headache') ?? 1;
      nausea = prefs.getDouble('nausea') ?? 1;
      fatigue = prefs.getDouble('fatigue') ?? 1;
    });
  }

  Future<void> _saveSymptoms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('frontCramps', frontCramps);
    await prefs.setDouble('backCramps', backCramps);
    await prefs.setDouble('headache', headache);
    await prefs.setDouble('nausea', nausea);
    await prefs.setDouble('fatigue', fatigue);
  }

  Widget _buildSymptomScale(String symptomName, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Text(
              symptomName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: Colors.pinkAccent,
              onChanged: (newValue) {
                setState(() => onChanged(newValue));
                _saveSymptoms();
              },
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              _getSeverityLabel(value),
              style: const TextStyle(
                fontSize: 26,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getSeverityLabel(double value) {
    switch (value.round()) {
      case 1:
        return '😊'; // None
      case 2:
        return '🙂'; // Mild
      case 3:
        return '😐'; // Moderate
      case 4:
        return '😣'; // Strong
      case 5:
        return '😖'; // Severe
      default:
        return '😊';
    }
  }

  Color _getSeverityColor(double value) {
    if (value <= 1) return Colors.green;
    if (value <= 2) return Colors.lightGreen;
    if (value <= 3) return Colors.orangeAccent;
    if (value <= 4) return Colors.deepOrange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Track Your Symptoms',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Scale: 1 (None) → 5 (Severe)',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 20),
        _buildSymptomScale('Front Cramps', frontCramps, (v) => frontCramps = v),
        const SizedBox(height: 4),
        _buildSymptomScale('Back Cramps', backCramps, (v) => backCramps = v),
        const SizedBox(height: 4),
        _buildSymptomScale('Headache', headache, (v) => headache = v),
        const SizedBox(height: 4),
        _buildSymptomScale('Nausea', nausea, (v) => nausea = v),
        const SizedBox(height: 4),
        _buildSymptomScale('Fatigue', fatigue, (v) => fatigue = v),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.pinkAccent, width: 2),
          ),
          child: const Text(
            '💗 Track symptoms daily to better understand your cycle',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
