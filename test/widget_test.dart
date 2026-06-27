import 'package:flutter_test/flutter_test.dart';
import 'package:memory_os/app/app.dart';

void main() {
  testWidgets('App starts at onboarding and shows MemoryOS title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MemoryOSApp());
    await tester.pumpAndSettle();

    // Verify that onboarding page is displayed by finding the app title text.
    expect(find.text('MemoryOS'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
