enum MemoryBrainIntent {
  todaySummary,
  yesterdaySummary,
  weekSummary,
  monthSummary,
  reminderQuery,
  upcomingReminder,
  missedReminder,
  completedReminder,
  categoryQuery,
  timeQuery,
  productivityQuery,
  timelineQuery,
  statisticsQuery,
  unknown,
}

class IntentParser {
  static MemoryBrainIntent parse(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return MemoryBrainIntent.unknown;

    // 1. Productivity Query
    if (q.contains('productive') ||
        q.contains('productivity') ||
        q.contains('efficiency') ||
        q.contains('streak') ||
        q.contains('completion rate') ||
        q.contains('complete rate')) {
      return MemoryBrainIntent.productivityQuery;
    }

    // 2. Statistics Query
    if (q.contains('how many') ||
        q.contains('number of') ||
        q.contains('count') ||
        q.contains('how much') ||
        q.contains('statistics') ||
        q.contains('stats')) {
      return MemoryBrainIntent.statisticsQuery;
    }

    // 3. Completed Reminders
    if (q.contains('completed') ||
        q.contains('finished') ||
        q.contains('done reminder') ||
        q.contains('done task') ||
        q.contains('completed reminder')) {
      return MemoryBrainIntent.completedReminder;
    }

    // 4. Missed Reminders / Forgot
    if (q.contains('missed') ||
        q.contains('forgot') ||
        q.contains('forget') ||
        q.contains('overdue') ||
        q.contains('expired')) {
      return MemoryBrainIntent.missedReminder;
    }

    // 5. Upcoming Reminders
    if (q.contains('upcoming') ||
        q.contains('tomorrow') ||
        q.contains('next week') ||
        q.contains('pending')) {
      return MemoryBrainIntent.upcomingReminder;
    }

    // 6. General Reminder Query
    if (q.contains('reminder') ||
        q.contains('reminders') ||
        q.contains('alert') ||
        q.contains('alerts')) {
      return MemoryBrainIntent.reminderQuery;
    }

    // 7. Today Summary
    if (q.contains('today') || q.contains('what did i do today') || q.contains('today\'s memories')) {
      return MemoryBrainIntent.todaySummary;
    }

    // 8. Yesterday Summary
    if (q.contains('yesterday') || q.contains('what happened yesterday') || q.contains('yesterday\'s memories')) {
      return MemoryBrainIntent.yesterdaySummary;
    }

    // 9. Week Summary
    if (q.contains('this week') || q.contains('week summary') || q.contains('past week')) {
      return MemoryBrainIntent.weekSummary;
    }

    // 10. Month Summary
    if (q.contains('this month') || q.contains('month summary') || q.contains('past month')) {
      return MemoryBrainIntent.monthSummary;
    }

    // 11. Timeline Query
    if (q.contains('timeline') ||
        q.contains('history') ||
        q.contains('feed') ||
        q.contains('what did i do') ||
        q.contains('what happened')) {
      return MemoryBrainIntent.timelineQuery;
    }

    // 12. Time Query
    if (q.contains('monday') ||
        q.contains('tuesday') ||
        q.contains('wednesday') ||
        q.contains('thursday') ||
        q.contains('friday') ||
        q.contains('saturday') ||
        q.contains('sunday') ||
        q.contains('days ago') ||
        q.contains('weeks ago') ||
        q.contains('months ago') ||
        q.contains('january') ||
        q.contains('february') ||
        q.contains('march') ||
        q.contains('april') ||
        q.contains('may') ||
        q.contains('june') ||
        q.contains('july') ||
        q.contains('august') ||
        q.contains('september') ||
        q.contains('october') ||
        q.contains('november') ||
        q.contains('december')) {
      return MemoryBrainIntent.timeQuery;
    }

    // 13. Category Query
    if (q.contains('health') ||
        q.contains('doctor') ||
        q.contains('hospital') ||
        q.contains('medicine') ||
        q.contains('clinic') ||
        q.contains('physician') ||
        q.contains('checkup') ||
        q.contains('work') ||
        q.contains('meeting') ||
        q.contains('office') ||
        q.contains('job') ||
        q.contains('project') ||
        q.contains('todo') ||
        q.contains('task') ||
        q.contains('finance') ||
        q.contains('money') ||
        q.contains('bank') ||
        q.contains('bill') ||
        q.contains('payment') ||
        q.contains('expenses') ||
        q.contains('spend') ||
        q.contains('invoice') ||
        q.contains('credit') ||
        q.contains('learning') ||
        q.contains('learn') ||
        q.contains('flutter') ||
        q.contains('dart') ||
        q.contains('study') ||
        q.contains('course') ||
        q.contains('read') ||
        q.contains('book') ||
        q.contains('programming') ||
        q.contains('bloc') ||
        q.contains('ideas') ||
        q.contains('idea') ||
        q.contains('thought') ||
        q.contains('brainstorm') ||
        q.contains('concept') ||
        q.contains('draft') ||
        q.contains('shopping') ||
        q.contains('buy') ||
        q.contains('groceries') ||
        q.contains('store') ||
        q.contains('purchase') ||
        q.contains('order') ||
        q.contains('list') ||
        q.contains('family') ||
        q.contains('mom') ||
        q.contains('dad') ||
        q.contains('parent') ||
        q.contains('sister') ||
        q.contains('brother') ||
        q.contains('wife') ||
        q.contains('husband') ||
        q.contains('son') ||
        q.contains('daughter') ||
        q.contains('kids') ||
        q.contains('fitness') ||
        q.contains('gym') ||
        q.contains('workout') ||
        q.contains('exercise') ||
        q.contains('run') ||
        q.contains('training')) {
      return MemoryBrainIntent.categoryQuery;
    }

    return MemoryBrainIntent.unknown;
  }
}
