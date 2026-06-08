import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const TerraFlowApp());
}

class TerraFlowApp extends StatelessWidget {
  const TerraFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TerraFlow - Carbon Footprint Awareness Platform',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0D14),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.greenAccent,
          brightness: Brightness.dark,
          primary: Colors.greenAccent,
          surface: const Color(0xFF111622),
          background: const Color(0xFF0A0D14),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          headlineSmall: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
          titleLarge: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: GoogleFonts.outfit(
            color: Colors.white70,
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.greenAccent,
          thumbColor: Colors.greenAccent,
          overlayColor: Colors.greenAccent.withOpacity(0.15),
          inactiveTrackColor: Colors.white10,
        ),
        dividerColor: Colors.white12,
        cardColor: const Color(0xFF141A29),
      ),
      home: const DashboardScreen(),
    );
  }
}
