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
    return Image.asset(
      'assets/images/Window.png',
      width: 200,
      height: 150,
      fit: BoxFit.contain,
    );
  }
}
