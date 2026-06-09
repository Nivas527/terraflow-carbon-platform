import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/main.dart';

void main() {
  setUpAll(() {
    // Disable HTTP runtime fetching of Google Fonts to avoid test network errors
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('TerraFlowApp Dashboard UI Smoke Test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TerraFlowApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the title header TERRAFLOW exists
    expect(find.text('TERRAFLOW'), findsOneWidget);
    expect(find.text('Carbon Footprint Awareness Platform'), findsOneWidget);

    // Verify that the primary metrics exist on cards
    expect(find.text('Total Carbon'), findsOneWidget);
    expect(find.text('Transit Footprint'), findsOneWidget);
    expect(find.text('Energy Index'), findsOneWidget);
    expect(find.text('Waste Mitigated'), findsOneWidget);

    // Verify the prominent Log Button is present
    expect(find.text('Log Daily Activity'), findsOneWidget);
  });
}
