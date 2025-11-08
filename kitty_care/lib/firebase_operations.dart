import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

final FirebaseFirestore _db = FirebaseFirestore.instance;

Future<void> logPeriodStart(String dateString) async {
  const String childId = 'TkzT27YKNhsb8k7ZOKFD';
  final DateFormat format = DateFormat('yyyy-MM-dd');
  final DateTime newPeriodStart = format.parse(dateString);

  try {
    final DocumentReference childRef = _db.collection('children').doc(childId);

    // Fetch child's periodLength
    final childSnapshot = await childRef.get();
    if (!childSnapshot.exists) {
      throw Exception('Child document not found');
    }

    final int periodLength = childSnapshot.get('periodLength');
    final int cycleLength = 28 + (periodLength - 7);

    // STEP 1: Fetch the most recent cycle
    final recentCycles = await childRef
        .collection('cycles')
        .orderBy('periodStartDate', descending: true)
        .limit(1)
        .get();

    if (recentCycles.docs.isNotEmpty) {
      final recentCycle = recentCycles.docs.first;
      final String prevLutealEndStr = recentCycle['predictedLuteal'][1];
      final DateTime prevLutealEnd = format.parse(prevLutealEndStr);

      // STEP 2: Check if the new period starts before previous predicted end
      if (newPeriodStart.isBefore(prevLutealEnd)) {
        final DateTime adjustedEnd = newPeriodStart.subtract(const Duration(days: 1));
        await recentCycle.reference.update({
          'predictedLuteal': [
            recentCycle['predictedLuteal'][0],
            format.format(adjustedEnd)
          ],
          'cycleShortened': true,
        });
        print('🩸 Previous cycle shortened to end on ${format.format(adjustedEnd)}');
      }
    }

    // STEP 3: Calculate new cycle dates
    final DateTime follicularStart = newPeriodStart;
    final DateTime follicularEnd =
        newPeriodStart.add(Duration(days: cycleLength - 16));
    final DateTime ovulationDate =
        newPeriodStart.add(Duration(days: cycleLength - 15));
    final DateTime lutealStart =
        newPeriodStart.add(Duration(days: cycleLength - 14));
    final DateTime lutealEnd =
        newPeriodStart.add(Duration(days: cycleLength - 1));

    // STEP 4: Save new cycle
    await childRef.collection('cycles').add({
      'periodStartDate': dateString,
      'cycleLength': cycleLength,
      'predictedFollicular': [
        format.format(follicularStart),
        format.format(follicularEnd)
      ],
      'predictedOvulation': format.format(ovulationDate),
      'predictedLuteal': [
        format.format(lutealStart),
        format.format(lutealEnd)
      ],
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('✅ New cycle logged successfully');
  } catch (e) {
    print('❌ Error logging period start: $e');
    rethrow;
  }
}


Future<void> logEmotions(
  int happiness,
  int energy,
  int satiation,
  int calmness,
  int kindness,
  String dateString,
) async {
  const String childId = 'TkzT27YKNhsb8k7ZOKFD'; // TODO: replace with actual ID
  final DateFormat format = DateFormat('yyyy-MM-dd');

  try {
    // Validate 0–10 range
    for (final value in [happiness, energy, satiation, calmness, kindness]) {
      if (value < 0 || value > 10) {
        throw Exception('Emotion values must be between 0 and 10 inclusive.');
      }
    }

    final DocumentReference childRef = _db.collection('children').doc(childId);
    final CollectionReference dailyLogsRef = childRef.collection('dailyLogs');

    // Check if a log for this date already exists
    final existingLogs = await dailyLogsRef
        .where('date', isEqualTo: dateString)
        .limit(1)
        .get();

    if (existingLogs.docs.isEmpty) {
      // No existing log → create new one
      await dailyLogsRef.add({
        'date': dateString,
        'emotionalSymptoms': {
          'happiness': happiness,
          'energy': energy,
          'satiation': satiation,
          'calmness': calmness,
          'kindness': kindness,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('🧠 Created new daily log for $dateString');
    } else {
      // Log exists → update emotionalSymptoms
      final docRef = existingLogs.docs.first.reference;
      await docRef.set({
        'emotionalSymptoms': {
          'happiness': happiness,
          'energy': energy,
          'satiation': satiation,
          'calmness': calmness,
          'kindness': kindness,
        },
      }, SetOptions(merge: true));

      print('🔄 Updated existing daily log for $dateString');
    }
  } catch (e) {
    print('❌ Error logging emotions: $e');
    rethrow;
  }
}

