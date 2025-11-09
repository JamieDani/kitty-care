import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';


final FirebaseFirestore _db = FirebaseFirestore.instance;

Future<int> daysToPeriod() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('No user logged in');
  }

  final userDoc = await getUserDocument(user.uid);
  final childId = userDoc?['childId'] as String?;

  if (childId == null) {
    throw Exception('Child ID not found in user document');
  }
  final DateFormat format = DateFormat('yyyy-MM-dd');
  final DateTime today = DateTime.now();

  try {
    final DocumentReference childRef = _db.collection('children').doc(childId);
    final CollectionReference cyclesRef = childRef.collection('cycles');

    // Fetch the most recent cycle
    final QuerySnapshot recentCycles = await cyclesRef
        .orderBy('periodStartDate', descending: true)
        .limit(1)
        .get();

    if (recentCycles.docs.isEmpty) {
      throw Exception('No cycles found for this child.');
    }

    final recentCycle = recentCycles.docs.first;
    final data = recentCycle.data() as Map<String, dynamic>;

    // Get the predicted end of luteal phase
    final String lutealEndStr = data['predictedLuteal'][1];
    final DateTime lutealEnd = format.parse(lutealEndStr);

    // The next period should start the day after the luteal end
    final DateTime nextPeriodStart = lutealEnd.add(const Duration(days: 1));

    // Calculate the difference in days
    int daysRemaining = nextPeriodStart.difference(today).inDays;

    // Clamp negative values to 0
    if (daysRemaining < 0) daysRemaining = 0;

    print('📅 Days until next period: $daysRemaining');
    return daysRemaining;
  } catch (e) {
    print('❌ Error calculating days to period: $e');
    rethrow;
  }
}


Future<String?> getCurrentPhase(String dateString) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('No user logged in');
  }

  final userDoc = await getUserDocument(user.uid);
  final childId = userDoc?['childId'] as String?;

  if (childId == null) {
    throw Exception('Child ID not found in user document');
  }
  final DateFormat format = DateFormat('yyyy-MM-dd');
  final DateTime queryDate = format.parse(dateString);

  try {
    final DocumentReference childRef = _db.collection('children').doc(childId);

    // Get child's periodLength
    final childSnapshot = await childRef.get();
    if (!childSnapshot.exists) throw Exception('Child document not found');
    final int periodLength = childSnapshot.get('periodLength');

    final CollectionReference cyclesRef = childRef.collection('cycles');

    // Get all cycles ordered by periodStartDate descending
    final QuerySnapshot cyclesSnapshot = await cyclesRef
        .orderBy('periodStartDate', descending: true)
        .get();

    for (final doc in cyclesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final DateTime follicularStart =
          format.parse(data['predictedFollicular'][0]);
      final DateTime follicularEnd =
          format.parse(data['predictedFollicular'][1]);
      final DateTime ovulationDate = format.parse(data['predictedOvulation']);
      final DateTime lutealStart = format.parse(data['predictedLuteal'][0]);
      final DateTime lutealEnd = format.parse(data['predictedLuteal'][1]);

      // Check if queryDate is within this cycle
      if (queryDate.isBefore(follicularStart) || queryDate.isAfter(lutealEnd)) {
        continue; // Not in this cycle
      }

      // ✅ Determine specific phase
      if (!queryDate.isBefore(follicularStart) &&
          !queryDate.isAfter(follicularEnd)) {
        // Check if within periodLength days of follicularStart
        final DateTime periodEnd =
            follicularStart.add(Duration(days: periodLength - 1));
        if (!queryDate.isAfter(periodEnd)) {
          print("period");
          return 'period';
        } else {
          print("follicular");
          return 'follicular';
        }
      } else if (queryDate.isAtSameMomentAs(ovulationDate)) {
        print("ovulation");
        return 'ovulation';
      } else if (!queryDate.isBefore(lutealStart) &&
          !queryDate.isAfter(lutealEnd)) {
        print("luteal");
        return 'luteal';
      }
    }
    print('unknown');
    return 'unknown';
  } catch (e) {
    print('❌ Error getting current phase: $e');
    rethrow;
  }
}


