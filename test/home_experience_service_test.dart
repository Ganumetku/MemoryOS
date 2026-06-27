import 'package:flutter_test/flutter_test.dart';
import 'package:memory_os/core/services/home_experience_service.dart';

void main() {
  group('HomeExperienceService Period Division Tests', () {
    test('Hour 6 is Morning', () {
      final period = _getPeriodForHour(6);
      expect(period, TimePeriod.morning);
    });

    test('Hour 12 is Afternoon', () {
      final period = _getPeriodForHour(12);
      expect(period, TimePeriod.afternoon);
    });

    test('Hour 18 is Evening', () {
      final period = _getPeriodForHour(18);
      expect(period, TimePeriod.evening);
    });

    test('Hour 22 is Night', () {
      final period = _getPeriodForHour(22);
      expect(period, TimePeriod.night);
    });

    test('Hour 2 is Night', () {
      final period = _getPeriodForHour(2);
      expect(period, TimePeriod.night);
    });
  });
}

TimePeriod _getPeriodForHour(int hour) {
  if (hour >= 5 && hour < 11) {
    return TimePeriod.morning;
  } else if (hour >= 11 && hour < 17) {
    return TimePeriod.afternoon;
  } else if (hour >= 17 && hour < 21) {
    return TimePeriod.evening;
  } else {
    return TimePeriod.night;
  }
}
