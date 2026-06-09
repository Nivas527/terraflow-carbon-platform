import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/widgets/calculator_form.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('CalculatorForm Stepper Flow Test', (WidgetTester tester) async {
    // Build the widget in a test environment
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CalculatorForm(onLogAdded: (log) {})),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Step 1 header and content is visible
    expect(find.text('Log Daily Activity'), findsOneWidget);
    expect(find.text('Mode of Transport'), findsOneWidget);
    expect(find.text('Daily Distance Traveled'), findsOneWidget);

    // Verify "Back" button is not present on the first page
    expect(find.text('Back'), findsNothing);

    // Tap "Next Step" to proceed to Step 2
    final nextBtn = find.text('Next Step');
    expect(nextBtn, findsOneWidget);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // Verify Step 2 (Electricity) is visible
    expect(find.text('Home Electricity Consumption'), findsOneWidget);

    // Verify "Back" button is now visible
    expect(find.text('Back'), findsOneWidget);

    // Tap "Next Step" to proceed to Step 3
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // Verify Step 3 (Waste) is visible
    expect(find.text('Household Waste'), findsOneWidget);
    expect(find.text('Waste Composition'), findsOneWidget);
    expect(find.text('Recycling Rate'), findsOneWidget);

    // Verify the submit button has changed to "Calculate & Log"
    expect(find.text('Calculate & Log'), findsOneWidget);
  });
}