Future<void> logPeriodStart(String dateString) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('No user logged in');
  }

  final userDoc = await getUserDocument(user.uid);
  final childId = userDoc?['childId'] as String?;

  if (childId == null) {
    throw Exception('Child ID not found in user document');
  }
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
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('No user logged in');
  }

  final userDoc = await getUserDocument(user.uid);
  final childId = userDoc?['childId'] as String?;

  if (childId == null) {
    throw Exception('Child ID not found in user document');
  } // TODO: replace with actual ID
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
      final String? phase = await getCurrentPhase(dateString);

      await dailyLogsRef.add({
        'date': dateString,
        'phase': phase,
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

Future<void> logPhysical(
  int frontCramps,
  int backCramps,
  int headache,
  int nausea,
  int fatigue,
  String dateString,
) async {
final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('No user logged in');
  }

  final userDoc = await getUserDocument(user.uid);
  final childId = userDoc?['childId'] as String?;

  if (childId == null) {
    throw Exception('Child ID not found in user document');
  }  final DateFormat format = DateFormat('yyyy-MM-dd');

  try {
    // Validate 0–10 range
    for (final value in [frontCramps, backCramps, headache, nausea, fatigue]) {
      if (value < 0 || value > 5) {
        throw Exception('Emotion values must be between 0 and 5 inclusive.');
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
      final String? phase = await getCurrentPhase(dateString);

      await dailyLogsRef.add({
        'date': dateString,
        'phase': phase,
        'physicalSymptoms': {
          'frontCramps': frontCramps,
          'backCramps': backCramps,
          'headache': headache,
          'nausea': nausea,
          'fatigue': fatigue,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('(physical) Created new daily log for $dateString');
    } else {
      // Log exists → update emotionalSymptoms
      final docRef = existingLogs.docs.first.reference;
      await docRef.set({
        'physicalSymptoms': {
          'frontCramps': frontCramps,
          'backCramps': backCramps,
          'headache': headache,
          'nausea': nausea,
          'fatigue': fatigue,
        },
      }, SetOptions(merge: true));

      print('🔄 (physical) Updated existing daily log for $dateString');
    }
  } catch (e) {
    print('❌ Error logging physical: $e');
    rethrow;
  }
}

Future<void> logSleep(double hours, String dateString) async {
final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('No user logged in');
  }

  final userDoc = await getUserDocument(user.uid);
  final childId = userDoc?['childId'] as String?;

  if (childId == null) {
    throw Exception('Child ID not found in user document');
  }  final DateFormat format = DateFormat('yyyy-MM-dd');

  try {
    // Validate hours (e.g., 0–24 range, but flexible)
    if (hours < 0 || hours > 24) {
      throw Exception('Sleep hours must be between 0 and 24.');
    }

    final DocumentReference childRef = _db.collection('children').doc(childId);
    final CollectionReference dailyLogsRef = childRef.collection('dailyLogs');

    // Check if there's already a log for that date
    final existingLogs = await dailyLogsRef
        .where('date', isEqualTo: dateString)
        .limit(1)
        .get();

    if (existingLogs.docs.isEmpty) {
      final String? phase = await getCurrentPhase(dateString);

      // No existing log → create a new one
      await dailyLogsRef.add({
        'date': dateString,
        'phase': phase,
        'hoursSleep': hours,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('💤 Created new daily log for $dateString with $hours hours of sleep');
    } else {
      // Log exists → update or add hoursSleep field
      final docRef = existingLogs.docs.first.reference;
      await docRef.set({
        'hoursSleep': hours,
      }, SetOptions(merge: true));

      print('🔄 Updated sleep hours for $dateString to $hours');
    }
  } catch (e) {
    print('❌ Error logging sleep: $e');
    rethrow;
  }
}

/// Fetches the past 7 days of daily logs for a child and computes category-based averages.
/// Handles missing categories but assumes all subfields exist if category exists.
Future<Map<String, dynamic>> fetchWeeklyLogs(String childId) async {
  final DateTime now = DateTime.now();
  final DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));

  final QuerySnapshot logsSnapshot = await _db
      .collection('children')
      .doc(childId)
      .collection('dailyLogs')
      .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(sevenDaysAgo))
      .get();

  if (logsSnapshot.docs.isEmpty) {
    return {};
  }

  // Initialize sums and counters
  final Map<String, double> physicalSums = {
    'frontCramps': 0,
    'backCramps': 0,
    'headache': 0,
    'nausea': 0,
    'fatigue': 0,
  };
  int physicalCount = 0;

  final Map<String, double> emotionalSums = {
    'happiness': 0,
    'energy': 0,
    'satiation': 0,
    'calmness': 0,
    'kindness': 0,
  };
  int emotionalCount = 0;

  double totalHoursSlept = 0;
  int sleepCount = 0;

  final Map<String, int> phaseCounts = {};

  // Aggregate
  for (var doc in logsSnapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;

    // --- Physical Symptoms ---
    if (data['physicalSymptoms'] != null) {
      final physical = Map<String, dynamic>.from(data['physicalSymptoms']);
      for (var key in physicalSums.keys) {
        physicalSums[key] = physicalSums[key]! + (physical[key] ?? 0).toDouble();
      }
      physicalCount++;
    }

    // --- Emotional Symptoms ---
    if (data['emotionalSymptoms'] != null) {
      final emotional = Map<String, dynamic>.from(data['emotionalSymptoms']);
      for (var key in emotionalSums.keys) {
        emotionalSums[key] = emotionalSums[key]! + (emotional[key] ?? 0).toDouble();
      }
      emotionalCount++;
    }

    // --- Sleep ---
    if (data['hoursSleep'] != null) {
      totalHoursSlept += (data['hoursSleep']).toDouble();
      sleepCount++;
    }

    // --- Phase ---
    if (data['phase'] != null) {
      final phase = data['phase'] as String;
      phaseCounts[phase] = (phaseCounts[phase] ?? 0) + 1;
    }
  }

  // --- Compute Averages ---
  final Map<String, double> physicalAvg = {
    for (var key in physicalSums.keys)
      key: physicalCount > 0 ? physicalSums[key]! / physicalCount : 0
  };

  final Map<String, double> emotionalAvg = {
    for (var key in emotionalSums.keys)
      key: emotionalCount > 0 ? emotionalSums[key]! / emotionalCount : 0
  };

  final avgSleep = sleepCount > 0 ? totalHoursSlept / sleepCount : 0.0;

  final String dominantPhase = phaseCounts.isEmpty
      ? 'unknown'
      : (phaseCounts.entries.reduce((a, b) => a.value > b.value ? a : b)).key;

  var logs = {
    'physicalAvg': physicalAvg,
    'emotionalAvg': emotionalAvg,
    'avgSleep': avgSleep,
    'dominantPhase': dominantPhase,
    'logCount': logsSnapshot.docs.length,
    'physicalCount': physicalCount,
    'emotionalCount': emotionalCount,
    'sleepCount': sleepCount,
  };
  print(logs);
  return logs;
}
      .where(
        'date',
        isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(sevenDaysAgo),
      )
      .orderBy('date', descending: false)
      .get();

  if (logsSnapshot.docs.isEmpty) {
    return [];
  }

  const physicalFields = [
    'backCramps',
    'fatigue',
    'frontCramps',
    'headache',
    'nausea',
  ];

  const emotionalFields = [
    'calmness',
    'energy',
    'happiness',
    'kindness',
    'satiation',
  ];

  final List<Map<String, dynamic>> rawLogs = logsSnapshot.docs.map((doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map); // ✅ safe conversion
    data['id'] = doc.id;

    // --- Ensure Physical Symptoms ---
    final rawPhysical = Map<String, dynamic>.from(data['physicalSymptoms'] ?? {});
    final physical = {
      for (var key in physicalFields) key: (rawPhysical[key] ?? 0).toDouble(),
    };
    data['physicalSymptoms'] = physical;

    // --- Ensure Emotional Symptoms ---
    final rawEmotional = Map<String, dynamic>.from(data['emotionalSymptoms'] ?? {});
    final emotional = {
      for (var key in emotionalFields) key: (rawEmotional[key] ?? 0).toDouble(),
    };
    data['emotionalSymptoms'] = emotional;

    // --- Other Fields ---
    data['hoursSlept'] = (data['hoursSlept'] ?? 0).toDouble();
    data['padChanges'] = List<String>.from(data['padChanges'] ?? []);
    data['phase'] = data['phase'] ?? 'unknown';
    data['date'] = data['date'] ?? '';

    return data;
  }).toList();

  return rawLogs;
}


Future<Map<String, dynamic>?> getUserDocument(String userId) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();
  return doc.data();
}

Future<Map<String, dynamic>?> getParentDocument(String parentId) async {
  final doc = await FirebaseFirestore.instance
      .collection('parents')
      .doc(parentId)
      .get();
  return doc.data();
}

Future<bool> verifyChildExists(String childId) async {
  final doc = await FirebaseFirestore.instance
      .collection('children')
      .doc(childId)
      .get();
  return doc.exists;
}

Future<void> updateParentChildId(String parentId, String childId) async {
  await FirebaseFirestore.instance
      .collection('parents')
      .doc(parentId)
      .update({'childId': childId});
}
