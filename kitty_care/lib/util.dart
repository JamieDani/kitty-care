import 'package:intl/intl.dart';

String getCurrentLocalDate() {
  // Get the current date/time in the user's local timezone
  final now = DateTime.now();

  // Format as YYYY-MM-DD
  final formattedDate = DateFormat('yyyy-MM-dd').format(now);

  return formattedDate;
}

String generateWeeklyInsights(Map<String, dynamic> weeklyData) {
  final physicalAvg = Map<String, double>.from(weeklyData['physicalAvg'] ?? {});
  final emotionalAvg = Map<String, double>.from(weeklyData['emotionalAvg'] ?? {});
  final avgSleep = (weeklyData['avgSleep'] ?? 0.0).toDouble();
  final dominantPhase = (weeklyData['dominantPhase'] ?? 'unknown').toLowerCase();

  final int physicalCount = weeklyData['physicalCount'] ?? 0;
  final int emotionalCount = weeklyData['emotionalCount'] ?? 0;
  final int sleepCount = weeklyData['sleepCount'] ?? 0;

  List<String> insights = [];

  // 🌿 Recommended sleep by phase
  final recommendedSleep = {
    'menstrual': 9.0,
    'follicular': 8.0,
    'ovulation': 7.5,
    'luteal': 8.5,
  };
  final recSleep = recommendedSleep[dominantPhase] ?? 8.0;

  // 🩸 PHYSICAL INSIGHTS
  if (physicalCount > 0) {
    final highSymptoms = <String>[];
    final lowSymptoms = <String>[];

    physicalAvg.forEach((key, value) {
      if (value >= 3) highSymptoms.add(key);
      if (value <= 1) lowSymptoms.add(key);
    });

    if (highSymptoms.isNotEmpty) {
      insights.add(
          "The child experienced elevated levels of ${highSymptoms.join(', ')}, indicating possible physical discomfort this week.");
    }
    if (lowSymptoms.isNotEmpty && highSymptoms.isEmpty) {
      insights.add("The child reported minimal physical symptoms overall, including low ${lowSymptoms.join(', ')}.");
    }
    if (highSymptoms.isEmpty && lowSymptoms.isEmpty) {
      insights.add("The child’s physical symptoms remained moderate and stable this week.");
    }
  }

  // 💖 EMOTIONAL INSIGHTS
  if (emotionalCount > 0) {
    final happiness = emotionalAvg['happiness'] ?? 0;
    final energy = emotionalAvg['energy'] ?? 0;
    final satiation = emotionalAvg['satiation'] ?? 0; // hungry -> full
    final calmness = emotionalAvg['calmness'] ?? 0;   // tense -> calm
    final kindness = emotionalAvg['kindness'] ?? 0;   // angry -> kind

    // General emotional tone
    final avgMood = (happiness + calmness + kindness) / 3;

    if (avgMood < 4) {
      insights.add(
          "The child’s overall mood indicators, including happiness, calmness, and kindness, were lower than average, suggesting elevated irritability or emotional sensitivity.");
    } else if (avgMood > 7) {
      insights.add(
          "The child demonstrated consistently positive mood indicators, with above-average happiness, calmness, and kindness.");
    }

    // Energy level
    if (energy < 4) {
      insights.add(
          "The child showed lower energy levels than typical, possibly related to hormonal changes in the ${dominantPhase} phase.");
    } else if (energy > 7) {
      insights.add(
          "The child exhibited high energy levels throughout the week, which may align with the follicular or ovulation phases.");
    }

    // Hunger/satiation pattern
    if (satiation < 4) {
      insights.add(
          "The child frequently reported low satiation, suggesting increased hunger or appetite fluctuations.");
    } else if (satiation > 7) {
      insights.add(
          "The child reported feeling well-nourished and satiated on most days.");
    }
  }

  // 😴 SLEEP INSIGHTS
  if (sleepCount > 0) {
    if (avgSleep < recSleep - 1) {
      insights.add(
          "The child averaged ${avgSleep.toStringAsFixed(1)} hours of sleep, which is below the recommended ${recSleep.toStringAsFixed(1)} hours for the ${dominantPhase} phase.");
    } else if (avgSleep > recSleep + 1) {
      insights.add(
          "The child averaged ${avgSleep.toStringAsFixed(1)} hours of sleep, exceeding the typical ${recSleep.toStringAsFixed(1)} hours for the ${dominantPhase} phase.");
    } else {
      insights.add(
          "The child’s sleep duration (${avgSleep.toStringAsFixed(1)} hrs) aligned closely with the recommended amount for the ${dominantPhase} phase (${recSleep.toStringAsFixed(1)} hrs).");
    }
  }

  // 🌷 PHASE CONTEXT
  if (dominantPhase != 'unknown') {
    String phaseSummary;
    switch (dominantPhase) {
      case 'menstrual':
        phaseSummary =
            "During the menstrual (winter) phase, increased rest and gentle care are beneficial as fatigue and cramps are common.";
        break;
      case 'follicular':
        phaseSummary =
            "During the follicular (spring) phase, the child’s energy and mood typically improve as hormone levels rise.";
        break;
      case 'ovulation':
        phaseSummary =
            "During the ovulation (summer) phase, energy, confidence, and social motivation are often at their peak.";
        break;
      case 'luteal':
        phaseSummary =
            "During the luteal (autumn) phase, emotional variability and physical tension can increase, making adequate sleep especially important.";
        break;
      default:
        phaseSummary = "Cycle phase data was varied this week.";
    }
    insights.add(phaseSummary);
  }

  return insights.join(' ');
}
