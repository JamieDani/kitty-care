import 'package:flutter/material.dart';
import '../models/seasons.dart';

class WindowDisplay extends StatelessWidget {
  final Season currentSeason;
  const WindowDisplay({super.key, required this.currentSeason});

  String get seasonText {
    switch (currentSeason) {
      case Season.winter:
        return 'Winter';
      case Season.spring:
        return 'Spring';
      case Season.summer:
        return 'Summer';
      case Season.fall:
        return 'Fall';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.lightBlue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        seasonText,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
