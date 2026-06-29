import 'package:flutter_test/flutter_test.dart';
import 'package:memory_os/core/parser/life_area_parser.dart';

void main() {
  group('LifeAreaParser Keyword Detection Tests', () {
    final parser = LifeAreaParser();

    test('Detects Health area', () {
      expect(parser.detectLifeArea('doctor checkup appointment'), 'Health');
      expect(parser.detectLifeArea('clinical report and medicine'), 'Health');
    });

    test('Detects Fitness area', () {
      expect(parser.detectLifeArea('went to the gym for a cardio workout'), 'Fitness');
      expect(parser.detectLifeArea('morning jog and yoga'), 'Fitness');
    });

    test('Detects Startup area', () {
      expect(parser.detectLifeArea('pitching our new saas product to ventures'), 'Startup');
      expect(parser.detectLifeArea('startup cofounder equity launch'), 'Startup');
    });

    test('Detects Work area', () {
      expect(parser.detectLifeArea('meeting with boss about client presentation'), 'Work');
      expect(parser.detectLifeArea('deadline for the project report'), 'Work');
    });

    test('Detects Finance area', () {
      expect(parser.detectLifeArea('paid monthly house rent and electric bill'), 'Finance');
      expect(parser.detectLifeArea('bank invoice tax calculation'), 'Finance');
    });

    test('Detects Travel area', () {
      expect(parser.detectLifeArea('booked flight tickets and hotel room'), 'Travel');
      expect(parser.detectLifeArea('summer airport vacation trip'), 'Travel');
    });

    test('Detects Shopping area', () {
      expect(parser.detectLifeArea('need to buy milk and groceries'), 'Shopping');
      expect(parser.detectLifeArea('weekly grocery shopping list'), 'Shopping');
    });

    test('Detects Family area', () {
      expect(parser.detectLifeArea('dinner with wife and parents'), 'Family');
      expect(parser.detectLifeArea('kids son daughter school event'), 'Family');
    });

    test('Detects Learning area', () {
      expect(parser.detectLifeArea('reading a book and studying coding tutorials'), 'Learning');
      expect(parser.detectLifeArea('university course research lecture'), 'Learning');
    });

    test('Detects Events area', () {
      expect(parser.detectLifeArea('birthday party next week'), 'Events');
      expect(parser.detectLifeArea('wedding anniversary'), 'Events');
    });

    test('Detects Personal area', () {
      expect(parser.detectLifeArea('writing my daily personal diary entries'), 'Personal');
    });

    test('Detects Other fallback area', () {
      expect(parser.detectLifeArea('random notes that match nothing'), 'Daily Life');
    });

    test('Realistic QA test examples', () {
      expect(parser.detectLifeArea('Doctor appointment tomorrow 5 PM'), 'Health');
      expect(parser.detectLifeArea('Buy milk tomorrow'), 'Shopping');
      expect(parser.detectLifeArea('Mom birthday on 10 July'), 'Family'); // Family matches first
      expect(parser.detectLifeArea('Flutter architecture idea'), 'Work');
      expect(parser.detectLifeArea('Pay electricity bill'), 'Finance');
      expect(parser.detectLifeArea('Gym at 7 AM'), 'Fitness');
    });
  });
}
