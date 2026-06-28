import 'package:flutter/material.dart';

/// Reusable widget to display a DateTime formatted relatively.
/// Shows: 'Today', 'Yesterday', 'X days ago', 'Last week', 'X weeks ago', 'X months ago'.
class RelativeDateText extends StatelessWidget {
  final DateTime date;
  final TextStyle? style;

  const RelativeDateText({
    super.key,
    required this.date,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      getRelativeDateString(date, DateTime.now()),
      style: style,
    );
  }

  static String getRelativeDateString(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final comparisonDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(comparisonDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 0) {
      // Future date fallback (for tomorrow reminders)
      if (difference == -1) return 'Tomorrow';
      return 'In ${-difference} days';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 14) {
      return 'Last week';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (difference / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }
}
