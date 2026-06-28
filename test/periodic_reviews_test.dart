import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Periodic Reviews Helper Logic Tests', () {
    test('Person name regex matching', () {
      final personRegex = RegExp(r'^(?:Dr\.?\s+)?[A-Z][a-zA-Z]+$');
      expect(personRegex.hasMatch('Dr Sharma'), isTrue);
      expect(personRegex.hasMatch('Dr. Sharma'), isTrue);
      expect(personRegex.hasMatch('Alice'), isTrue);
      expect(personRegex.hasMatch('John'), isTrue);
      expect(personRegex.hasMatch('flutter'), isFalse);
      expect(personRegex.hasMatch('some random tag'), isFalse);
    });

    test('Category check logic', () {
      final categories = {
        'idea', 'health', 'work', 'personal', 'finance', 'shopping',
        'travel', 'birthday', 'meeting', 'reminder', 'task',
        'learning', 'fitness', 'family', 'startup', 'events', 'other', 'reflection'
      };
      
      bool isCategory(String tag) {
        return categories.contains(tag.toLowerCase().trim());
      }

      expect(isCategory('Work'), isTrue);
      expect(isCategory('personal'), isTrue);
      expect(isCategory('Reflection'), isTrue);
      expect(isCategory('flutter'), isFalse);
      expect(isCategory('Dr Sharma'), isFalse);
    });
  });
}
