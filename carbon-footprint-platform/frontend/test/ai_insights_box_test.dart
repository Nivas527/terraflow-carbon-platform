import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/widgets/ai_insights_box.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('AiInsightsBox Rendering Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 350,
            child: AiInsightsBox(
              transportCo2: 2.5,
              electricityCo2: 3.5,
              wasteCo2: 1.5,
            ),
          ),
        ),
      ),
    );

    // Advance framework clock to allow ticker initialization and stream characters
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Verify that the title is present
    expect(find.text('AI REDUCTION INSIGHTS'), findsOneWidget);

    // Verify that the streamed insights are drawing via RichText widget
    expect(find.byType(RichText), findsWidgets);
  });
}
