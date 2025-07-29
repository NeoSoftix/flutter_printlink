// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:thermal_printer_example/main.dart';

void main() {
  testWidgets('Product Label Printer widget test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app loads with the correct title
    expect(find.text('Product Label Printer'), findsOneWidget);
    
    // Verify that connection section is present
    expect(find.text('Printer Connection'), findsOneWidget);
    
    // Verify that product information section is present
    expect(find.text('Product Information'), findsOneWidget);
    
    // Verify that print actions section is present
    expect(find.text('Print Actions'), findsOneWidget);
  });
}
