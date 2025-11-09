import 'package:intl/intl.dart';

String getCurrentLocalDate() {
  // Get the current date/time in the user's local timezone
  final now = DateTime.now();

  // Format as YYYY-MM-DD
  final formattedDate = DateFormat('yyyy-MM-dd').format(now);

  return formattedDate;
}