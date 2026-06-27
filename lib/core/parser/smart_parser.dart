import 'parsed_memory.dart';

/// Contract interface for the natural language parser.
abstract class SmartParser {
  ParsedMemory parse(String content);
}

class SmartParserImpl implements SmartParser {
  @override
  ParsedMemory parse(String content) {
    final text = content.trim();

    // 1. Detect Person Name (Added 'for' preposition to match 'appointment for Dr Sharma')
    final nameRegex = RegExp(
      r'\b(?:with|call|meet|meeting|to|for)\s+(Dr\.?\s+[A-Z][a-zA-Z]+|[A-Z][a-zA-Z]+)',
      caseSensitive: false,
    );
    String? personName;
    final nameMatch = nameRegex.firstMatch(text);
    if (nameMatch != null) {
      personName = nameMatch.group(1);
    }

    // 2. Detect Date
    DateTime? parsedDate;
    final now = DateTime.now();

    if (text.toLowerCase().contains('tomorrow')) {
      parsedDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 1));
    } else if (text.toLowerCase().contains('today')) {
      parsedDate = DateTime(now.year, now.month, now.day);
    } else {
      // Check absolute month days (e.g. "15 July" or "28 June")
      final dateRegex = RegExp(
        r'\b([0-9]{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|January|February|March|April|May|June|July|August|September|October|November|December)\b',
        caseSensitive: false,
      );
      final dateMatch = dateRegex.firstMatch(text);
      if (dateMatch != null) {
        final day = int.parse(dateMatch.group(1)!);
        final monthStr = dateMatch.group(2)!.toLowerCase();
        final month = _getMonthIndex(monthStr);
        parsedDate = DateTime(now.year, month, day);
        // If the date has already passed this year, assume the next year
        if (parsedDate.isBefore(DateTime(now.year, now.month, now.day))) {
          parsedDate = DateTime(now.year + 1, month, day);
        }
      } else {
        // Check weekdays (e.g. "Monday" or "Friday")
        final weekdayRegex = RegExp(
          r'\b(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\b',
          caseSensitive: false,
        );
        final weekdayMatch = weekdayRegex.firstMatch(text);
        if (weekdayMatch != null) {
          final weekdayStr = weekdayMatch.group(1)!.toLowerCase();
          final targetWeekday = _getWeekdayIndex(weekdayStr);
          int currentWeekday = now.weekday;
          int daysToAdd = (targetWeekday - currentWeekday) % 7;
          if (daysToAdd <= 0) {
            daysToAdd += 7;
          }
          parsedDate = DateTime(
            now.year,
            now.month,
            now.day,
          ).add(Duration(days: daysToAdd));
        }
      }
    }

    // 3. Detect Time
    String? parsedTime;
    int? parsedHour;
    int? parsedMinute;

    final timeRegex = RegExp(
      r'\b([0-9]{1,2})(?::([0-9]{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    );
    final timeMatch = timeRegex.firstMatch(text);
    if (timeMatch != null) {
      parsedTime = timeMatch.group(0);
      parsedHour = int.parse(timeMatch.group(1)!);
      parsedMinute = timeMatch.group(2) != null
          ? int.parse(timeMatch.group(2)!)
          : 0;
      final ampm = timeMatch.group(3)!.toLowerCase();

      if (ampm == 'pm' && parsedHour < 12) {
        parsedHour += 12;
      }
      if (ampm == 'am' && parsedHour == 12) {
        parsedHour = 0;
      }
    }

    // 4. Determine Reminder DateTime
    DateTime? reminderAt;
    if (parsedDate != null) {
      final hour =
          parsedHour ?? 9; // Default reminder to 9 AM if only date is present
      final minute = parsedMinute ?? 0;
      final eventTime = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        hour,
        minute,
      );

      // If time was parsed explicitly, default reminder to 30 mins before
      if (parsedHour != null) {
        final offsetTime = eventTime.subtract(const Duration(minutes: 30));
        if (offsetTime.isBefore(now) && eventTime.isAfter(now)) {
          reminderAt =
              eventTime; // Use exactly eventTime if the offset is in the past!
        } else {
          reminderAt = offsetTime;
        }
      } else {
        reminderAt = eventTime;
      }
    } else if (parsedHour != null) {
      final hour = parsedHour;
      final minute = parsedMinute ?? 0;
      var eventTime = DateTime(now.year, now.month, now.day, hour, minute);

      // If the event time has already passed today, assume it is for tomorrow!
      if (eventTime.isBefore(now)) {
        eventTime = eventTime.add(const Duration(days: 1));
      }

      final offsetTime = eventTime.subtract(const Duration(minutes: 30));
      if (offsetTime.isBefore(now) && eventTime.isAfter(now)) {
        reminderAt = eventTime;
      } else {
        reminderAt = offsetTime;
      }
    }

    // 5. Determine Memory Type, Category & Priority
    String type = 'Personal';
    String category = 'Personal';
    String priority = 'Low';
    final List<String> tags = [];

    final textLower = text.toLowerCase();

    // Prioritized check order: Health checks first, then meetings/appointments
    if (textLower.contains('doctor') ||
        textLower.contains('dentist') ||
        textLower.contains('dr.') ||
        textLower.contains('dr ') ||
        textLower.contains('gym') ||
        textLower.contains('workout') ||
        textLower.contains('health')) {
      type = 'Health';
      category = 'Health';
      tags.add('Health');
      priority = 'High';
    } else if (textLower.contains('birthday') || textLower.contains('bday')) {
      type = 'Birthday';
      category = 'Personal';
      tags.add('Birthday');
      priority = 'Medium';
    } else if (textLower.contains('meeting') ||
        textLower.contains('appointment') ||
        textLower.contains('meet')) {
      type = 'Meeting';
      category = 'Work';
      tags.add('Meeting');
      priority = 'High';
    } else if (textLower.contains('buy') ||
        textLower.contains('shopping') ||
        textLower.contains('milk') ||
        textLower.contains('grocery')) {
      type = 'Shopping';
      category = 'Personal';
      tags.add('Shopping');
      priority = 'Low';
    } else if (textLower.contains('pay') ||
        textLower.contains('bill') ||
        textLower.contains('rent') ||
        textLower.contains('finance')) {
      type = 'Finance';
      category = 'Finance';
      tags.add('Finance');
      priority = 'High';
    } else if (textLower.contains('flight') ||
        textLower.contains('trip') ||
        textLower.contains('hotel') ||
        textLower.contains('travel')) {
      type = 'Travel';
      category = 'Travel';
      tags.add('Travel');
      priority = 'High';
    } else if (textLower.contains('call') ||
        textLower.contains('todo') ||
        textLower.contains('task')) {
      type = 'Task';
      category = 'Work';
      tags.add('Task');
      priority = 'Medium';
    } else if (textLower.contains('reminder') || reminderAt != null) {
      type = 'Reminder';
      category = 'Personal';
      tags.add('Reminder');
      priority = 'Medium';
    }

    // Adjust Priority based on urgency keywords
    if (textLower.contains('urgent') ||
        textLower.contains('important') ||
        textLower.contains('asap') ||
        textLower.contains('must')) {
      priority = 'High';
    }

    // 6. Generate Fallback Title
    final title = _generateFallbackTitle(text);

    return ParsedMemory(
      title: title,
      content: text,
      type: type,
      reminderAt: reminderAt,
      personName: personName,
      date: parsedDate,
      time: parsedTime,
      priority: priority,
      category: category,
      tags: tags,
    );
  }

  int _getMonthIndex(String monthStr) {
    if (monthStr.startsWith('jan')) return 1;
    if (monthStr.startsWith('feb')) return 2;
    if (monthStr.startsWith('mar')) return 3;
    if (monthStr.startsWith('apr')) return 4;
    if (monthStr.startsWith('may')) return 5;
    if (monthStr.startsWith('jun')) return 6;
    if (monthStr.startsWith('jul')) return 7;
    if (monthStr.startsWith('aug')) return 8;
    if (monthStr.startsWith('sep')) return 9;
    if (monthStr.startsWith('oct')) return 10;
    if (monthStr.startsWith('nov')) return 11;
    if (monthStr.startsWith('dec')) return 12;
    return 1;
  }

  int _getWeekdayIndex(String weekdayStr) {
    if (weekdayStr.startsWith('mon')) return 1;
    if (weekdayStr.startsWith('tue')) return 2;
    if (weekdayStr.startsWith('wed')) return 3;
    if (weekdayStr.startsWith('thu')) return 4;
    if (weekdayStr.startsWith('fri')) return 5;
    if (weekdayStr.startsWith('sat')) return 6;
    if (weekdayStr.startsWith('sun')) return 7;
    return 1;
  }

  String _generateFallbackTitle(String content) {
    final words = content.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || content.isEmpty) return 'Unstructured Note';
    final limit = words.length > 4 ? 4 : words.length;
    return '${words.sublist(0, limit).join(' ')}...';
  }
}
