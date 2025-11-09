import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmotionsDisplay extends StatefulWidget {
  const EmotionsDisplay({super.key});

  @override
  State<EmotionsDisplay> createState() => _EmotionsDisplayState();
}

class _EmotionsDisplayState extends State<EmotionsDisplay> {
  // Emotion scores (0–100)
  double sadHappy = 50;
  double tiredEnergetic = 50;
  double hungryFull = 50;
  double worriedCalm = 50;
  double angryKind = 50;

  double positivityScore = 50; // Overall positivity (average of sliders)

  @override
  void initState() {
    super.initState();
    _loadEmotions();
  }

  Future<void> _loadEmotions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      sadHappy = prefs.getDouble('sadHappy') ?? 50;
      tiredEnergetic = prefs.getDouble('tiredEnergetic') ?? 50;
      hungryFull = prefs.getDouble('hungryFull') ?? 50;
      worriedCalm = prefs.getDouble('worriedCalm') ?? 50;
      angryKind = prefs.getDouble('angryKind') ?? 50;
    });
    _updatePositivity();
  }

  Future<void> _saveEmotions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sadHappy', sadHappy);
    await prefs.setDouble('tiredEnergetic', tiredEnergetic);
    await prefs.setDouble('hungryFull', hungryFull);
    await prefs.setDouble('worriedCalm', worriedCalm);
    await prefs.setDouble('angryKind', angryKind);
    await prefs.setDouble('positivityScore', positivityScore);
  }

  void _updatePositivity() {
    final avg = (sadHappy +
            tiredEnergetic +
            hungryFull +
            worriedCalm +
            angryKind) /
        5;
    setState(() => positivityScore = avg);
    _saveEmotions();
  }

  Widget _buildSlider(String leftEmoji, String leftLabel, String rightEmoji,
      String rightLabel, double value, ValueChanged<double> onChanged) {
    return Transform.translate(
      offset: const Offset(0, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$leftEmoji $leftLabel',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14)),
              Text('$rightEmoji $rightLabel',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14)),
            ],
          ),
          Transform.translate(
            offset: const Offset(0, -8),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              divisions: 10,
              activeColor: Colors.pinkAccent,
              onChanged: (newValue) {
                setState(() => onChanged(newValue));
                _updatePositivity();
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _getScoreMessage(double score) {
    if (score >= 70) {
      return "🌟 You're radiating positivity today!";
    } else if (score >= 50) {
      return "🌈 You're doing okay — a little self-care goes a long way.";
    } else {
      return "💗 Be kind to yourself — brighter days are coming.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'How are you feeling today?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildSlider('😢', 'Sad', '😊', 'Happy', sadHappy,
            (v) => sadHappy = v),
        const SizedBox(height: 12),
        _buildSlider('😴', 'Tired', '⚡', 'Energetic', tiredEnergetic,
            (v) => tiredEnergetic = v),
        const SizedBox(height: 12),
        _buildSlider('🍽️', 'Hungry', '😋', 'Full', hungryFull,
            (v) => hungryFull = v),
        const SizedBox(height: 12),
        _buildSlider('😰', 'Worried', '😌', 'Calm', worriedCalm,
            (v) => worriedCalm = v),
        const SizedBox(height: 12),
        _buildSlider('😠', 'Angry', '🤗', 'Kind', angryKind,
            (v) => angryKind = v),
        const SizedBox(height: 16),
        // Positivity Score at the bottom
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(
            color: _getScoreColor(positivityScore).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getScoreColor(positivityScore),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Positivity Score: ${positivityScore.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(positivityScore),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getScoreMessage(positivityScore),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
